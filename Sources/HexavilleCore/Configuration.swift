//
//  BuildConfiguration.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation
import Yaml
import AWSSDKSwift
import Core

public struct AWSConfiguration {
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
        public let role: String
        public let bucket: String
        public let timeout: Int
        public let memory: Int32?
        public let vpcConfig: Lambda.VpcConfig?
        public let environment: [String : String]
        
        public init(role: String, bucket: String, timeout: Int = 10, memory: Int32? = nil, vpcConfig: Lambda.VpcConfig? = nil, environment: [String : String] = [:]) {
            self.role = role
            self.bucket = bucket
            self.timeout = timeout
            self.memory = memory
            self.vpcConfig = vpcConfig
            self.environment = environment
        }
    }
    
    public let credential: Credential?
    public let region: Region?
    public let endpoints: Endpoints?
    public let lambdaCodeConfig: LambdaCodeConfig
    
    public init(credential: Credential? = nil, region: Region? = nil, endpoints: Endpoints? = nil, lambdaCodeConfig: LambdaCodeConfig) {
        self.credential = credential
        self.region = region
        self.endpoints = endpoints
        self.lambdaCodeConfig = lambdaCodeConfig
    }
}

public struct Configuration {
    public struct BuildConfiguration {
        public let noCache: Bool
        
        public init(noCache: Bool = false){
            self.noCache = noCache
        }
    }
    
    public enum PlatformConfiguration {
        case aws(AWSConfiguration)
    }
    
    // TODO should extend
    public static var binaryMediaTypes: [String] = [
        "image/*",
        "application/x-protobuf",
        "application/x-google-protobuf",
        "application/octet-stream"
    ]
    
    public let name: String
    
    public let forBuild: BuildConfiguration
    
    public let forPlatform: PlatformConfiguration
    
    public init(name: String, platformConfiguration: PlatformConfiguration,  buildConfiguration: BuildConfiguration) {
        self.name = name
        self.forPlatform = platformConfiguration
        self.forBuild = buildConfiguration
    }
}
