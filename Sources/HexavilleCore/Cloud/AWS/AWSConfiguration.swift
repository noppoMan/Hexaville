//
//  AWSConfiguration.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/12/18.
//

import Foundation
import S3
import Lambda
import APIGateway
import IAM
import AWSSDKSwiftCore

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
        public let role: String?
        public let bucket: String
        public let timeout: Int
        public let memory: Int32?
        public let vpcConfig: Lambda.VpcConfig?
        public let environment: [String : String]
        
        public init(role: String?, bucket: String, timeout: Int = 10, memory: Int32? = nil, vpcConfig: Lambda.VpcConfig? = nil, environment: [String : String] = [:]) {
            self.role = role
            self.bucket = bucket
            self.timeout = timeout
            self.memory = memory
            self.vpcConfig = vpcConfig
            self.environment = environment
        }
    }
    
    public let credential: AWSSDKSwiftCore.Credential?
    public let region: AWSSDKSwiftCore.Region?
    public let endpoints: Endpoints?
    public let lambdaCodeConfig: LambdaCodeConfig
    
    public init(credential: AWSSDKSwiftCore.Credential? = nil, region: AWSSDKSwiftCore.Region? = nil, endpoints: Endpoints? = nil, lambdaCodeConfig: LambdaCodeConfig) {
        self.credential = credential
        self.region = region
        self.endpoints = endpoints
        self.lambdaCodeConfig = lambdaCodeConfig
    }
}
