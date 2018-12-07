//
//  AWSLauncherProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/15.
//
//

#if os(OSX)
    import Darwin.C
#else
    import Glibc
#endif

import S3
import Lambda
import APIGateway
import IAM
import AWSSDKSwiftCore
import Foundation
import SwiftyJSON

struct Resource {
    let pathPart: String
    let method: String?
    var apiGatewayResource: APIGateway.Resource?
    var apiGatewayParentResource: APIGateway.Resource?
}

extension AWSSDKSwiftCore.AWSShape {
    public func toJSONString() -> String {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

public enum AWSLauncherProviderError: Error {
    case couldNotZipPackage
}

public struct AWSLauncherProvider {
    public let appName: String
    
    public let credential: AWSSDKSwiftCore.Credential?
    
    public let lambda: Lambda
    
    public let s3: S3
    
    public let apiGateway: APIGateway
    
    public let iam: IAM
    
    public let region: AWSSDKSwiftCore.Region
    
    public let lambdaCodeConfig: HexavilleFile.Provider.AWS.Lambda
    
    let environment: [String: String]
    
    var runtime: Lambda.Runtime {
        return .nodejs810
    }
    
    public func endpoint(restApiId: String, deploymentStage: DeploymentStage) -> String {
        return "https://\(restApiId).execute-api.\(region.rawValue).amazonaws.com/\(deploymentStage.stringValue)"
    }
    
    public init(appName: String, credential: AWSSDKSwiftCore.Credential? = nil, region: AWSSDKSwiftCore.Region? = nil, endpoints: AWSEndpoints? = nil, lambdaCodeConfig: HexavilleFile.Provider.AWS.Lambda, environment: [String: String]) {
        self.credential = credential
        
        self.appName = appName
        
        self.region = region ?? .useast1
        
        if let credential = credential {
            self.apiGateway = APIGateway(
                accessKeyId: credential.accessKeyId,
                secretAccessKey: credential.secretAccessKey,
                region: region,
                endpoint: endpoints?.apiGatewayEndpoint
            )
            
            self.s3 = S3(
                accessKeyId: credential.accessKeyId,
                secretAccessKey: credential.secretAccessKey,
                region: region,
                endpoint: endpoints?.s3Endpoint
            )
            
            self.lambda = Lambda(
                accessKeyId: credential.accessKeyId,
                secretAccessKey: credential.secretAccessKey,
                region: region,
                endpoint: endpoints?.lambdaEndpoint
            )
        } else {
            self.apiGateway = APIGateway(region: region, endpoint: endpoints?.apiGatewayEndpoint)
            self.s3 = S3(region: region, endpoint: endpoints?.s3Endpoint)
            self.lambda = Lambda(region: region, endpoint: endpoints?.lambdaEndpoint)
        }
        
        
        self.iam = IAM(
            accessKeyId: credential?.accessKeyId,
            secretAccessKey: credential?.secretAccessKey
        )
        
        self.lambdaCodeConfig = lambdaCodeConfig
        self.environment = environment
    }
}

extension AWSLauncherProvider {
    fileprivate func lambdaPackageShellContent() -> String {
        var content = ""
        content += "#!/usr/bin/env sh"
        content += "\n"
        content += "cd $2"
        content += "\n"
        content += "zip $1 $3 byline.js index.js ./*.so ./*.so.* -r assets"
        return content
    }
    
    fileprivate func zipPackage(buildResult: BuildResult, hexavilleApplicationPath: String, executable: String) throws -> Data {
        
        let nodejsTemplatePath = try Finder.findTemplatePath(for: "/lambda/node.js")
        
        let pkgFileName = "\(hexavilleApplicationPath)/lambda-package.zip"
        
        try String(contentsOfFile: "\(nodejsTemplatePath)/index.js", encoding: .utf8)
            .replacingOccurrences(of: "{{executablePath}}", with: executable)
            .write(toFile: buildResult.destination+"/index.js", atomically: true, encoding: .utf8)
        
        try String(contentsOfFile: "\(nodejsTemplatePath)/byline.js", encoding: .utf8)
            .write(toFile: buildResult.destination+"/byline.js", atomically: true, encoding: .utf8)
        
        let assetPath = hexavilleApplicationPath+"/assets"
        if FileManager.default.fileExists(atPath: assetPath) {
            _ = Process.exec("cp", ["-r", assetPath, "\(buildResult.destination)"])
        }
        
        let shellPath = "/tmp/build-lambda-package.sh"
        let shellContent = lambdaPackageShellContent()
        try shellContent.write(toFile: shellPath, atomically: true, encoding: .utf8)
        let proc = Proc("/bin/sh", [shellPath, pkgFileName, buildResult.destination, executable])
        
        if proc.terminationStatus > 0 {
            throw AWSLauncherProviderError.couldNotZipPackage
        }
        
        let data = try Data(contentsOf: URL(string: "file://"+pkgFileName)!)
        
        try FileManager.default.removeItem(atPath: pkgFileName)
        try FileManager.default.removeItem(atPath: shellPath)
        
        return data
    }
}

// IAM
extension AWSLauncherProvider {
    private var assumeRolePolicyDocument: String {
        var str = ""
        str+="{"
            str+="\"Version\": \"2012-10-17\","
            str+="\"Statement\": {"
                str+="\"Effect\": \"Allow\","
                str+="\"Principal\": {\"Service\": \"lambda.amazonaws.com\"},"
                str+="\"Action\": \"sts:AssumeRole\""
            str+="}"
        str+="}"
        return str
    }
    
    private var policyDocument: String {
        var str = ""
        str+="{"
            str+="\"Version\": \"2012-10-17\","
            str+="\"Statement\": ["
                str+="{"
                    str+="\"Effect\": \"Allow\","
                    str+="\"Action\": ["
                        str+="\"logs:CreateLogGroup\","
                        str+="\"logs:CreateLogStream\","
                        str+="\"logs:PutLogEvents\""
                    str+="],"
                    str+="\"Resource\": \"arn:aws:logs:*:*:*\""
                str+="}"
            str+="]"
        str+="}"
        return str
    }
    
    private var lambdaLoleName: String {
        return "\(appName)-and-lambda-basic-execution"
    }
    
    public func resolveLambdaRoleARN() throws  -> String {
        let arn: String
        if let roleARN = lambdaCodeConfig.role {
            arn = roleARN
        } else {
            let role = try createOrGetLambdaRole()
            try attachPolicyToRoleIfNeeded()
            arn = role.arn
        }
        return arn
    }
    
    public func attachPolicyToRoleIfNeeded() throws {
        let policyName = "permissions-policy-for-lambda"
        
        do {
            let input = IAM.GetRolePolicyRequest(roleName: lambdaLoleName, policyName: policyName)
            _ = try iam.getRolePolicy(input)
        } catch {
            let putRolePolicyInput = IAM.PutRolePolicyRequest(
                policyDocument: policyDocument,
                roleName: lambdaLoleName,
                policyName: policyName
            )
            _ = try iam.putRolePolicy(putRolePolicyInput)
        }
    }
    
    public func createOrGetLambdaRole() throws -> IAM.Role {
        do {
            let output = try iam.getRole(IAM.GetRoleRequest(roleName: lambdaLoleName))
            return output.role
        } catch {
            let crateRoleInput = IAM.CreateRoleRequest(
                roleName: lambdaLoleName,
                assumeRolePolicyDocument: assumeRolePolicyDocument
            )
            let createRoleOutput = try iam.createRole(crateRoleInput)
            sleep(10) // waiting for role is ready.
            return createRoleOutput.role
        }
    }
}

// ApiGateway aliases
extension AWSLauncherProvider {
    var apiName: String {
        return "hexaville-"+appName
    }
    
    public func currentRestAPI() throws -> APIGateway.RestApi {
        let apis = try apiGateway.getRestApis(APIGateway.GetRestApisRequest())
        
        if let api = apis.items?.filter({ $0.name == apiName }).first {
            return api
        }
        
        return try apiGateway.createRestApi(APIGateway.CreateRestApiRequest(name: apiName))
    }
    
    public func methodIsExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
        do {
            let input = APIGateway.GetMethodRequest(resourceId: resourceId, httpMethod: httpMethod, restApiId: restApiId)
            _ = try apiGateway.getMethod(input)
            return true
        } catch {
            return false
        }
    }
    
    public func integrationIsExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
        do {
            let input = APIGateway.GetIntegrationRequest(resourceId: resourceId, httpMethod: httpMethod, restApiId: restApiId)
            _ = try apiGateway.getIntegration(input)
            return true
        } catch {
            return false
        }
    }
    
