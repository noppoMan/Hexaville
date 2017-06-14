//
//  HexavillefileLoader.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/29.
//
//

import Foundation
import Yaml

public protocol PlatformConfigurationLoadable {
    func load() throws -> Configuration.PlatformConfiguration
}

public struct HexavillefileLoader {
    public static func load(hexavilleFilePath: String) throws -> Yaml {
        let ymlString = try String(contentsOfFile: hexavilleFilePath, encoding: .utf8)
        return try Yaml.load(ymlString)
    }
    
    public let config: Yaml
    
    public init(fromYaml config: Yaml) {
        self.config = config
    }
    
    public init(fromYamlString config: String) throws {
        self.config = try Yaml.load(config)
    }
    
    public init(fromHexavillefilePath hexavilleFilePath: String) throws {
        self.config = try HexavillefileLoader.load(hexavilleFilePath: hexavilleFilePath)
    }
    
    public func load(withEnvironment environment: [String: String] = [:]) throws -> Configuration {
        guard let service = config["service"].string else {
            throw HexavilleCoreError.missingRequiredParamInHexavillefile("service")
        }
        
        guard let appName = config["name"].string else {
            throw HexavilleCoreError.missingRequiredParamInHexavillefile("name")
        }
        
        let buildConfiguration = Configuration.BuildConfiguration(noCache: config["build"]["nocache"].bool ?? false)
        
        switch service {
        case "aws":
            return Configuration(
                name: appName,
                platformConfiguration: try AWSLoader(appName: appName, yaml: config["aws"], environment: environment).load(),
                buildConfiguration: buildConfiguration
            )
            
        default:
            throw HexavilleCoreError.unsupportedService(service)
        }
    }
}
