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
@testable import Yams

@available(iOS 13.0, macOS 10.15.0, tvOS 13.0, watchOS 6.0, *)
class TopLevelDecoderTests: XCTestCase {
    func testDecodeFromYAMLDecoder() throws {
        let yaml = """
            name: Bird
            """
        let data = try XCTUnwrap(yaml.data(using: Parser.Encoding.default.swiftStringEncoding))

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
#endif