    public func stageIsExists(restApiId: String, deploymentStage: DeploymentStage) -> Bool {
        do {
            let input = APIGateway.GetStageRequest(restApiId: restApiId, stageName: deploymentStage.stringValue)
            _ = try apiGateway.getStage(input)
            return true
        } catch {
            return false
        }
    }
    
    public func methodResponseIsExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
        do {
            let input = APIGateway.GetMethodResponseRequest(
                resourceId: resourceId,
                restApiId: restApiId,
                httpMethod: httpMethod,
                statusCode: statusCode
            )
            
            _ = try apiGateway.getMethodResponse(input)
            return true
        } catch {
            return false
        }
    }
    
    public func integrationResponseIsExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
        do {
            let input = APIGateway.GetIntegrationResponseRequest(
                resourceId: resourceId,
                restApiId: restApiId,
                httpMethod: httpMethod,
                statusCode: statusCode
            )
            
            _ = try apiGateway.getIntegrationResponse(input)
            return true
        } catch {
            return false
        }
    }
    
    public func updateIntegrations(lambdaURI: String, restApiId: String, resourceId: String, httpMethod: String) throws {
        let statusCode = "200"
        
        if !methodIsExists(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId) {
            let putMethodRequest = APIGateway.PutMethodRequest(
                restApiId: restApiId,
                resourceId: resourceId,
                apiKeyRequired: false,
                authorizationType: "NONE",
                httpMethod: httpMethod
            )
            let out = try apiGateway.putMethod(putMethodRequest)
            print("Created PutMethod for \(out.toJSONString())")
        }
        
        if integrationIsExists(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId) {
            let lambdaURIPatch = APIGateway.PatchOperation(
                value: lambdaURI,
                path: "/uri",
                op: .replace
            )
            
            let input = APIGateway.UpdateIntegrationRequest(
                resourceId: resourceId,
                restApiId: restApiId,
                httpMethod: httpMethod,
                patchOperations: [lambdaURIPatch]
            )
            let out = try apiGateway.updateIntegration(input)
            print("Updated PutIntegration for \(out.toJSONString())")
        } else {
            let putIntegrationRequest = APIGateway.PutIntegrationRequest(
                integrationHttpMethod: "POST",
                resourceId: resourceId,
                uri: lambdaURI,
                restApiId: restApiId,
                type: .awsProxy,
                httpMethod: httpMethod
            )
            let out = try apiGateway.putIntegration(putIntegrationRequest)
            print("Created PutIntegration for \(out.toJSONString())")
        }
        
        if !integrationResponseIsExists(restApiId: restApiId, statusCode: statusCode, resourceId: resourceId, httpMethod: httpMethod) {
            let input = APIGateway.PutIntegrationResponseRequest(
                restApiId: restApiId,
                statusCode: statusCode,
                resourceId: resourceId,
                httpMethod: httpMethod
            )
            
            let out = try apiGateway.putIntegrationResponse(input)
            print("Created IntegrationResponse for \(out.toJSONString())")
        }
        
        if !methodResponseIsExists(restApiId: restApiId, statusCode: statusCode, resourceId: resourceId, httpMethod: httpMethod) {
            let input = APIGateway.PutMethodResponseRequest(
                resourceId: resourceId,
                restApiId: restApiId,
                httpMethod: httpMethod,
                statusCode: statusCode
            )
            let out = try apiGateway.putMethodResponse(input)
            print("Created PutMethodResponse for \(out.toJSONString())")
        }
    }
    
    struct ResourceForDelete {
        struct MethodForDelete {
            let resourceId: String
            let method: String
        }
        
        let shouldDeleteResource: Bool
        let resource: APIGateway.Resource
        let methods: [MethodForDelete]
    }
    
    fileprivate func checkDeletedResources(manifestJSON: JSON, resources: [APIGateway.Resource]) -> [ResourceForDelete] {
        var deletedResources: [ResourceForDelete] = []
        
        for resource in resources {
            var deletedMethods: [ResourceForDelete.MethodForDelete] = []
            guard let methods = resource.resourceMethods else { continue }
            let definedResources = manifestJSON["routing"].arrayValue.filter({ $0["path"].string == resource.path })
            if definedResources.count == 0 {
                let target = ResourceForDelete(shouldDeleteResource: true, resource: resource, methods: [])
                deletedResources.append(target)
                continue
            }
            
            for (methodString, _) in methods {
                if !definedResources.contains(where: { $0["method"].stringValue.uppercased() == methodString }) {
                    let m = ResourceForDelete.MethodForDelete(resourceId: resource.id!, method: methodString)
                    deletedMethods.append(m)
                }
            }
            
            let resourceForDelete: ResourceForDelete
            if deletedMethods.count == methods.count {
                resourceForDelete = ResourceForDelete(shouldDeleteResource: true, resource: resource, methods: deletedMethods)
            } else {
                resourceForDelete = ResourceForDelete(shouldDeleteResource: false, resource: resource, methods: deletedMethods)
            }
            deletedResources.append(resourceForDelete)
        }
        
        return deletedResources
    }
    
    fileprivate func showDeletedResources(_ resources: [ResourceForDelete]) {
        if resources.count == 0 { return }
        
        let deletedResourcesCount = resources.filter({ $0.shouldDeleteResource }).count
        let deletedMethodsCount = resources.filter({ !$0.shouldDeleteResource }).compactMap({ $0.methods.count }).reduce(0) { $0 + $1 }
        
        print("There are \(deletedResourcesCount) deleted resources and \(deletedMethodsCount) deleted methods.")
        
        print("")
        
        print("-- deleted resources(\(deletedResourcesCount)) --")
        print("")
        
        for resourceForDelete in resources {
            if resourceForDelete.shouldDeleteResource {
                print("id: \(resourceForDelete.resource.id!)")
                print("path: \(resourceForDelete.resource.path!)")
                print(" ")
            }
        }
        
        print("")
        
        print("-- deleted methods(\(deletedMethodsCount)) --")
        print("")
        
        for resourceForDelete in resources {
            if resourceForDelete.methods.count == 0 { continue }
            for method in resourceForDelete.methods {
                print("path: \(resourceForDelete.resource.path!)")
                print("method: \(method.method)")
                print("")
            }
        }
    }
}

