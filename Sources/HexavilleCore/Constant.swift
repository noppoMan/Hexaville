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
        return 3...4
    }
    
    public static var defaultSwiftVersion: SwiftVersion {
        return .release(Version(major: 4, minor: 2))
    }
    
    public static let appPrefix = "hexaville"
    
    public static let runtimeVersion = "rv1"
}

