//
//  DotEnvParserTests.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation

import XCTest
@testable import HexavilleCore

class DotEnvParserTests: XCTestCase {
    
    var dotenv: String {
        var str = ""
        str += "FOO=bar\n"
        str += "BAR=foo\n"
        str += "#Hoge=fuga\n"
        str += "\n"
        str += "Fiz=baz"
        return str
    }
    
    static var allTests = [
        ("testParse", testParse),
    ]
    
    func testParse() {
        let env = try! DotEnvParser.parse(fromString: dotenv)
        XCTAssertEqual(env.count, 3)
        XCTAssertEqual(env["Fiz"], "baz")
    }
}
