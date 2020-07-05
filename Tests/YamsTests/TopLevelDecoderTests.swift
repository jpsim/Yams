//
//  TopLevelDecoderTests.swift
//  Yams
//
//  Created by JP Simard on 2020-07-05.
//  Copyright (c) 2020 Yams. All rights reserved.
//

#if canImport(Combine)
import Combine
import XCTest
import Yams

class TopLevelDecoderTests: XCTestCase {
    func testDecodeFromYAMLDecoder() throws {
        let yaml = """
            name: Bird
            """
        let data = try XCTUnwrap(yaml.data(using: .utf8))

        struct Foo: Decodable {
            var name: String
        }

        var foo: Foo?
        _ = Just(data)
            .decode(type: Foo.self, decoder: YAMLDecoder())
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { foo = $0 }
            )
        XCTAssertEqual(foo?.name, "Bird")
    }
}

extension TopLevelDecoderTests {
    static var allTests: [(String, (TopLevelDecoderTests) -> () throws -> Void)] {
        return [
            ("testDecodeFromYAMLDecoder", testDecodeFromYAMLDecoder)
        ]
    }
}
#endif
