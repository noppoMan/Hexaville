//
//  AWSLauncherProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/15.
//
//

import AWSSDKSwift
import Core
import Foundation
import SwiftyJSON

extension AWSShape {
    public func toJSONString() -> String {
        do {
            let dict = try self.serializeToDictionary()
            let data = try JSONSerializer.serialize(dict)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

public enum AWSLauncherProviderError: Error {
    case createLambdaPackageFailed
}

public struct AWSLauncherProvider {
    public let appName: String
    
    public let credential: Credential?
    
    public let lambda: LambdaExecutor
    
    public let s3: S3Executor
    
    public let apiGateway: APIGatewayExecutor
    
    public let iam: Iam
    
    public let region: Region
    
    public func endpoint(restApiId: String, deploymentStage: DeploymentStage) -> String {
        return "https://\(restApiId).execute-api.\(region.rawValue).amazonaws.com/\(deploymentStage.stringValue)"
    }
    
    public init(appName: String, credential: Credential? = nil, region: Region? = nil, endpoints: Endpoints? = nil, lambdaCodeConfig: LambdaCodeConfig) {
        self.credential = credential
        
        self.appName = appName
        
        self.region = region ?? .useast1
        
        self.lambda = LambdaExecutor(
            appName: appName,
            credential: credential,
            region: region,
            endpoint: endpoints?.s3Endpoint,
            config: lambdaCodeConfig
        )
        
        self.s3 = S3Executor(
            appName: appName,
            bucketName: lambdaCodeConfig.bucket,
            credential: credential,
            region: region,
            endpoint: endpoints?.lambdaEndpoint
        )
        
        self.apiGateway = APIGatewayExecutor(
            appName: appName,
            credential: credential,
            region: region,
            endpoint: endpoints?.apiGatewayEndpoint
        )
        
        self.iam = Iam(
            accessKeyId: credential?.accessKeyId,
            secretAccessKey: credential?.secretAccessKey
        )
    }
}

extension AWSLauncherProvider {
    public struct Endpoints {
        let s3Endpoint: String?
        let lambdaEndpoint: String?
        let apiGatewayEndpoint: String?
        
        init(s3Endpoint: String? = nil, lambdaEndpoint: String? = nil, apiGatewayEndpoint: String) {
            self.s3Endpoint = s3Endpoint
            self.lambdaEndpoint = lambdaEndpoint
            self.apiGatewayEndpoint = apiGatewayEndpoint
        }
    }
    
    public struct LambdaCodeConfig {
        let role: String
        let bucket: String
        let timeout: Int
        let memory: Int32?
        let vpcConfig: Lambda.VpcConfig?
        let environment: [String : String]
        
        public init(role: String, bucket: String, timeout: Int = 10, memory: Int32? = nil, vpcConfig: Lambda.VpcConfig? = nil, environment: [String : String] = [:]) {
            self.role = role
            self.bucket = bucket
            self.timeout = timeout
            self.memory = memory
            self.vpcConfig = vpcConfig
            self.environment = environment
        }
    }
    
    public struct S3Executor {
        let appName: String
        
        let client: S3
        
        let bucketName: String
        
        init(appName: String, bucketName: String, credential: Credential? = nil, region: Region? = nil, endpoint: String? = nil) {
            self.appName = appName
            if let credential = credential {
                self.client = S3(
                    accessKeyId: credential.accessKeyId,
                    secretAccessKey: credential.secretAccessKey,
                    region: region,
                    endpoint: endpoint
                )
            } else {
                self.client = S3(region: region, endpoint: endpoint)
            }
            
            self.bucketName = bucketName
        }
        
        public func uploadCode(zipData: Data) throws -> Lambda.FunctionCode {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let date = formatter.string(from: Date())
            
            let key = "\(date)-lambda-package.zip"
            
            let input = S3.PutObjectRequest(
                bucket: bucketName,
                contentEncoding: "UTF-8",
                key: key,
                body: zipData,
                contentType: "application/octet-stream"
            )
            
            let output = try client.putObject(input)
            
            return Lambda.FunctionCode(
                s3ObjectVersion: output.versionId,
                s3Key: key,
                s3Bucket: bucketName,
                zipFile: nil
            )
        }
        
        public func createBucketIfNotExists() throws {
            if try bucketIsExists() == false {
                try createBucket()
            }
        }
        
        public func bucketIsExists() throws -> Bool {
            let output = try client.listBuckets()
            guard let alreadyExsits = output.buckets?.bucket?.contains(where: { $0.name ==  bucketName}) else {
                return false
            }
            return alreadyExsits
        }
        
        public func createBucket() throws {
            let input = S3.CreateBucketRequest(bucket: bucketName)
            _ = try client.createBucket(input)
        }
    }
    
    public struct APIGatewayExecutor {
        let appName: String
        
        var apiName: String {
            return "hexaville-"+appName
        }
        
        var handler = "index.handler"
        
        let client: Apigateway
        
        init(appName: String, credential: Credential? = nil, region: Region? = nil, endpoint: String? = nil) {
            self.appName = appName
            
            if let credential = credential {
                self.client = Apigateway(
                    accessKeyId: credential.accessKeyId,
                    secretAccessKey: credential.secretAccessKey,
                    region: region,
                    endpoint: endpoint
                )
            } else {
                self.client = Apigateway(region: region, endpoint: endpoint)
            }
        }
        
        public func currentRestAPI() throws -> Apigateway.RestApi {
            let apis = try client.getRestApis(Apigateway.GetRestApisRequest())
            
            if let api = apis.items?.filter({ $0.name == apiName }).first {
                return api
            }
            
            return try client.createRestApi(Apigateway.CreateRestApiRequest(name: apiName))
        }
        
        public func methodIsExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
            do {
                let input = Apigateway.GetMethodRequest(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId)
                _ = try client.getMethod(input)
                return true
            } catch {
                return false
            }
        }
        
        public func integrationExists(restApiId: String, httpMethod: String, resourceId: String) -> Bool {
            do {
                let input = Apigateway.GetIntegrationRequest(restApiId: restApiId, httpMethod: httpMethod, resourceId: resourceId)
                _ = try client.getIntegration(input)
                return true
            } catch {
                return false
            }
        }
        
        public func stageExists(restApiId: String, deploymentStage: DeploymentStage) -> Bool {
            do {
                let input = Apigateway.GetStageRequest(restApiId: restApiId, stageName: deploymentStage.stringValue)
                _ = try client.getStage(input)
                return true
            } catch {
                return false
            }
        }
        
        public func methodResponseExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
            do {
                let input = Apigateway.GetMethodResponseRequest(
                    restApiId: restApiId,
                    statusCode: statusCode,
                    resourceId: resourceId,
                    httpMethod: httpMethod
                )
                
                _ = try client.getMethodResponse(input)
                return true
            } catch {
                return false
            }
        }
        
        public func integrationResponseExists(restApiId: String, statusCode: String, resourceId: String, httpMethod: String) -> Bool {
            do {
                let input = Apigateway.GetIntegrationResponseRequest(
                    restApiId: restApiId,
                    statusCode: statusCode,
                    resourceId: resourceId,
                    httpMethod: httpMethod
                )
                
                _ = try client.getIntegrationResponse(input)
                return true
            } catch {
                return false
            }
        }
    }
    
    public struct LambdaExecutor {
        let appName: String
        
        var functionName: String {
            return "hexaville-"+appName+"-function"
        }
        
        var handler = "index.handler"
        
        let client: Lambda
        
        let config: LambdaCodeConfig
        
        init(appName: String, credential: Credential? = nil, region: Region? = nil, endpoint: String? = nil, config: LambdaCodeConfig) {
            self.appName = appName
            
            if let credential = credential {
                self.client = Lambda(
                    accessKeyId: credential.accessKeyId,
                    secretAccessKey: credential.secretAccessKey,
                    region: region,
                    endpoint: endpoint
                )
            } else {
                self.client = Lambda(region: region, endpoint: endpoint)
            }
            
            self.config = config
        }
        
        public func updateFunctionCode(code: Lambda.FunctionCode) throws -> Lambda.FunctionConfiguration {
            do {
                _ = try getFunction()
                return try updateFunction(code: code)
            } catch LambdaError.resourceNotFoundException(_) {
                return try createFunction(
                    role: config.role,
                    timeout: config.timeout,
                    code: code,
                    memory: config.memory,
                    vpcConfig: config.vpcConfig,
                    environment: config.environment
                )
            } catch {
                throw error
            }
        }
        
        public func getFunction() throws -> Lambda.FunctionConfiguration {
            let input = Lambda.GetFunctionRequest(functionName: functionName)
            let output = try client.getFunction(input)
            guard let configuration = output.configuration else {
                throw LauncherError.missingRequiredParam("Lambda.GetFunctionResponse.configuration")
            }
            return configuration
        }
        
        public func updateFunction(code: Lambda.FunctionCode) throws -> Lambda.FunctionConfiguration {
            let input = Lambda.UpdateFunctionCodeRequest(
                s3ObjectVersion: code.s3ObjectVersion,
                functionName: functionName,
                s3Bucket: code.s3Bucket,
                publish: true,
                s3Key: code.s3Key,
                zipFile: nil
            )
            
            return try client.updateFunctionCode(input)
        }
        
        public func createFunction(role: String, timeout: Int = 10, code: Lambda.FunctionCode, memory: Int32? = nil, vpcConfig: Lambda.VpcConfig? = nil, environment: [String : String] = [:]) throws -> Lambda.FunctionConfiguration {
            
            let input = Lambda.CreateFunctionRequest(
                vpcConfig: vpcConfig,
                timeout: Int32(timeout),
                runtime: .nodejs4_3,
                publish: true,
                description: "Automatically generated by Hexaville",
                functionName: functionName,
                code: code,
                memorySize: memory,
                role: role,
                environment: Lambda.Environment(variables: environment),
                handler: handler
            )
            return try client.createFunction(input)
        }
        
        public func policies() -> JSON {
            do {
                let lambdaPolicies = try client.getPolicy(Lambda.GetPolicyRequest(functionName: functionName))
                
                guard let jsonString = lambdaPolicies.policy else { return [:] }
                let data = try JSONSerialization.jsonObject(with: jsonString.data, options: [])
                return JSON(data)
            } catch {
                return [:]
            }
        }
    }
}

extension AWSLauncherProvider {
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

extension AWSLauncherProvider {
    fileprivate func zipPackage(buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> Data {
        let pkgFileName = "\(hexavilleApplicationPath)/lambda-package.zip"
        let nodejsTemplatePath = "\(projectRoot)/templates/lambda/node.js"
        try String(contentsOfFile: "\(nodejsTemplatePath)/index.js")
            .replacingOccurrences(of: "{{executablePath}}", with: executableTarget)
            .write(toFile: buildResult.destination+"/index.js", atomically: true, encoding: .utf8)

        try String(contentsOfFile: "\(nodejsTemplatePath)/byline.js")
            .write(toFile: buildResult.destination+"/byline.js", atomically: true, encoding: .utf8)

        let proc = Proc("/bin/sh", ["\(projectRoot)/build-lambda-package.sh", pkgFileName, buildResult.destination])

        if proc.terminationStatus > 0 {
            throw AWSLauncherProviderError.createLambdaPackageFailed
        }
        
        let data = try Data(contentsOf: URL(string: "file://"+pkgFileName)!)
        
        try FileManager.default.removeItem(atPath: pkgFileName)
        
        return data
    }
    
    fileprivate func uploadCodeToS3(buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> Lambda.FunctionCode {
        let zipData = try zipPackage(
            buildResult: buildResult,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executableTarget: executableTarget
        )
        
        print("Uploading code to s3.....")
        _ = try s3.createBucketIfNotExists()
        let code = try s3.uploadCode(zipData: zipData)
        print("Code uploaded")
        
        return code
    }
}

extension AWSLauncherProvider {
    func routes(deploymentStage: DeploymentStage) throws -> Routes {
        let api = try apiGateway.currentRestAPI()
        let resources = try apiGateway.client.getResources(Apigateway.GetResourcesRequest(restApiId: api.id!))
        let resourceItems: [Apigateway.Resource] = resources.items ?? []
        
        let routes = resourceItems.map({
            Route(method: $0.resourceMethods?.keys.map({ $0 }) ?? [], resource: $0.path!)
        })
        
        return Routes(endpoint: endpoint(restApiId: api.id!, deploymentStage: deploymentStage), routes: routes)
    }
}

extension AWSLauncherProvider {
    func deploy(deploymentStage: DeploymentStage, buildResult: BuildResult, hexavilleApplicationPath: String, executableTarget: String) throws -> DeployResult {
        let code = try uploadCodeToS3(buildResult: buildResult, hexavilleApplicationPath: hexavilleApplicationPath, executableTarget: executableTarget)
        
        let lambdaConfiguration = try lambda.updateFunctionCode(code: code)
        
        let functionArn = lambdaConfiguration.functionArn!.replacingOccurrences(of: ":[0-9]*$", with: "", options: .regularExpression, range: nil)
        
        let lambdaURI = "arn:aws:apigateway:\(region.rawValue):lambda:path/2015-03-31/functions/\(functionArn)/invocations"
        
        let awsClinetId = lambdaURI.components(separatedBy: "/")[3].components(separatedBy: ":")[4]
        
        let api = try apiGateway.currentRestAPI()
        
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
            _ = try apiGateway.client.updateRestApi(input)
        }
        
        let resources = try apiGateway.client.getResources(Apigateway.GetResourcesRequest(restApiId: api.id!))
        var resourceItems: [Apigateway.Resource] = resources.items ?? []
        
        guard let rootResource = resourceItems.filter({ $0.path == "/" }).first else {
            throw LauncherError.couldNotFindRootResource
        }
        
        let lambdaPolicies = lambda.policies()
        
        let manifest = try String(contentsOfFile: hexavilleApplicationPath+"/.routing-manifest.json")
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
                    let response = try apiGateway.client.createResource(request)
                    print("Created CreateResource for \(response.toJSONString())")
                    lastApiResource = response
                    if !resourceItems.contains(where: { $0.id == response.id }) {
                        resourceItems.append(response)
                    }
                }
                
                if let httpMethod = apiResource.method?.uppercased() {
                    if !apiGateway.methodIsExists(restApiId: restApiId, httpMethod: httpMethod, resourceId: lastApiResource.id!) {
                        let putMethodRequest = Apigateway.PutMethodRequest(
                            httpMethod: httpMethod,
                            restApiId: restApiId,
                            apiKeyRequired: false,
                            authorizationType: "NONE",
                            resourceId: lastApiResource.id!
                        )
                        let out = try apiGateway.client.putMethod(putMethodRequest)
                        print("Created PutMethod for \(out.toJSONString())")
                    }
                    
                    if apiGateway.integrationExists(restApiId: restApiId, httpMethod: httpMethod, resourceId: lastApiResource.id!) {
                        let lambdaURIPatch = Apigateway.PatchOperation(
                            value: lambdaURI,
                            path: "/uri",
                            op: .replace
                        )
                        
                        let input = Apigateway.UpdateIntegrationRequest(
                            restApiId: restApiId,
                            patchOperations: [lambdaURIPatch],
                            resourceId: lastApiResource.id!,
                            httpMethod: httpMethod
                        )
                        let out = try apiGateway.client.updateIntegration(input)
                        print("Updated PutIntegration for \(out.toJSONString())")
                    } else {
                        let putIntegrationRequest = Apigateway.PutIntegrationRequest(
                            uri: lambdaURI,
                            restApiId: restApiId,
                            type: .aws_proxy,
                            resourceId: lastApiResource.id!,
                            httpMethod: httpMethod,
                            integrationHttpMethod: "POST"
                        )
                        let out = try apiGateway.client.putIntegration(putIntegrationRequest)
                        print("Created PutIntegration for \(out.toJSONString())")
                    }
                    
                    if apiGateway.integrationResponseExists(restApiId: restApiId, statusCode: "200", resourceId: lastApiResource.id!, httpMethod: httpMethod) {
                        
                    } else {
                        let input = Apigateway.PutIntegrationResponseRequest(
                            statusCode: "200",
                            httpMethod: httpMethod,
                            restApiId: restApiId,
                            resourceId: lastApiResource.id!
                        )
                        
                        let out = try apiGateway.client.putIntegrationResponse(input)
                        print("Created IntegrationResponse for \(out.toJSONString())")
                    }
                    
                    if apiGateway.methodResponseExists(restApiId: restApiId, statusCode: "200", resourceId: lastApiResource.id!, httpMethod: httpMethod) {
                        
                    } else {
                        let input = Apigateway.PutMethodResponseRequest(
                            restApiId: restApiId,
                            statusCode: "200",
                            resourceId: lastApiResource.id!,
                            httpMethod: httpMethod
                        )
                        let out = try apiGateway.client.putMethodResponse(input)
                        print("Created PutMethodResponse for \(out.toJSONString())")
                    }
                    
                    let sourceARN = try "arn:aws:execute-api:\(region.rawValue):\(awsClinetId):\(restApiId)/*/\(httpMethod)\(pathForARN(path))"
                    
                    activeSourceARNs.append(sourceARN)
                    
                    if lambdaPolicies["Statement"].arrayValue.filter({
                        $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.stringValue == sourceARN
                    }).count == 0 {
                        // TODO limit
                        let addPermissionRequest = Lambda.AddPermissionRequest(
                            statementId: UUID().uuidString.lowercased(),
                            functionName: lambda.functionName,
                            action: "lambda:InvokeFunction",
                            sourceArn: sourceARN,
                            principal: "apigateway.amazonaws.com"
                        )
                        _ = try lambda.client.addPermission(addPermissionRequest)
                    }
                }
            }
        }
        
