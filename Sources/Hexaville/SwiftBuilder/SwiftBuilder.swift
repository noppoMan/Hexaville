//
//  SwiftBuilder.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation

enum OS {
    case linux_x86
    case mac
    
    static var current: OS {
        #if os(Linux)
            return .linux_x86
        #else
            return .mac
        #endif
    }
}

enum SwiftBuilderError: Error {
    case unsupportedPlatform(String)
}

class SwiftBuilder {
    static var swiftDownloadURL = "https://swift.org/builds/swift-3.1-release/ubuntu1404/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu14.04.tar.gz"
    
    static var swiftFileName: String {
        let paths = swiftDownloadURL.components(separatedBy: "/")
        let fileName = paths[paths.count-1]
        return fileName.components(separatedBy: ".tar.gz")[0]
    }
    
    public func build(with defaultProvider: SwiftBuildEnvironmentProvider? = nil, config: BuildConfiguration, hexavilleApplicationPath: String) throws -> BuildResult {
        if let defaultProvider = defaultProvider {
            return try defaultProvider.build(config: config, hexavilleApplicationPath: hexavilleApplicationPath)
        }
        
        switch OS.current {
        case .mac:
            let provider = DockerBuildEnvironmentProvider()
            return try provider.build(config: config, hexavilleApplicationPath: hexavilleApplicationPath)
            
        case .linux_x86:
            throw SwiftBuilderError.unsupportedPlatform("linux_x86")
        }
    }
    
}
