//
//  SwiftPMDumpPackageTests.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/10/10.
//

import Foundation

import XCTest
@testable import HexavilleCore

class SwiftPMDumpPackageTests: XCTestCase {

    var dumpPackageSample: Data {
        return """
          {
            "cLanguageStandard": null,
            "cxxLanguageStandard": null,
            "dependencies": [
              {
                "requirement": {
                  "lowerBound": "1.0.1",
                  "type": "range",
                  "upperBound": "2.0.0"
                },
                "url": "https://github.com/swift-aws/s3.git"
              },
              {
                "requirement": {
                  "lowerBound": "1.0.1",
                  "type": "range",
                  "upperBound": "2.0.0"
                },
                "url": "https://github.com/swift-aws/lambda.git"
              },
              {
                "requirement": {
                  "lowerBound": "1.0.1",
                  "type": "range",
                  "upperBound": "2.0.0"
                },
                "url": "https://github.com/swift-aws/iam.git"
              },
              {
                "requirement": {
                  "lowerBound": "1.0.1",
                  "type": "range",
                  "upperBound": "2.0.0"
                },
                "url": "https://github.com/swift-aws/apigateway.git"
              },
              {
                "requirement": {
                  "lowerBound": "16.0.0",
                  "type": "range",
                  "upperBound": "17.0.0"
                },
                "url": "https://github.com/IBM-Swift/SwiftyJSON.git"
              },
              {
                "requirement": {
                  "lowerBound": "3.1.0",
                  "type": "range",
                  "upperBound": "4.0.0"
                },
                "url": "https://github.com/jakeheis/SwiftCLI.git"
              },
              {
                "requirement": {
                  "lowerBound": "3.0.0",
                  "type": "range",
                  "upperBound": "4.0.0"
                },
                "url": "https://github.com/behrang/YamlSwift.git"
              }
            ],
            "name": "Hexaville",
            "products": [
              {
                "name": "HexavilleCore",
                "product_type": "library",
                "targets": [
                  "HexavilleCore"
                ],
                "type": null
              },
              {
                "name": "hexaville",
                "product_type": "executable",
                "targets": [
                  "Hexaville"
                ]
              }
            ],
            "targets": [
              {
                "dependencies": [
                  {
                    "name": "SwiftAWSS3",
                    "type": "byname"
                  },
                  {
                    "name": "SwiftAWSLambda",
                    "type": "byname"
                  },
                  {
                    "name": "SwiftAWSIam",
                    "type": "byname"
                  },
                  {
                    "name": "SwiftAWSApigateway",
                    "type": "byname"
                  },
                  {
                    "name": "SwiftyJSON",
                    "type": "byname"
                  },
                  {
                    "name": "SwiftCLI",
                    "type": "byname"
                  },
                  {
                    "name": "Yaml",
                    "type": "byname"
                  }
                ],
                "exclude": [

                ],
                "isTest": false,
                "name": "HexavilleCore",
                "path": null,
                "publicHeadersPath": null,
                "sources": null
              },
              {
                "dependencies": [
                  {
                    "name": "HexavilleCore",
                    "type": "byname"
                  }
                ],
                "exclude": [

                ],
                "isTest": false,
                "name": "Hexaville",
                "path": null,
                "publicHeadersPath": null,
                "sources": null
              },
              {
                "dependencies": [
                  {
                    "name": "HexavilleCore",
                    "type": "byname"
                  }
                ],
                "exclude": [

                ],
                "isTest": true,
                "name": "HexavilleTests",
                "path": null,
                "publicHeadersPath": null,
                "sources": null
              }
            ]
          }
          """.data
    }


    func testDecodeFromJSON() {
        do {
            let dumpPackage = try JSONDecoder().decode(SwiftPMDumpPackage.self, from: dumpPackageSample)
            let product = dumpPackage.findProduct(fromTargetName: "Hexaville")!
            XCTAssertTrue(product.isExecutable)
            XCTAssertEqual(product.name, "hexaville")
        } catch {
            XCTFail("\(error)")
        }
    }

    static var allTests = [
        ("testDecodeFromJSON", testDecodeFromJSON),
    ]
}
