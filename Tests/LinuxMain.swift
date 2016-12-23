import XCTest

@testable import YamsTests

XCTMain([
    testCase(ConstructorTests.allTests),
    testCase(ParserTests.allTests),
    testCase(ResolverTests.allTests),
    testCase(StringTests.allTests),
    testCase(YamlErrorTests.allTests)
])
