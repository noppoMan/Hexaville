//
//  SignalHandler.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/10/17.
//
#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import Foundation
import Dispatch

public class SignalEventEmitter: EventEmitter<SignalHandler.Signal> {
    public static let shared = SignalEventEmitter()
}

public class SignalHandler {
    
    public enum Signal: Int32 {
        case hup    = 1
        case int    = 2
        case quit   = 3
        case abrt   = 6
        case kill   = 9
        case alrm   = 14
        case term   = 15
    }
    
    public static let shared = SignalHandler()
    
    private var handlers: [() -> Void] = []
    
    private init() {}
    
    public func trap(with signal: Signal, handler: @escaping () -> Void) {
        handlers.append(handler)
        
        let action: @convention(c) (Int32) -> () = { sig in
            for handle in SignalHandler.shared.handlers {
                handle()
            }
        }
        
        #if os(macOS)
            var signalAction = sigaction(
                __sigaction_u: unsafeBitCast(action, to: __sigaction_u.self),
                sa_mask: 0,
                sa_flags: 0
            )
            
            _ = withUnsafePointer(to: &signalAction) { actionPointer in
                sigaction(signal.rawValue, actionPointer, nil)
            }
            
        #elseif os(Linux)
            var sigAction = sigaction()
            sigAction.__sigaction_handler = unsafeBitCast(
                action,
                to: sigaction.__Unnamed_union___sigaction_handler.self
            )
            _ = sigaction(signal.rawValue, &sigAction, nil)
        #endif
    }
    
    public func raise(_ signal: Signal) {
        #if os(macOS)
            _ = Darwin.raise(signal.rawValue)
        #elseif os(Linux)
            _ = Glibc.raise(signal.rawValue)
        #endif
    }
}
