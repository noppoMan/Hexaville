//
//  Docker.swift
//  PKGConfig
//
//  Created by Yuki Takei on 2018/11/29.
//

import Foundation

extension HexavilleFile {
    public struct DockerBuildOption: Codable {
        let nocache: Bool?
    }
    
    public struct Docker: Codable {
        public let buildOptions: DockerBuildOption
    }
}
