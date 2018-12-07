//
//  HexavilleFile+AWSSDKSwift.swift
//  APIGateway
//
//  Created by Yuki Takei on 2018/11/30.
//

import Foundation
import Lambda
import AWSSDKSwiftCore

extension HexavilleFile.Provider.AWS {
    var awsSDKSwiftCredential: AWSSDKSwiftCore.Credential? {
        if let cred = self.credential {
            return AWSSDKSwiftCore.Credential(
                accessKeyId: cred.accessKeyId,
                secretAccessKey: cred.secretAccessKey
            )
        }
        
        return nil
    }
    
    var awsSDKSwiftRegion: AWSSDKSwiftCore.Region? {
        if let r = self.region {
            return AWSSDKSwiftCore.Region(rawValue: r)
        }
        
        return nil
    }
}

typealias AWSLambda = Lambda

extension HexavilleFile.Provider.AWS.Lambda {
    var awsSDKSwiftVPCConfig: AWSLambda.VpcConfig? {
        if let vpc = self.vpc {
            return AWSLambda.VpcConfig(securityGroupIds: vpc.securityGroupIds, subnetIds: vpc.subnetIds)
        }
        
        return nil
    }
}
