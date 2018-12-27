//
//  SwiftBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

public struct BuildResult {
    public let destination: String
    public let dockerTag: String?
    
    init(destination: String, dockerTag: String? = nil) {
        self.destination = destination
        self.dockerTag = dockerTag
    }
}

public protocol SwiftBuildEnvironmentProvider {
    func build(config: HexavilleFile, hexavilleApplicationPath: String, executable: String) throws -> BuildResult
}
