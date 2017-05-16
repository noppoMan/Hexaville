//
//  BuildConfiguration.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation
import Yaml

public struct BuildConfiguration {
    let noCache: Bool
    
    public init(noCache: Bool = false){
        self.noCache = noCache
    }
}

extension BuildConfiguration {
    init(yml: Yaml) {
        self.noCache = yml["nocache"].bool ?? false
    }
}
