import XCTest

@testable import YamsTests

var testCases = [
    testCase(ConstructorTests.allTests),
    testCase(EmitterTests.allTests),
    testCase(MarkTests.allTests),
    testCase(NodeTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(RepresenterTests.allTests),
    testCase(ResolverTests.allTests),
    testCase(SpecTests.allTests),
    testCase(StringTests.allTests),
    testCase(YamlErrorTests.allTests)
]

#if swift(>=4.0)
    testCases.append(testCase(EncoderTests.allTests))
#endif

XCTMain(testCases)
