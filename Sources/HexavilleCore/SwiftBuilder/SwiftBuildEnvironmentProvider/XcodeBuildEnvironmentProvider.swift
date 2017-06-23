//
//  XcodeBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

struct XcodeBuildEnvironmentProvider: SwiftBuildEnvironmentProvider {
    
    let useDerivedDataPath: Bool
    
    init(useDerivedDataPath: Bool = true) {
        self.useDerivedDataPath = useDerivedDataPath
    }
    
    func build(config: Configuration, hexavilleApplicationPath: String) throws -> BuildResult {
        _ = Process.exec("swift", ["build", "--chdir", hexavilleApplicationPath])
        return BuildResult(destination: hexavilleApplicationPath+"/.build/debug")
    }
}
