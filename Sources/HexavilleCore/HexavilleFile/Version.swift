//
//  Version.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/08/13.
//

import Foundation

public protocol VersionRepresentable: Hashable, Comparable {
    var major: Int { get }
    var minor: Int { get }
    var patch: Int { get }
}

extension VersionRepresentable {
    public static func < <Other: VersionRepresentable>(lhs: Self, rhs: Other) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else {
            if lhs.minor < rhs.minor {
                return true
            }
            return lhs.patch < rhs.patch
        }
    }
}

extension VersionRepresentable {
    public var hashValue: Int {
        return (major << 8) | minor | patch
    }
    
    public static func == <Other: VersionRepresentable>(lhs: Self, rhs: Other) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func ~= <Other: VersionRepresentable>(match: Self, version: Other) -> Bool {
        return match == version
    }
}

enum VersionError: Error {
    case invalidVersion(String)
    case notEmpty
}

public struct Version: VersionRepresentable {
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

extension Version {
    public init(string: String) throws {
        let components = string.components(separatedBy: ".")
        if components.count == 0 {
            throw VersionError.notEmpty
        }
        
        let intCastedComponents: [Int] = try components.map({
            guard let int = Int($0) else {
                throw VersionError.invalidVersion(string)
            }
            return int
        })
        
        switch intCastedComponents.count {
        case 1:
            self = Version(major: intCastedComponents[0], minor: 0)
        case 2:
            self = Version(major: intCastedComponents[0], minor: intCastedComponents[1])
        case 3:
            self = Version(major: intCastedComponents[0], minor: intCastedComponents[1], patch: intCastedComponents[2])
        default:
            throw VersionError.invalidVersion(string)
        }
    }
}
