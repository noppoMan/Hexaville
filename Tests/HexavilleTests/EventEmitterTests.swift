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
        let expectation = XCTestExpectation(description: "testOnce")
        
        let evm = EventEmitter<Int>()
        
        evm.on {
            XCTAssertEqual($0 + 1, 2)
            expectation.fulfill()
        }
        
        evm.emit(with: 1)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(evm.onListenerCounts, 1)
    }
    
    func testOnce() {
        let expectation = XCTestExpectation(description: "testOnce")
        
        let evm = EventEmitter<Int>()
        
        evm.once {
            XCTAssertEqual($0 + 1, 2)
            expectation.fulfill()
        }
        
        evm.emit(with: 1)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(evm.onceListenerCounts, 0)
    }
    
    static var allTests = [
        ("testOn", testOn),
        ("testOnce", testOnce),
    ]
}

