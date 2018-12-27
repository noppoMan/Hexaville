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
"""
    }
    
    static var allTests = [
        ("testload", testload),
    ]

    func testload() {
        do {
            let hexavilleFile = try HexavilleFile.load(ymlString: hexavillefileForAWS)

            XCTAssertEqual(hexavilleFile.appName, "testApp")
            XCTAssert(hexavilleFile.docker!.buildOptions.nocache!)
            XCTAssertEqual(hexavilleFile.swift.buildMode.rawValue, "release")
            XCTAssertEqual(hexavilleFile.swift.version.asCompareableVersion(), Version(major: 4, minor: 2))
            
        } catch {
            XCTFail("\(error)")
        }
    }
}