// S3 aliases
extension AWSLauncherProvider {
    public func uploadCode(zipData: Data) throws -> Lambda.FunctionCode {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let date = formatter.string(from: Date())
        
        let key = "\(date)-lambda-package.zip"
        
        let input = S3.PutObjectRequest(
            contentType: "application/octet-stream",
            contentEncoding: "UTF-8",
            bucket: lambdaCodeConfig.s3Bucket,
            key: key,
            body: zipData
        )
        
        let output = try s3.putObject(input)
        
        return Lambda.FunctionCode(
            s3Bucket: lambdaCodeConfig.s3Bucket,
            s3ObjectVersion: output.versionId,
            s3Key: key,
            zipFile: nil
        )
    }
    
    public func createBucketIfNotExists() throws {
        do {
            try createBucket()
            print("\(lambdaCodeConfig.s3Bucket) is successfully created")
        } catch S3ErrorType.bucketAlreadyOwnedByYou {
            print("\(lambdaCodeConfig.s3Bucket) is already exist")
        } catch S3ErrorType.bucketAlreadyExists {
            print("\(lambdaCodeConfig.s3Bucket) is already exist")
        } catch {
            throw error
        }
    }
    
    public func createBucket() throws {
        let input = S3.CreateBucketRequest(bucket: lambdaCodeConfig.s3Bucket)
        _ = try s3.createBucket(input)
    }
    
