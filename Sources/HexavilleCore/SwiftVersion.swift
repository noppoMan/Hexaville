//
//  SwiftVersion.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/08/13.
//

import Foundation

public enum SwiftVersionContainer {
    case release(SwiftVersion)
    case developmentSnapshot(SwiftDevelopmentSnapshot)
}

extension SwiftVersionContainer {
    public init(string versionString: String) throws {
        if versionString.contains(substring: SwiftDevelopmentSnapshot.snapshotIdentifer) {
            self = .developmentSnapshot(try SwiftDevelopmentSnapshot(string: versionString))
        } else {
            self = .release(try SwiftVersion(string: versionString))
        }
    }
}

extension SwiftVersionContainer {
    public var versionString: String {
        switch self {
        case .developmentSnapshot(let snapshot):
            return snapshot.fullName
            
        case .release(let version):
            return version.versionString
        }
    }
    
    public var downloadBaseURLString: String {
        return "https://swift.org/builds"
    }
    
    public var osName: String {
        return "ubuntu14.04"
    }
    
    public var path: String {
        switch self {
        case .developmentSnapshot(let snapshot):
            return "swift-\(snapshot.versionString)-branch/\(osName.replacingOccurrences(of: ".", with: ""))/swift-\(snapshot.versionString)-DEVELOPMENT-SNAPSHOT-\(snapshot.dateString)-a"
            
        case .release(let version):
            return "swift-\(version.versionString)-release/\(osName.replacingOccurrences(of: ".", with: ""))/swift-\(version.versionString)-RELEASE"
        }
    }
    
    public var fileName: String {
        switch self {
        case .developmentSnapshot(let snapthot):
            return "\(snapthot.fullName)-\(osName)"
            
        case .release(let version):
            return "swift-\(version.versionString)-RELEASE-\(osName)"
        }
    }
    
    public var downloadURLString: String {
        return "\(downloadBaseURLString)/\(path)/\(fileName).tar.gz"
    }
    
    public func asCompareableVersion() -> SwiftVersion {
        switch self {
        case .developmentSnapshot(let snapshot):
            return SwiftVersion(major: snapshot.major, minor: snapshot.major, patch: snapshot.patch)
            
        case .release(let version):
            return version
        }
    }
}

public protocol SwiftVersionRepresentable: Hashable, Comparable {
    var major: Int { get }
    var minor: Int { get }
    var patch: Int { get }
}

extension SwiftVersionRepresentable {
    public static func < <Other: SwiftVersionRepresentable>(lhs: Self, rhs: Other) -> Bool {
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

extension SwiftVersionRepresentable {
    public var hashValue: Int {
        return (major << 8) | minor | patch
    }
    
    public static func == <Other: SwiftVersionRepresentable>(lhs: Self, rhs: Other) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func ~= <Other: SwiftVersionRepresentable>(match: Self, version: Other) -> Bool {
        return match == version
    }
}

enum SwiftVersionError: Error {
    case invalidVersion(String)
    case notEmpty
}

public struct SwiftVersion: SwiftVersionRepresentable {
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

public enum SwiftDevelopmentSnapshotError: Error {
    case invalidDevelopmentSnapshotName(String)
}

public struct SwiftDevelopmentSnapshot {
    public static let snapshotIdentifer = "DEVELOPMENT-SNAPSHOT"
    public let fullName: String
    public let date: Date
    public let major: Int
    public let minor: Int
    public let patch: Int
    
    public var versionString: String {
        return "\(major).\(minor)"
    }
    
    public var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self.date)
    }
    
    public init(string: String) throws {
        let components = string.components(separatedBy: "-"+SwiftDevelopmentSnapshot.snapshotIdentifer+"-")
        if components.count != 2 {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        
        let versionComponents = components[0].components(separatedBy: "-")
        if versionComponents.count != 2 {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        
        let versions = versionComponents[1].components(separatedBy: ".")
        if versions.count != 2 {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        
        guard let majorVersion = Int(versions[0]) else {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        
        guard let minorVersion = Int(versions[1]) else {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        
        self.major = majorVersion
        self.minor = minorVersion
        self.patch = 0
        
        self.fullName = string
        
        let endIndex = components[1].index(components[1].endIndex, offsetBy: -2)
        let dateString = components[1].substring(with: components[1].startIndex..<endIndex)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else {
            throw SwiftDevelopmentSnapshotError.invalidDevelopmentSnapshotName(string)
        }
        self.date = date
    }
}

extension SwiftDevelopmentSnapshot: Hashable {
    public var hashValue: Int {
        return (major << 8) | minor | patch | Int(date.timeIntervalSince1970)
    }
    
    public static func == (lhs: SwiftDevelopmentSnapshot, rhs: SwiftDevelopmentSnapshot) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.date == rhs.date
    }
    
    public static func ~= (match: SwiftDevelopmentSnapshot, version: SwiftDevelopmentSnapshot) -> Bool {
        return match == version
    }
}

extension SwiftDevelopmentSnapshot: Comparable {
    public static func < (lhs: SwiftDevelopmentSnapshot, rhs: SwiftDevelopmentSnapshot) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else {
            if lhs.minor < rhs.minor {
                return true
            }
            
            if lhs.patch < rhs.patch {
                return true
            }
            
            return lhs.date.timeIntervalSince1970 < rhs.date.timeIntervalSince1970
        }
    }
}
