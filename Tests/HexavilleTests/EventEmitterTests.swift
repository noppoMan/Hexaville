//
//  EventEmitterTests.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/10/17.
//

import Foundation

import XCTest
@testable import HexavilleCore

class EventEmitterTests: XCTestCase {
    
    func testOn() {
        let exp = expectation(description: "testOnce")
        
        let evm = EventEmitter<Int>()
        
        evm.on {
            XCTAssertEqual($0 + 1, 2)
            exp.fulfill()
        }
        
        evm.emit(with: 1)
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(evm.onListenersCount, 1)
    }
    
    func testOnce() {
        let exp = expectation(description: "testOnce")
        
        let evm = EventEmitter<Int>()
        
        evm.once {
            XCTAssertEqual($0 + 1, 2)
            exp.fulfill()
        }
        
        evm.emit(with: 1)
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(evm.onceListenersCount, 0)
    }
    
    static var allTests = [
        ("testOn", testOn),
        ("testOnce", testOnce),
    ]
}