    fileprivate func uploadCodeToS3(buildResult: BuildResult, hexavilleApplicationPath: String, executable: String) throws -> Lambda.FunctionCode {
        
        print("Starting zip package........")
        let zipData = try zipPackage(
            buildResult: buildResult,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: executable
        )
        print("Zip package done.")
        
        print("Uploading code to s3.....")
        _ = try createBucketIfNotExists()
        let code = try uploadCode(zipData: zipData)
        print("Code uploaded")
        
        return code
    }
}

// lambda aliases
extension AWSLauncherProvider {
    var functionName: String {
        return "hexaville-"+appName+"-function"
    }
    
    var lambdaHandler: String {
        return "index.handler"
    }
    
    public func updateFunctionCode(code: Lambda.FunctionCode) throws -> Lambda.FunctionConfiguration {
        let arn = try resolveLambdaRoleARN()
        
        do {
            _ = try getFunction()
            return try updateFunction(code: code, roleARN: arn, environment: environment)
        } catch LambdaErrorType.resourceNotFoundException(_) {
            return try createFunction(code: code, roleARN: arn, environment: environment)
        } catch {
            throw error
        }
    }
    
    public func getFunction() throws -> Lambda.FunctionConfiguration {
        let input = Lambda.GetFunctionRequest(functionName: functionName)
        let output = try lambda.getFunction(input)
        guard let configuration = output.configuration else {
            throw LauncherError.missingRequiredParam("Lambda.GetFunctionResponse.configuration")
        }
        return configuration
    }
    
