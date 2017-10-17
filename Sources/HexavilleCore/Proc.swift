//
//  Proc.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation

extension Process {
    public static func exec(_ cmd: String, _ args: [String], environment: [String: String] = ProcessInfo.processInfo.environment) -> Proc {
        var args = args
        args.insert(cmd, at: 0)
        return Proc.init("/usr/bin/env", args, environment: environment)
    }
}

public struct Proc {
    
    public let terminationStatus: Int32
    
    public let stdout: Any?
    
    public let stderr: Any?
    
    public let pid: Int32?
    
    public init(_ exetutablePath: String, _ arguments: [String] = [], environment: [String: String] = ProcessInfo.processInfo.environment) {
        let process = Process()
        process.launchPath = exetutablePath
        process.arguments = arguments
        process.environment = environment
        process.launch()
        
        // handle SIGINT
        SignalEventEmitter.shared.once { sig in
            assert(sig == .int)
            process.interrupt()
        }
        
        process.waitUntilExit()
        terminationStatus = process.terminationStatus
        stdout = process.standardOutput
        stderr = process.standardError
        pid = process.processIdentifier
    }
}
