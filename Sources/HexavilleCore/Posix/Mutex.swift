//
//  Mutex.swift
//  APIGateway
//
//  Created by Yuki Takei on 2018/11/27.
//

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import Foundation

class Mutex {
    fileprivate var mutex: pthread_mutex_t
    
    public init(){
        mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
    }
    
    public func lock(){
        pthread_mutex_lock(&mutex)
    }
    
    public func unlock(){
        pthread_mutex_unlock(&mutex)
    }
    
    deinit{
        pthread_mutex_destroy(&mutex)
    }
}

