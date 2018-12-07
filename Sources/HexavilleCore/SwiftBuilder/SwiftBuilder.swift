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
    let version: SwiftVersion
    
    init(version: SwiftVersion) {
        self.version = version
    }
    
    func build(with defaultProvider: SwiftBuildEnvironmentProvider? = nil, config: HexavilleFile, hexavilleApplicationPath: String, executable: String) throws -> BuildResult {
        let provider = DockerBuildEnvironmentProvider()
        return try provider.build(
            config: config,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: executable
        )
    }
}
