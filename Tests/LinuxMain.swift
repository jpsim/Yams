#if os(Linux)
import XCTest

#if BAZEL
#else
@testable import YamsTests
#endif

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
