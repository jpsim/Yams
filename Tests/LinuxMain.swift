import XCTest

@testable import YamsTests

XCTMain([
    testCase(StringTests.allTests),
    testCase(YamsTests.allTests),
])