    public func updateFunction(code: Lambda.FunctionCode, roleARN: String, environment: [String : String] = [:]) throws -> Lambda.FunctionConfiguration {
        
        let input = Lambda.UpdateFunctionCodeRequest(
            s3Key: code.s3Key,
            s3Bucket: code.s3Bucket,
            s3ObjectVersion: code.s3ObjectVersion,
            functionName: functionName,
            publish: true
        )
        
        _ = try lambda.updateFunctionCode(input)
        
        let updateFunctionConfigurationRequest = Lambda.UpdateFunctionConfigurationRequest(
            vpcConfig: lambdaCodeConfig.awsSDKSwiftVPCConfig,
            timeout: lambdaCodeConfig.timeout,
            role: roleARN,
            runtime: runtime,
            memorySize: lambdaCodeConfig.memory,
            environment: Lambda.Environment(variables: environment),
            functionName: functionName
        )
        
        return try lambda.updateFunctionConfiguration(updateFunctionConfigurationRequest)
    }
    
    public func createFunction(code: Lambda.FunctionCode, roleARN: String, environment: [String : String] = [:]) throws -> Lambda.FunctionConfiguration {
        
        let input = Lambda.CreateFunctionRequest(
            vpcConfig: lambdaCodeConfig.awsSDKSwiftVPCConfig,
            timeout: Int32(lambdaCodeConfig.timeout),
            role: roleARN,
            handler: lambdaHandler,
            runtime: runtime,
            memorySize: lambdaCodeConfig.memory,
            publish: true,
            description: "Automatically generated by Hexaville",
            code: code,
            environment: Lambda.Environment(variables: environment),
            functionName: functionName
        )
        
        return try lambda.createFunction(input)
    }
    
    public func fetchLambdaPolicies() -> JSON {
        do {
            let lambdaPolicies = try lambda.getPolicy(Lambda.GetPolicyRequest(functionName: functionName))
            
            guard let jsonString = lambdaPolicies.policy else { return [:] }
            let data = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8) ?? Data(), options: [])
            return JSON(data)
        } catch {
            return [:]
        }
    }
}

// for commands
extension AWSLauncherProvider {
    func routes(deploymentStage: DeploymentStage) throws -> Routes {
        let api = try currentRestAPI()
        let resources = try apiGateway.getResources(APIGateway.GetResourcesRequest(restApiId: api.id!))
        let resourceItems: [APIGateway.Resource] = resources.items ?? []
        
        let routes = resourceItems.map({
            Route(method: $0.resourceMethods?.keys.map({ $0 }) ?? [], resource: $0.path!)
        })
        
        return Routes(endpoint: endpoint(restApiId: api.id!, deploymentStage: deploymentStage), routes: routes)
    }
    
