//
//  Swift.swift
//  PKGConfig
//
//  Created by Yuki Takei on 2018/11/29.
//

import Foundation

extension HexavilleFile {
    public enum ConfigurationType: String, Codable {
        case debug = "debug"
        case release = "release"
    }
    
    public struct SwiftBuildOption: Codable {
        let configuration: ConfigurationType
    }
    
    public struct Swift: Decodable {
        public let version: SwiftVersion
        public let buildOptions: SwiftBuildOption?
        
        var buildMode: ConfigurationType {
            return buildOptions?.configuration ?? .debug
        }
    }
}
