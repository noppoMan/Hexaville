//
//  BuildConfiguration.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation
import Yaml

public struct Configuration {
    public struct BuildConfiguration {
        let noCache: Bool
        
        public init(noCache: Bool = false){
            self.noCache = noCache
        }
    }
    
    // TODO should extend
    static var binaryMediaTypes: [String] = [
        "image/*",
        "application/x-protobuf",
        "application/x-google-protobuf",
        "application/octet-stream"
    ]
    
    let build: BuildConfiguration
    
    init(yml: Yaml) {
        self.build = BuildConfiguration(noCache: yml["nocache"].bool ?? false)
    }
    
    init() {
        self.build = BuildConfiguration()
    }
}
