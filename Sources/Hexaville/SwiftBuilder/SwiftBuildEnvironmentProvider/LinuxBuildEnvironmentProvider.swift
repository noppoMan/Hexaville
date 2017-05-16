//
//  LinuxBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

struct LinuxBuildEnvironmentProvider: SwiftBuildEnvironmentProvider {
    func build(config: BuildConfiguration, hexavilleApplicationPath: String) throws -> BuildResult {
        throw SwiftBuilderError.unsupportedPlatform("Linux")
    }
}
