//
//  AWSLoader.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/29.
//
//

import Foundation
import Yaml
import AWSSDKSwiftCore
import SwiftAWSLambda

struct AWSLoader: PlatformConfigurationLoadable {
    
    let appName: String
    
    let config: Yaml
    
    let environment: [String: String]
    
    init(appName: String, yaml: Yaml, environment: [String: String] = [:]) {
        self.config = yaml
        self.appName = appName
        self.environment = environment
    }
    
    func load() throws -> Configuration.PlatformConfiguration {
        var cred: AWSSDKSwiftCore.Credential?
        
        if let accessKey = config["credential"]["access_key_id"].string, let secretKey = config["credential"]["secret_access_key"].string {
            cred = Credential(
                accessKeyId: accessKey,
                secretAccessKey: secretKey
            )
        }
        
        guard let lambdaBucket = config["lambda"]["bucket"].string else {
            throw HexavilleCoreError.missingRequiredParamInHexavillefile("aws.lambda.bucket")
        }
        
        var vpcConfig: Lambda.VpcConfig?
        if let vpcConf = config["lambda"]["vpc"].dictionary {
            vpcConfig = Lambda.VpcConfig(
                subnetIds: vpcConf["subnetIds"]?.array?.flatMap({ $0.string }),
                securityGroupIds: vpcConf["securityGroupIds"]?.array?.flatMap({ $0.string })
            )
        }
        
        let lambdaCodeConfig = AWSConfiguration.LambdaCodeConfig(
            role: config["lambda"]["role"].string ?? "",
            bucket: lambdaBucket,
            timeout: config["lambda"]["timout"].int ?? 10,
            vpcConfig: vpcConfig,
            environment: environment
        )
        
        var region: AWSSDKSwiftCore.Region?
        if let reg = config["region"].string {
            region = Region(rawValue: reg)
        }
        
        let awsConfiguration = AWSConfiguration(
            credential: cred,
            region: region,
            endpoints: nil,
            lambdaCodeConfig: lambdaCodeConfig
        )
        
        return .aws(awsConfiguration)
    }
}

