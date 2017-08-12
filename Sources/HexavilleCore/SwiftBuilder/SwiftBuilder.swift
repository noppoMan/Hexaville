//
//  SwiftBuilder.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation

enum SwiftVersionError: Error {
    case invalidVersion(String)
    case notEmpty
}

public struct SwiftVersion {
    public let major: Int
    public let minor: Int
    public let patch: Int
    
    public var versionString: String {
        var version = "\(major).\(minor)"
        if patch > 0 {
            version += ".\(patch)"
        }
        return version
    }
    
    public init(major: Int, minor: Int, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

extension SwiftVersion : Hashable {
    public var hashValue: Int {
        return (major << 8) | minor | patch
    }
    
    public static func == (lhs: SwiftVersion, rhs: SwiftVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func ~= (match: SwiftVersion, version: SwiftVersion) -> Bool {
        return match == version
    }
}

extension SwiftVersion : Comparable {
    public static func < (lhs: SwiftVersion, rhs: SwiftVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else {
            return lhs.minor < rhs.minor && lhs.patch < rhs.patch
        }
    }
}

extension SwiftVersion {
    public init(string: String) throws {
        let components = string.components(separatedBy: ".")
        if components.count == 0 {
            throw SwiftVersionError.notEmpty
        }
        
        var intCastedComponents: [Int] = try components.map({
            guard let int = Int($0) else {
                throw SwiftVersionError.invalidVersion(string)
            }
            return int
        })
        
        switch intCastedComponents.count {
        case 1:
            self = SwiftVersion(major: intCastedComponents[0], minor: 0)
        case 2:
            self = SwiftVersion(major: intCastedComponents[0], minor: intCastedComponents[1])
        case 3:
            self = SwiftVersion(major: intCastedComponents[0], minor: intCastedComponents[1], patch: intCastedComponents[2])
        default:
            throw SwiftVersionError.invalidVersion(string)
        }
    }
}

extension SwiftVersion {
    var fileName: String {
        if self.major == 4 {
            return "swift-4.0-DEVELOPMENT-SNAPSHOT-2017-07-22-a-ubuntu14.04"
        } else {
            return "swift-\(versionString)-RELEASE-ubuntu14.04"
        }
    }
    
    var downloadURLString: String {
        if self.major == 4 {
            return "https://swift.org/builds/swift-4.0-branch/ubuntu1404/swift-4.0-DEVELOPMENT-SNAPSHOT-2017-07-22-a/\(fileName).tar.gz"
        } else {
            return "https://swift.org/builds/swift-\(versionString)-release/ubuntu1404/swift-\(versionString)-RELEASE/swift-\(versionString)-RELEASE-ubuntu14.04.tar.gz"
        }
    }
}

enum SwiftBuilderError: Error {
    case unsupportedPlatform(String)
    case swiftBuildFailed
}

class SwiftBuilder {
    let version: SwiftVersion
    
    init(version: SwiftVersion) {
        self.version = version
    }
    
    func build(with defaultProvider: SwiftBuildEnvironmentProvider? = nil, config: Configuration, hexavilleApplicationPath: String, executableTarget: String) throws -> BuildResult {
        let provider = DockerBuildEnvironmentProvider()
        return try provider.build(
            config: config,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executableTarget: executableTarget
        )
    }
}
