//
//  SwiftBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

struct BuildResult {
    let destination: String
    let dockerTag: String?
    
    init(destination: String, dockerTag: String? = nil) {
        self.destination = destination
        self.dockerTag = dockerTag
    }
}

protocol SwiftBuildEnvironmentProvider {
    func build(config: Configuration, hexavilleApplicationPath: String, executableTarget: String) throws -> BuildResult
}
