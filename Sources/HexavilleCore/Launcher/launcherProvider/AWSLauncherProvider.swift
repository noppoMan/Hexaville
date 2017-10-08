//
//  AWSLauncherProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/15.
//
//

import SwiftAWSS3
import SwiftAWSLambda
import SwiftAWSApigateway
import SwiftAWSIam
import AWSSDKSwiftCore
import Foundation
import SwiftyJSON

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
    
    public let apiGateway: Apigateway
    
    public let iam: Iam
    
    public let region: AWSSDKSwiftCore.Region
    
    public let lambdaCodeConfig: AWSConfiguration.LambdaCodeConfig
    
    public func endpoint(restApiId: String, deploymentStage: DeploymentStage) -> String {
        return "https://\(restApiId).execute-api.\(region.rawValue).amazonaws.com/\(deploymentStage.stringValue)"
    }
    
    public init(appName: String, credential: AWSSDKSwiftCore.Credential? = nil, region: AWSSDKSwiftCore.Region? = nil, endpoints: AWSConfiguration.Endpoints? = nil, lambdaCodeConfig: AWSConfiguration.LambdaCodeConfig) {
        self.credential = credential
        
        self.appName = appName
        
        self.region = region ?? .useast1
        
        if let credential = credential {
            self.apiGateway = Apigateway(
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
            self.apiGateway = Apigateway(region: region, endpoint: endpoints?.apiGatewayEndpoint)
            self.s3 = S3(region: region, endpoint: endpoints?.s3Endpoint)
            self.lambda = Lambda(region: region, endpoint: endpoints?.lambdaEndpoint)
        }
        
        
        self.iam = Iam(
            accessKeyId: credential?.accessKeyId,
            secretAccessKey: credential?.secretAccessKey
        )
        
        self.lambdaCodeConfig = lambdaCodeConfig
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
    
    fileprivate func zipPackage(buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> Data {
        
        let nodejsTemplatePath = try Finder.findTemplatePath(for: "/lambda/node.js")
        
        let pkgFileName = "\(hexavilleApplicationPath)/lambda-package.zip"
        
        try String(contentsOfFile: "\(nodejsTemplatePath)/index.js", encoding: .utf8)
            .replacingOccurrences(of: "{{executablePath}}", with: executableTarget)
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
        let proc = Proc("/bin/sh", [shellPath, pkgFileName, buildResult.destination, executableTarget])
        
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
            let input = Iam.GetRolePolicyRequest(roleName: lambdaLoleName, policyName: policyName)
            _ = try iam.getRolePolicy(input)
        } catch {
            let putRolePolicyInput = Iam.PutRolePolicyRequest(
                roleName: lambdaLoleName,
                policyDocument: policyDocument,
                policyName: policyName
            )
            _ = try iam.putRolePolicy(putRolePolicyInput)
        }
    }
    
    public func createOrGetLambdaRole() throws -> Iam.Role {
        do {
            let output = try iam.getRole(Iam.GetRoleRequest(roleName: lambdaLoleName))
            return output.role
        } catch {
            let crateRoleInput = Iam.CreateRoleRequest(
                roleName: lambdaLoleName,
                assumeRolePolicyDocument: assumeRolePolicyDocument
            )
            let createRoleOutput = try iam.createRole(crateRoleInput)
            return createRoleOutput.role
        }
    }
}

// ApiGateway aliases
extension AWSLauncherProvider {
    var apiName: String {
        return "hexaville-"+appName
    }
    
    public func currentRestAPI() throws -> Apigateway.RestApi {
        let apis = try apiGateway.getRestApis(Apigateway.GetRestApisRequest())
        
        if let api = apis.items?.filter({ $0.name == apiName }).first {
            return api
        }
        
        return try apiGateway.createRestApi(Apigateway.CreateRestApiRequest(name: apiName))
    }
    
    public func methodIsExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
        do {
            let input = Apigateway.GetMethodRequest(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId)
            _ = try apiGateway.getMethod(input)
            return true
        } catch {
            return false
        }
    }
    
    public func integrationIsExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
        do {
            let input = Apigateway.GetIntegrationRequest(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId)
            _ = try apiGateway.getIntegration(input)
            return true
        } catch {
            return false
        }
    }
    
    public func stageIsExists(restApiId: String, deploymentStage: DeploymentStage) -> Bool {
        do {
            let input = Apigateway.GetStageRequest(restApiId: restApiId, stageName: deploymentStage.stringValue)
            _ = try apiGateway.getStage(input)
            return true
        } catch {
            return false
        }
    }
    
    public func methodResponseIsExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
        do {
            let input = Apigateway.GetMethodResponseRequest(
                restApiId: restApiId,
                statusCode: statusCode,
                resourceId: resourceId,
                httpMethod: httpMethod
            )
            
            _ = try apiGateway.getMethodResponse(input)
            return true
        } catch {
            return false
        }
    }
    
    public func integrationResponseIsExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
        do {
            let input = Apigateway.GetIntegrationResponseRequest(
                restApiId: restApiId,
                statusCode: statusCode,
                resourceId: resourceId,
                httpMethod: httpMethod
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
            let putMethodRequest = Apigateway.PutMethodRequest(
                httpMethod: httpMethod,
                restApiId: restApiId,
                apiKeyRequired: false,
                authorizationType: "NONE",
                resourceId: resourceId
            )
            let out = try apiGateway.putMethod(putMethodRequest)
            print("Created PutMethod for \(out.toJSONString())")
        }
        
        if integrationIsExists(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId) {
            let lambdaURIPatch = Apigateway.PatchOperation(
                value: lambdaURI,
                path: "/uri",
                op: .replace
            )
            
            let input = Apigateway.UpdateIntegrationRequest(
                restApiId: restApiId,
                patchOperations: [lambdaURIPatch],
                resourceId: resourceId,
                httpMethod: httpMethod
            )
            let out = try apiGateway.updateIntegration(input)
            print("Updated PutIntegration for \(out.toJSONString())")
        } else {
            let putIntegrationRequest = Apigateway.PutIntegrationRequest(
                uri: lambdaURI,
                restApiId: restApiId,
                type: .aws_proxy,
                resourceId: resourceId,
                httpMethod: httpMethod,
                integrationHttpMethod: "POST"
            )
            let out = try apiGateway.putIntegration(putIntegrationRequest)
            print("Created PutIntegration for \(out.toJSONString())")
        }
        
        if !integrationResponseIsExists(restApiId: restApiId, statusCode: statusCode, resourceId: resourceId, httpMethod: httpMethod) {
            let input = Apigateway.PutIntegrationResponseRequest(
                statusCode: statusCode,
                httpMethod: httpMethod,
                restApiId: restApiId,
                resourceId: resourceId
            )
            
            let out = try apiGateway.putIntegrationResponse(input)
            print("Created IntegrationResponse for \(out.toJSONString())")
        }
        
        if !methodResponseIsExists(restApiId: restApiId, statusCode: statusCode, resourceId: resourceId, httpMethod: httpMethod) {
            let input = Apigateway.PutMethodResponseRequest(
                restApiId: restApiId,
                statusCode: statusCode,
                resourceId: resourceId,
                httpMethod: httpMethod
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
        let resource: Apigateway.Resource
        let methods: [MethodForDelete]
    }
    
    fileprivate func checkDeletedResources(manifestJSON: JSON, resources: [Apigateway.Resource]) -> [ResourceForDelete] {
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
        let deletedMethodsCount = resources.filter({ !$0.shouldDeleteResource }).flatMap({ $0.methods.count }).reduce(0) { $0 + $1 }
        
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
            bucket: lambdaCodeConfig.bucket,
            contentEncoding: "UTF-8",
            key: key,
            body: zipData,
            contentType: "application/octet-stream"
        )
        
        let output = try s3.putObject(input)
        
        return Lambda.FunctionCode(
            s3ObjectVersion: output.versionId,
            s3Key: key,
            s3Bucket: lambdaCodeConfig.bucket,
            zipFile: nil
        )
    }
    
    public func createBucketIfNotExists() throws {
        if try bucketIsExists() == false {
            try createBucket()
        }
    }
    
    public func bucketIsExists() throws -> Bool {
        let output = try s3.listBuckets()
        guard let alreadyExsits = output.buckets?.bucket?.contains(where: { $0.name ==  lambdaCodeConfig.bucket}) else {
            return false
        }
        return alreadyExsits
    }
    
    public func createBucket() throws {
        let input = S3.CreateBucketRequest(bucket: lambdaCodeConfig.bucket)
        _ = try s3.createBucket(input)
    }
    
    fileprivate func uploadCodeToS3(buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> Lambda.FunctionCode {
        
        print("Starting zip package........")
        let zipData = try zipPackage(
            buildResult: buildResult,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executableTarget: executableTarget
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
            return try updateFunction(code: code, roleARN: arn, environment: lambdaCodeConfig.environment)
        } catch LambdaError.resourceNotFoundException(_) {
            return try createFunction(code: code, roleARN: arn, environment: lambdaCodeConfig.environment)
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
            functionName: functionName,
            s3Key: code.s3Key,
            s3Bucket: code.s3Bucket,
            publish: true,
            s3ObjectVersion: code.s3ObjectVersion
        )
        
        _ = try lambda.updateFunctionCode(input)
        
        let updateFunctionConfigurationRequest = Lambda.UpdateFunctionConfigurationRequest(
            functionName: functionName,
            vpcConfig: lambdaCodeConfig.vpcConfig,
            memorySize: lambdaCodeConfig.memory,
            role: roleARN,
            environment: Lambda.Environment(variables: environment),
            timeout: Int32(lambdaCodeConfig.timeout)
        )
        
        return try lambda.updateFunctionConfiguration(updateFunctionConfigurationRequest)
    }
    
    public func createFunction(code: Lambda.FunctionCode, roleARN: String, environment: [String : String] = [:]) throws -> Lambda.FunctionConfiguration {
        
        let input = Lambda.CreateFunctionRequest(
            vpcConfig: lambdaCodeConfig.vpcConfig,
            timeout: Int32(lambdaCodeConfig.timeout),
            publish: true,
            runtime: .nodejs4_3,
            description: "Automatically generated by Hexaville",
            functionName: functionName,
            code: code,
            memorySize: lambdaCodeConfig.memory,
            role: roleARN,
            environment: Lambda.Environment(variables: environment),
            handler: lambdaHandler
        )
        
        return try lambda.createFunction(input)
    }
    
    public func fetchLambdaPolicies() -> JSON {
        do {
            let lambdaPolicies = try lambda.getPolicy(Lambda.GetPolicyRequest(functionName: functionName))
            
            guard let jsonString = lambdaPolicies.policy else { return [:] }
            let data = try JSONSerialization.jsonObject(with: jsonString.data, options: [])
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
        let resources = try apiGateway.getResources(Apigateway.GetResourcesRequest(restApiId: api.id!))
        let resourceItems: [Apigateway.Resource] = resources.items ?? []
        
        let routes = resourceItems.map({
            Route(method: $0.resourceMethods?.keys.map({ $0 }) ?? [], resource: $0.path!)
        })
        
        return Routes(endpoint: endpoint(restApiId: api.id!, deploymentStage: deploymentStage), routes: routes)
    }
    
    func deploy(deploymentStage: DeploymentStage, buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> DeployResult {
        let code = try uploadCodeToS3(buildResult: buildResult, hexavilleApplicationPath: hexavilleApplicationPath, executableTarget: executableTarget)
        
        let lambdaConfiguration = try updateFunctionCode(code: code)
        
        let lambdaURI = self.lambdaURI(region: region, arn: lambdaConfiguration.functionArn!)
        
        let api = try currentRestAPI()
        
        guard let restApiId = api.id else {
            throw LauncherError.missingRequiredParam("RestApi.id")
        }
        
        let binaryMediaTypes: [String] = api.binaryMediaTypes ?? []
        
        let patchOperations: [Apigateway.PatchOperation] = Configuration.binaryMediaTypes.flatMap({
            if binaryMediaTypes.contains($0) {
                return nil
            }
            return Apigateway.PatchOperation(
                path: "/binaryMediaTypes/\($0.replacingOccurrences(of: "/", with: "~1"))",
                op: .add
            )
        })
        
        if patchOperations.count > 0 {
            let input = Apigateway.UpdateRestApiRequest(
                restApiId: restApiId,
                patchOperations: patchOperations
            )
            _ = try apiGateway.updateRestApi(input)
        }
        
        let resources = try apiGateway.getResources(Apigateway.GetResourcesRequest(restApiId: api.id!))
        var resourceItems: [Apigateway.Resource] = resources.items ?? []
        
        guard let rootResource = resourceItems.filter({ $0.path == "/" }).first else {
            throw LauncherError.couldNotFindRootResource
        }
        
        let lambdaPolicies = fetchLambdaPolicies()
        let manifest = try String(contentsOfFile: buildResult.destination+"/.routing-manifest.json", encoding: .utf8)
        let dict = try JSONSerialization.jsonObject(with: manifest.data, options: []) as! [String: Any]
        let manifestJSON = JSON(dict)
        
        print("Routing Manifest loaded")
        
        print("taking resources diff between live stage and current deploying ....")
        let resourcesForDelete = checkDeletedResources(manifestJSON: manifestJSON, resources: resourceItems)
        showDeletedResources(resourcesForDelete)
        
        var activeSourceARNs: [String] = []
        
        for json in manifestJSON["routing"].arrayValue {
            let path = json["path"].stringValue
            let paths: [String]
            if path == "/" {
                paths = [path]
            } else {
                paths = path.components(separatedBy: "/").filter({ !$0.isEmpty })
            }
            
            var apiResources: [Resource] = []
            
            for (index, pathPart) in paths.enumerated() {
                var parentApiGatewayResource: Apigateway.Resource?
                if index == 0 {
                    parentApiGatewayResource = rootResource
                } else {
                    parentApiGatewayResource = apiResources[index-1].apiGatewayResource
                }
                
                var apiGatewayResource: Apigateway.Resource?
                if let _apiGatewayResource = resourceItems.filter({
                    if let parentPath = parentApiGatewayResource?.path, let parentIsSame = $0.path?.contains(parentPath) {
                        return $0.pathPart == pathPart && parentIsSame
                    }
                    return $0.pathPart == pathPart
                }).first {
                    apiGatewayResource = _apiGatewayResource
                }
                
                let resource = Resource(
                    pathPart: pathPart,
                    method: index == paths.count-1 ? json["method"].stringValue : nil,
                    apiGatewayResource: apiGatewayResource,
                    apiGatewayParentResource: parentApiGatewayResource
                )
                
                apiResources.append(resource)
            }
            
            var lastApiResource: Apigateway.Resource = rootResource
            
            for apiResource in apiResources {
                if apiResource.pathPart == "/" {
                    // TODO
                }
                else if let apiGatewayResource = apiResource.apiGatewayResource {
                    lastApiResource = apiGatewayResource
                }
                else
                {
                    let request = Apigateway.CreateResourceRequest(
                        restApiId: restApiId,
                        pathPart: apiResource.pathPart,
                        parentId: lastApiResource.id!
                    )
                    let response = try apiGateway.createResource(request)
                    print("Created CreateResource for \(response.toJSONString())")
                    lastApiResource = response
                    if !resourceItems.contains(where: { $0.id == response.id }) {
                        resourceItems.append(response)
                    }
                }
                
                if let httpMethod = apiResource.method?.uppercased() {
                    try updateIntegrations(
                        lambdaURI: lambdaURI,
                        restApiId: restApiId,
                        resourceId: lastApiResource.id!,
                        httpMethod: httpMethod
                    )
                    
                    let sourceARN = try self.sourceARN(
                        region: region,
                        lambdaURI: lambdaURI,
                        restApiId: restApiId,
                        httpMethod: httpMethod,
                        path: path
                    )
                    
                    activeSourceARNs.append(sourceARN)
                    
                    if lambdaPolicies["Statement"].arrayValue.filter({
                        $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.stringValue == sourceARN
                    }).count == 0 {
                        // TODO limit
                        let addPermissionRequest = Lambda.AddPermissionRequest(
                            statementId: UUID().uuidString.lowercased(),
                            functionName: functionName,
                            action: "lambda:InvokeFunction",
                            sourceArn: sourceARN,
                            principal: "apigateway.amazonaws.com"
                        )
                        _ = try lambda.addPermission(addPermissionRequest)
                    }
                }
            }
        }
        
        for resourceForDelete in resourcesForDelete {
            for method in resourceForDelete.methods {
                let input = Apigateway.DeleteMethodRequest(restApiId: restApiId, httpMethod: method.method, resourceId: resourceForDelete.resource.id!)
                print("deleting method for.... \(input.toJSONString())")
                _ = try apiGateway.deleteMethod(input)
            }
        }
        
        try lambdaPolicies["Statement"].arrayValue.filter({
            guard let arn = $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.string else { return false }
            return !activeSourceARNs.contains(arn)
        })
            .forEach { policy in
                let input = Lambda.RemovePermissionRequest(functionName: functionName, statementId: policy["Sid"].stringValue)
                print("deleting lambda policy for.... \(input.toJSONString())")
                _ = try lambda.removePermission(input)
        }
        
        for resourceForDelete in resourcesForDelete {
            if !resourceForDelete.shouldDeleteResource { continue }
            let input = Apigateway.DeleteResourceRequest(restApiId: restApiId, resourceId: resourceForDelete.resource.id!)
            
            print("deleting resource for.... \(input.toJSONString())")
            try apiGateway.deleteResource(input)
        }
        
        print("deplying to \(deploymentStage.stringValue)")
        let createDeploymentRequest = Apigateway.CreateDeploymentRequest(
            cacheClusterEnabled: false,
            cacheClusterSize: nil,
            variables: [:],
            description: "",
            restApiId: restApiId,
            stageName: deploymentStage.stringValue,
            stageDescription: ""
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
        return regex.stringByReplacingMatches(in: path, options: [], range: NSRange(location: 0, length: path.characters.count), withTemplate: "*")
    }
}
