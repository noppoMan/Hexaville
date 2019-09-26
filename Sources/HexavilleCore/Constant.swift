//
//  Constant.swift
//
//  Created by Yuki Takei on 2018/11/29.
//

public struct Constant {
    let binaryMediaTypes: [String] = [
        "image/*",
        "application/x-protobuf",
        "application/x-google-protobuf",
        "application/octet-stream"
    ]
    
    public static var supportedSwiftVersionsRange: CountableClosedRange<Int> {
        return 5...5
    }
    
    public static var defaultSwiftVersion: SwiftVersion {
        return .release(Version(major: 5, minor: 1))
    }
    
    public static let appPrefix = "hexaville"
}

