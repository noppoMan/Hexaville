//
//  SwiftVersion.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/12/18.
//

import Foundation

public enum SwiftVersion {
    case release(Version)
    case developmentSnapshot(SwiftDevelopmentSnapshot)
}

extension SwiftVersion: Decodable {
    enum CodingKeys: CodingKey {
        case release
        case developmentSnapshot
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = try SwiftVersion(string: value)
    }
}

extension SwiftVersion {
    public init(string versionString: String) throws {
        if versionString.contains(SwiftDevelopmentSnapshot.snapshotIdentifer) {
            self = .developmentSnapshot(try SwiftDevelopmentSnapshot(string: versionString))
        } else {
            self = .release(try Version(string: versionString))
        }
    }
}

extension SwiftVersion {
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
        return "ubuntu16.04"
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
    
    public func asCompareableVersion() -> Version {
        switch self {
        case .developmentSnapshot(let snapshot):
            return Version(major: snapshot.major, minor: snapshot.minor, patch: snapshot.patch)
            
        case .release(let version):
            return version
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
        let dateString = String(components[1][components[1].startIndex..<endIndex])
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
