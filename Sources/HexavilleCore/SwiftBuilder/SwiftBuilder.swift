//
//  SwiftBuilder.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//
import Foundation

public enum SwiftBuilderError: Error {
    case unsupportedPlatform(String)
    case swiftBuildFailed
}

public class SwiftBuilder {
    public let version: SwiftVersion
    
    public init(version: SwiftVersion) {
        self.version = version
    }
    
    public func build(with defaultProvider: SwiftBuildEnvironmentProvider? = nil, config: HexavilleFile, hexavilleApplicationPath: String, executable: String) throws -> BuildResult {
        let provider = DockerBuildEnvironmentProvider()
        return try provider.build(
            config: config,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: executable
        )
    }
}
