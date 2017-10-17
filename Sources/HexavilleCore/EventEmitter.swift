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
    
    public var onceListenersCount: Int {
        return onceListeners.count
    }
    
    public var onListenersCount: Int {
        return onListeners.count
    }
    
    private var onceListeners: [(T) -> Void] = []
    
    private var onListeners: [(T) -> Void] = []
    
    public init() {}
    
    public func emit(with value: T) {
        defer {
            mutex.lock()
            onceListeners.removeAll()
            mutex.unlock()
        }
        
        for handle in onceListeners {
            handle(value)
        }
        
        for handle in onListeners {
            handle(value)
        }
    }
    
    public func once(handler: @escaping (T) -> Void) {
        defer {
            mutex.unlock()
        }
        mutex.lock()
        onceListeners.append(handler)
    }
    
    public func on(handler: @escaping (T) -> Void) {
        defer {
            mutex.unlock()
        }
        mutex.lock()
        onListeners.append(handler)
    }
}
