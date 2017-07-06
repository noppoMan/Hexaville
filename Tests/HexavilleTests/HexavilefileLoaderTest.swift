//
//  HexavilefileLoaderTest.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/29.
//
//

import Foundation

import XCTest
@testable import HexavilleCore

class HexavilefileLoaderTest: XCTestCase {
    
    var hexavillefileForAWS: String {
        var str = ""
        str += "name: test-app\n"
        str += "service: aws\n"
        str += "aws:\n"
        str += "  credential:\n"
        str += "    access_key_id: access_key\n"
        str += "    secret_access_key: secret_access_key\n"
        str += "  region: ap-northeast-1\n"
        str += "  lambda:\n"
        str += "    bucket: hexaville-test-app-8uh-bucket\n"
        str += "    role: arn:aws:iam::foo:role/lambda_basic_execution\n"
        str += "    timout: 10\n"
        str += "    vpc:\n"
        str += "      subnetIds:\n"
        str += "        - subnet-foo-bar\n"
        str += "        - subnet-bar-foo\n"
        str += "      securityGroupIds:\n"
        str += "        - sg-foo-bar\n"
        str += "        - sg-bar-foo\n"
        str += "build:\n"
        str += "  nocache: true\n"
        str += "swift:\n"
        str += "  build:\n"
        str += "    configuration: release\n"
        
        return str
    }
    
    static var allTests = [
        ("testloadAWS", testloadAWS),
    ]

    func testloadAWS() {
        do {
            let loader = try HexavillefileLoader(fromYamlString: hexavillefileForAWS)
            let configuration = try loader.load()

            XCTAssertEqual(configuration.name, "test-app")
            XCTAssert(configuration.forBuild.noCache)
            XCTAssertEqual(configuration.forSwift.build.configuration, "release")
            
            switch configuration.forPlatform {
            case .aws(let config):
                XCTAssertEqual(config.credential?.accessKeyId, "access_key")
                XCTAssertEqual(config.credential?.secretAccessKey, "secret_access_key")
                XCTAssertEqual(config.region?.rawValue, "ap-northeast-1")
                
                XCTAssertEqual(config.lambdaCodeConfig.bucket, "hexaville-test-app-8uh-bucket")
                XCTAssertEqual(config.lambdaCodeConfig.role, "arn:aws:iam::foo:role/lambda_basic_execution")
                XCTAssertEqual(config.lambdaCodeConfig.timeout, 10)
                XCTAssertEqual(config.lambdaCodeConfig.vpcConfig!.subnetIds!, ["subnet-foo-bar", "subnet-bar-foo"])
                XCTAssertEqual(config.lambdaCodeConfig.vpcConfig!.securityGroupIds!, ["sg-foo-bar", "sg-bar-foo"])
            }
            
        } catch {
            XCTFail("\(error)")
        }
    }
}
