//
//  AWSLoader.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/29.
//
//

import Foundation
import AWSSDKSwift
import Core
import Yaml

struct AWSLoader: HexavillefileLoadable {
    
    let appName: String
    
    let config: Yaml
    
    init(appName: String, yaml: Yaml) {
        self.config = yaml
        self.appName = appName
    }
    
    func load() throws -> CloudLauncherProvider {
        var cred: Credential?
        
        if let accessKey = config["credential"]["access_key_id"].string, let secretKey = config["credential"]["secret_access_key"].string {
            cred = Credential(
                accessKeyId: accessKey,
                secretAccessKey: secretKey
            )
        }
        
        guard let lambdaBucket = config["lambda"]["bucket"].string else {
            throw HexavilleError.missingRequiredParamInHexavillefile("aws.lambda.bucket")
        }
        
        var vpcConfig: Lambda.VpcConfig?
        if let vpcConf = config["lambda"]["vpc"].dictionary {
            vpcConfig = Lambda.VpcConfig(
                subnetIds: vpcConf["subnetIds"]?.array?.flatMap({ $0.string }),
                securityGroupIds: vpcConf["securityGroupIds"]?.array?.flatMap({ $0.string })
            )
        }
        
        let lambdaCodeConfig = AWSLauncherProvider.LambdaCodeConfig(
            role: config["lambda"]["role"].string ?? "",
            bucket: lambdaBucket,
            timeout: config["lambda"]["timout"].int ?? 10,
            vpcConfig: vpcConfig
        )
        
        var region: Region?
        if let reg = config["region"].string {
            region = Region(rawValue: reg)
        }
        
        let provider = AWSLauncherProvider(
            appName: appName,
            credential: cred,
            region: region,
            lambdaCodeConfig: lambdaCodeConfig
        )
        
        return .aws(provider)
    }
}

