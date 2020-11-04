import XCTest

@testable import YamsTests

// This file is compiled but does not appear to be actually used on Windows.
#if os(Linux)

XCTMain([
    testCase(ConstructorTests.allTests),
    testCase(EmitterTests.allTests),
    testCase(EncoderTests.allTests),
    testCase(MarkTests.allTests),
    testCase(NodeTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(RepresenterTests.allTests),
    testCase(ResolverTests.allTests),
    testCase(SpecTests.allTests),
    testCase(StringTests.allTests),
    testCase(YamlErrorTests.allTests)
])

#endif
