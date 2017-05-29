//
//  Proc.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation

public struct Proc {
    
    public let terminationStatus: Int32
    
    public let stdout: Any?
    
    public let stderr: Any?
    
    public init(_ exetutablePath: String, _ arguments: [String] = [], environment: [String: String] = ProcessInfo.processInfo.environment) {
        let process = Process()
        process.launchPath = exetutablePath
        process.arguments = arguments
        process.environment = environment
        process.launch()
        process.waitUntilExit()
        terminationStatus = process.terminationStatus
        stdout = process.standardOutput
        stderr = process.standardError
    }
}
