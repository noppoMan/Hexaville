//
//  DotEnvParser.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation

public struct DotEnvParser {
    
    public static func parse(fromFile file: String) throws -> [String: String] {
        return try self.parse(fromString: String(contentsOfFile: file))
    }
    
    public static func parse(fromString string: String) throws -> [String: String] {
        var env: [String: String] = [:]
        string.components(separatedBy: "\n")
            .forEach {
                if $0.isEmpty { return }
                let first = $0.substring(with: $0.startIndex..<$0.index($0.startIndex, offsetBy: 1))
                if first == "#" { return }
                let splited = $0.components(separatedBy: "=")
                guard splited.count > 1 else { return }
                env[splited[0]] = splited[1]
        }
        return env
    }
    
}
