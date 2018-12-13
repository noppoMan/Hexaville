//
//  CloudService.swift
//  PKGConfig
//
//  Created by Yuki Takei on 2018/11/29.
//

import Foundation

extension HexavilleFile {
    public enum Provider {
        public struct AWS: Codable {
            public struct Credential: Codable {
                public let accessKeyId: String
                public let secretAccessKey: String
                
                public init(accessKeyId: String, secretAccessKey: String) {
                    self.accessKeyId = accessKeyId
                    self.secretAccessKey = secretAccessKey
                }
            }
            
            public struct Lambda: Codable {
                public let s3Bucket: String?
                public let role: String?
                public let memory: Int32
                public let timeout: Int32
                public let vpc: VPC?
                
                public init(
                    s3Bucket: String?,
                    role: String? = nil,
                    timeout: Int32 = 10,
                    memory: Int32 = 256,
                    vpc: VPC? = nil) {
                    self.s3Bucket = s3Bucket
                    self.role = role
                    self.timeout = timeout
                    self.memory = memory
                    self.vpc = vpc
                }
            }
            
            public struct VPC: Codable {
                public let subnetIds: [String]
                public let securityGroupIds: [String]
                
                public init(subnetIds: [String], securityGroupIds: [String]) {
                    self.subnetIds = subnetIds
                    self.securityGroupIds = securityGroupIds
                }
            }
            
            public let credential: Credential?
            
            public let region: String?
            
            public let lambda: Lambda
            
            public init(
                credential: Credential? = nil,
                region: String? = nil,
                lambda: Lambda) {
                self.credential = credential
                self.region = region
                self.lambda = lambda
            }
        }
        
        case aws(AWS)
    }
}

extension HexavilleFile.Provider: Codable {
    enum CodingKeys: CodingKey {
        case aws
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let aws = try container.decode(HexavilleFile.Provider.AWS.self, forKey: .aws)
        self = .aws(aws)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .aws(let aws):
            try container.encode(aws, forKey: .aws)
        }
    }
}

