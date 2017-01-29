import XCTest

@testable import YamsTests

XCTMain([
    testCase(ConstructorTests.allTests),
    testCase(EmitterTests.allTests),
    testCase(NodeTests.allTests),
    testCase(ParserTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(RepresenterTests.allTests),
    testCase(ResolverTests.allTests),
    testCase(StringTests.allTests),
    testCase(YamlErrorTests.allTests)
])