        for resourceForDelete in resourcesForDelete {
            for method in resourceForDelete.methods {
                let input = Apigateway.DeleteMethodRequest(restApiId: restApiId, httpMethod: method.method, resourceId: resourceForDelete.resource.id!)
                print("deleting method for.... \(input.toJSONString())")
                _ = try apiGateway.client.deleteMethod(input)
            }
        }
        
        try lambdaPolicies["Statement"].arrayValue.filter({
            guard let arn = $0["Condition"]["ArnLike"].dictionaryValue["AWS:SourceArn"]?.string else { return false }
            return !activeSourceARNs.contains(arn)
        })
            .forEach { policy in
                let input = Lambda.RemovePermissionRequest(functionName: lambda.functionName, statementId: policy["Sid"].stringValue)
                print("deleting lambda policy for.... \(input.toJSONString())")
                _ = try lambda.client.removePermission(input)
        }
        
        for resourceForDelete in resourcesForDelete {
            if !resourceForDelete.shouldDeleteResource { continue }
            let input = Apigateway.DeleteResourceRequest(restApiId: restApiId, resourceId: resourceForDelete.resource.id!)
            
            print("deleting resource for.... \(input.toJSONString())")
            try apiGateway.client.deleteResource(input)
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
        
        _ = try apiGateway.client.createDeployment(createDeploymentRequest)
        
        return DeployResult(
            endpoint: "https://\(restApiId).execute-api.\(region.rawValue).amazonaws.com/\(deploymentStage.stringValue)"
        )
    }
    
    fileprivate func pathForARN(_ path: String) throws -> String {
        let regex = try NSRegularExpression(pattern: "\\{[a-zA-Z_-]*\\}", options: [])
        return regex.stringByReplacingMatches(in: path, options: [], range: NSRange(location: 0, length: path.characters.count), withTemplate: "*")
    }
}
