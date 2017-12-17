//
//  BuildConfiguration.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation
import Yaml

public enum ConfigurationError: Error {
    case invalidSwiftBuildConfiguration(String)
}

public struct Configuration {
    public struct SwiftConfiguration {
        
        public static var supportedVersionsRange: CountableClosedRange<Int> {
            return 3...4
        }
        
        public static var defaultVersion: SwiftVersion {
            return .release(Version(major: 4, minor: 0))
        }
        
        public struct Build {
            public let configuration: String
            
            public init(configuration: String = "debug"){
                self.configuration = configuration
            }
        }
        
        public let build: Build
        
        public let version: SwiftVersion
        
        init(yml: Yaml) throws {
            let swiftBuildConfiguration = yml["build"]["configuration"].string ?? "debug"
            guard ["release", "debug"].contains(swiftBuildConfiguration) else {
                throw ConfigurationError.invalidSwiftBuildConfiguration(swiftBuildConfiguration)
            }
            self.build = Build(configuration: swiftBuildConfiguration)
            
            let versionYml = yml["version"]
            
            if let version = versionYml.string {
                self.version = try SwiftVersion(string: version)
                
            } else if let version = versionYml.double {
                self.version = .release(try Version(string: version.description))
                
            } else if let version = versionYml.int {
                self.version = .release(try Version(string: version.description))
                
            } else {
                self.version = SwiftConfiguration.defaultVersion
            }
        }
    }
    
    public struct BuildConfiguration {
        public let noCache: Bool
        
        public init(noCache: Bool = false){
            self.noCache = noCache
        }
    }
    
    public enum PlatformConfiguration {
        case aws(AWSConfiguration)
    }
    
    // TODO should extend
    public static var binaryMediaTypes: [String] = [
        "image/*",
        "application/x-protobuf",
        "application/x-google-protobuf",
        "application/octet-stream"
    ]
    
    public let name: String
    
    public let forBuild: BuildConfiguration
    
    public let forPlatform: PlatformConfiguration
    
    public let forSwift: SwiftConfiguration
    
    public init(name: String, platformConfiguration: PlatformConfiguration,  buildConfiguration: BuildConfiguration, swiftConfiguration: SwiftConfiguration) {
        self.name = name
        self.forPlatform = platformConfiguration
        self.forBuild = buildConfiguration
        self.forSwift = swiftConfiguration
    }
}
