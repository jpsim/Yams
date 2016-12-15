import XCTest

@testable import YamsTests

XCTMain([
    testCase(ParserTests.allTests),
    testCase(ResolverTests.allTests),
    testCase(StringTests.allTests),
    testCase(YamlErrorTests.allTests),
])
