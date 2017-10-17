//
//  EventEmitter.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/10/17.
//

import Foundation
import Prorsum

/**
 Thread safety EventEmitter
 */
public class EventEmitter<T> {
    
    private var mutex = Mutex()
    
    private var onceHandlers: [(T) -> Void] = []
    
    private var handlers: [(T) -> Void] = []
    
    public init() {}
    
    public func emit(with value: T) {
        defer {
            mutex.lock()
            onceHandlers.removeAll()
            mutex.unlock()
        }
        
        for handle in onceHandlers {
            handle(value)
        }
        
        for handle in handlers {
            handle(value)
        }
    }
    
    public func once(handler: @escaping (T) -> Void) {
        defer {
            mutex.unlock()
        }
        mutex.lock()
        onceHandlers.append(handler)
    }
    
    public func on(handler: @escaping (T) -> Void) {
        defer {
            mutex.unlock()
        }
        mutex.lock()
        handlers.append(handler)
    }
}
