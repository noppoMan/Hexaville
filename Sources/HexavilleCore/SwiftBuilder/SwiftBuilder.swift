//
//  SwiftBuilder.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//
import Foundation

enum SwiftBuilderError: Error {
    case unsupportedPlatform(String)
    case swiftBuildFailed
}

class SwiftBuilder {
    let version: SwiftVersionContainer
    
    init(version: SwiftVersionContainer) {
        self.version = version
    }
    
    func build(with defaultProvider: SwiftBuildEnvironmentProvider? = nil, config: Configuration, hexavilleApplicationPath: String, executable: String) throws -> BuildResult {
        let provider = DockerBuildEnvironmentProvider()
        return try provider.build(
            config: config,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: executable
        )
    }
}
