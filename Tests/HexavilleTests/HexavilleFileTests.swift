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
        return """
appName: testApp
executableTarget: testApp
swift:
    version: 4.2
    buildOptions:
        configuration: release

docker:
    buildOptions:
        nocache: true

provider:
    aws:
        credential:
            accessKeyId: access_key
            secretAccessKey: secret_access_key
        region: ap-northeast-1
        lambda:
            s3Bucket: hexaville-test-app-8uh-bucket
            role: arn:aws:iam::foo:role/lambda_basic_execution
            timeout: 20
            memory: 512
            vpc:
                subnetIds:
                    - subnet-foo-bar
                    - subnet-bar-foo
                securityGroupIds:
                    - sg-foo-bar
                    - sg-bar-foo
"""
    }
    
    static var allTests = [
        ("testloadAWS", testloadAWS),
    ]

    func testloadAWS() {
        do {
            let hexavilleFile = try HexavilleFile.load(ymlString: hexavillefileForAWS)

            XCTAssertEqual(hexavilleFile.appName, "testApp")
            XCTAssert(hexavilleFile.docker!.buildOptions.nocache!)
            XCTAssertEqual(hexavilleFile.swift.buildMode.rawValue, "release")

            switch hexavilleFile.provider {
            case .aws(let config):
                XCTAssertEqual(config.credential?.accessKeyId, "access_key")
                XCTAssertEqual(config.credential?.secretAccessKey, "secret_access_key")
                XCTAssertEqual(config.region, "ap-northeast-1")

                XCTAssertEqual(config.lambda.s3Bucket, "hexaville-test-app-8uh-bucket")
                XCTAssertEqual(config.lambda.role, "arn:aws:iam::foo:role/lambda_basic_execution")
                XCTAssertEqual(config.lambda.timeout, 20)
                XCTAssertEqual(config.lambda.memory, 512)
                XCTAssertEqual(config.lambda.vpc!.subnetIds, ["subnet-foo-bar", "subnet-bar-foo"])
                XCTAssertEqual(config.lambda.vpc!.securityGroupIds, ["sg-foo-bar", "sg-bar-foo"])
            }
            
            XCTAssertEqual(hexavilleFile.swift.version.asCompareableVersion(), Version(major: 4, minor: 2))
            
        } catch {
            XCTFail("\(error)")
        }
    }
}