    func deploy(deploymentStage: DeploymentStage, buildResult: BuildResult, hexavilleApplicationPath: String, executable: String) throws -> DeployResult {
        let code = try uploadCodeToS3(buildResult: buildResult, hexavilleApplicationPath: hexavilleApplicationPath, executable: executable)
        
        let lambdaConfiguration = try updateFunctionCode(code: code)
        
        let lambdaURI = self.lambdaURI(region: region, arn: lambdaConfiguration.functionArn!)
        
        let api = try currentRestAPI()
        
        guard let restApiId = api.id else {
            throw LauncherError.missingRequiredParam("RestApi.id")
        }
        
        let binaryMediaTypes: [String] = api.binaryMediaTypes ?? []
        
        let patchOperations: [APIGateway.PatchOperation] = binaryMediaTypes.compactMap({
            if binaryMediaTypes.contains($0) {
                return nil
            }
            return APIGateway.PatchOperation(
                path: "/binaryMediaTypes/\($0.replacingOccurrences(of: "/", with: "~1"))",
                op: .add
            )
        })
        
        if patchOperations.count > 0 {
            let input = APIGateway.UpdateRestApiRequest(
                restApiId: restApiId,
                patchOperations: patchOperations
            )
            _ = try apiGateway.updateRestApi(input)
        }
        
        let resources = try apiGateway.getResources(APIGateway.GetResourcesRequest(restApiId: api.id!))
        let resourceItems: [APIGateway.Resource] = resources.items ?? []
        
        guard let rootResource = resourceItems.filter({ $0.path == "/" }).first else {
            throw LauncherError.couldNotFindRootResource
        }
        
        let lambdaPolicies = fetchLambdaPolicies()
        
        let httpMethod = "ANY"
        let path = "/"
        
        try updateIntegrations(
            lambdaURI: lambdaURI,
            restApiId: restApiId,
            resourceId: rootResource.id!,
            httpMethod: httpMethod
        )
        
        let sourceARN = try self.sourceARN(
            region: region,
            lambdaURI: lambdaURI,
            restApiId: restApiId,
            httpMethod: httpMethod,
            path: path
        )
        
        if lambdaPolicies["Statement"].arrayValue.filter({
            $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.stringValue == sourceARN
        }).count == 0 {
            // TODO limit
            let addPermissionRequest = Lambda.AddPermissionRequest(
                action: "lambda:InvokeFunction",
                principal: "apigateway.amazonaws.com",
                functionName: functionName,
                sourceArn: sourceARN,
                statementId: UUID().uuidString.lowercased()
            )
            _ = try lambda.addPermission(addPermissionRequest)
        }
        
        
        try lambdaPolicies["Statement"].arrayValue.filter({
            guard let arn = $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.string else { return false }
            return sourceARN != arn
        })
        .forEach { policy in
            let input = Lambda.RemovePermissionRequest(statementId: policy["Sid"].stringValue, functionName: functionName)
            print("deleting lambda policy for.... \(input.toJSONString())")
            _ = try lambda.removePermission(input)
        }
        
        print("deplying to \(deploymentStage.stringValue)")
        let createDeploymentRequest = APIGateway.CreateDeploymentRequest(
            stageName: deploymentStage.stringValue,
            restApiId: restApiId,
            cacheClusterSize: nil,
            stageDescription: "",
            cacheClusterEnabled: false,
            description: "",
            variables: [:]
        )
        
        _ = try apiGateway.createDeployment(createDeploymentRequest)
        
        return DeployResult(
            endpoint: "https://\(restApiId).execute-api.\(region.rawValue).amazonaws.com/\(deploymentStage.stringValue)"
        )
    }
    
    func sourceARN(region: AWSSDKSwiftCore.Region, lambdaURI: String, restApiId: String, httpMethod: String, path: String) throws -> String {
        return try "arn:aws:execute-api:\(region.rawValue):\(self.clientId(from: lambdaURI)):\(restApiId)/*/\(httpMethod)\(pathForARN(path))"
    }
    
    func clientId(from uri: String) -> String {
        return uri.components(separatedBy: "/")[3].components(separatedBy: ":")[4]
    }
    
    func lambdaURI(region: AWSSDKSwiftCore.Region, arn: String) -> String {
        let functionArn = arn.replacingOccurrences(of: ":[0-9]*$", with: "", options: .regularExpression, range: nil)
        return "arn:aws:apigateway:\(region.rawValue):lambda:path/2015-03-31/functions/\(functionArn)/invocations"
    }
    
    func pathForARN(_ path: String) throws -> String {
        let regex = try NSRegularExpression(pattern: "\\{[a-zA-Z_-]*\\}", options: [])
        return regex.stringByReplacingMatches(in: path, options: [], range: NSRange(location: 0, length: path.count), withTemplate: "*")
    }
}
