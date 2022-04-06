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

    func testDecodeOptionalTypes() throws {
        let yaml = """
        AAA: ''
        BBB:
        CCC: null
        DDD: ~
        EEE: ""
        json: {
          "FFF": "",
          "GGG": "null"
        }
        array:
        - one
        - ''
        - null
        - 'null'
        - '~'
        """

        struct Container: Codable, Equatable {
            struct JSON: Codable, Equatable {
                var FFF: String?
                var GGG: String?
            }

            var AAA: String?
            var BBB: String?
            var CCC: Int?
            var DDD: String?
            var EEE: String?
            var json: JSON
            var array: [String?]
        }

        let container = try YAMLDecoder().decode(Container.self, from: yaml)

        XCTAssertEqual(container.AAA, "")
        XCTAssertEqual(container.BBB, nil)
        XCTAssertEqual(container.CCC, nil)
        XCTAssertEqual(container.DDD, nil)
        XCTAssertEqual(container.EEE, "")
        XCTAssertEqual(container.json.FFF, "")
        XCTAssertEqual(container.json.GGG, "null")
        XCTAssertEqual(container.array, ["one", "", nil, "null", "~"])
    }
}
#endif
