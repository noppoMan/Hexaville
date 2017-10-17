import XCTest
@testable import HexavilleTests

XCTMain([
    testCase(HexavilefileLoaderTest.allTests),
    testCase(DotEnvParserTests.allTests),
    testCase(SwiftVersionTests.allTests),
    testCase(EventEmitterTests.allTests)
])
