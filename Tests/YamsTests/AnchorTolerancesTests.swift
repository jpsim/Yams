//
//  AnchorTolerancesTests.swift
//  Yams
//
//  Created by Adora Lynch on 9/18/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import XCTest
import Yams

class AnchorTolerancesTests: XCTestCase {

    struct Example: Codable, Hashable {
        var myCustomAnchorDeclaration: Anchor
        var extraneousValue: Int
    }

    /// Any type that is Encodable and contains an `Anchor`value but with a coding key different from
    /// YamlAnchorProviding will not encode to a yaml anchor
    /// This may be unexpected
    func testAnchorEncoding_undeclaredBehavior() throws {
        let expectedYAML = """
                           myCustomAnchorDeclaration: I-did-it-myyyyy-way
                           extraneousValue: 3

                           """

        let value = Example(myCustomAnchorDeclaration: "I-did-it-myyyyy-way",
                            extraneousValue: 3)

        let encoder = YAMLEncoder()
        let producedYAML = try encoder.encode(value)
        XCTAssertEqual(producedYAML, expectedYAML, "Produced YAML not identical to expected YAML.")
    }

    /// Any type that is Encodable and contains an `Anchor`value with the same coding key as
    /// YamlAnchorProviding will encode to a yaml anchor even though the type does not conform to
    /// YamlAnchorProviding
    /// This may be unexpected
    func testAnchorEncoding_undeclaredBehavior_7() throws {
        struct Example: Codable, Hashable {
            var yamlAnchor: Anchor
            var extraneousValue: Int
        }

        let expectedYAML = """
                           &I-did-it-myyyyy-way
                           extraneousValue: 3

                           """

        let value = Example(yamlAnchor: "I-did-it-myyyyy-way",
                            extraneousValue: 3)

        let encoder = YAMLEncoder()
        let producedYAML = try encoder.encode(value)
        XCTAssertEqual(producedYAML, expectedYAML, "Produced YAML not identical to expected YAML.")
    }

    /// Any type that is Decodable and contains an `Anchor` value but with a coding key different from
    /// YamlAnchorProviding will not decode an anchor from the text representation.
    /// In this case a key not found error will be thrown during decoding
    /// This may be unexpected
    func testAnchorDecoding_undeclaredBehavior_1() throws {
        let sourceYAML = """
                           &a-different-tag
                           extraneousValue: 3
                           """
        let decoder = YAMLDecoder()
        XCTAssertThrowsError(try decoder.decode(Example.self, from: sourceYAML))
        // error is ^^ key not found, "myCustomAnchorDeclaration"
    }

    /// Any type that is Decodable and contains an `Anchor` value but with a coding key different from
    /// YamlAnchorProviding will not decode an anchor from the text representation.
    /// In this case the decoding is successful and the anchor is respected by the parser.
    /// This may be unexpected
    func testAnchorDecoding_undeclaredBehavior_6() throws {
        struct Example: Codable, Hashable {
            var myCustomAnchorDeclaration: Anchor?
            var extraneousValue: Int
        }
        let sourceYAML = """
                           &a-different-tag
                           extraneousValue: 3

                           """

        let expectedValue = Example(myCustomAnchorDeclaration: nil,
                                    extraneousValue: 3)

        let decoder = YAMLDecoder()
        let decodedValue = try decoder.decode(Example.self, from: sourceYAML)
        XCTAssertEqual(decodedValue, expectedValue, "\(Example.self) did not round-trip to an equal value.")
    }

    /// Any type that is Decodable and contains an `Anchor` value with the same coding key as
    /// YamlAnchorProviding will decode an anchor from the text representation even though the type does
    /// not conform to YamlAnchorCoding
    /// This may be unexpected
    func testAnchorDecoding_undeclaredBehavior_8() throws {
        struct Example: Codable, Hashable {
            var yamlAnchor: Anchor?
            var extraneousValue: Int
        }
        let sourceYAML = """
                           &a-different-tag
                           extraneousValue: 3

                           """

        let expectedValue = Example(yamlAnchor: "a-different-tag",
                                    extraneousValue: 3)

        let decoder = YAMLDecoder()
        let decodedValue = try decoder.decode(Example.self, from: sourceYAML)
        XCTAssertEqual(decodedValue, expectedValue, "\(Example.self) did not round-trip to an equal value.")
    }

    /// Any type that is Decodable and contains an `Anchor` value but with a coding key different from
    /// YamlAnchorProviding will not decode an anchor from the text representation.
    /// In this case the decoding is successful and the anchor is respected by the parser.
    /// This is expected behavior, but in a strange situation.
    func testAnchorDecoding_undeclaredBehavior_3() throws {
        let sourceYAML = """
                           &a-different-tag
                           extraneousValue: 3
                           myCustomAnchorDeclaration: deliver-us-from-evil

                           """
        let expectedValue = Example(myCustomAnchorDeclaration: "deliver-us-from-evil",
                                    extraneousValue: 3)

        let decoder = YAMLDecoder()
        let decodedValue = try decoder.decode(Example.self, from: sourceYAML)
        XCTAssertEqual(decodedValue, expectedValue, "\(Example.self) did not round-trip to an equal value.")

    }

    /// Any type that is Decodable and contains an `Anchor` value but with a coding key different from
    /// YamlAnchorProviding will not decode an anchor from the text representation.
    /// In this case the decoding is successful even though and the `Anchor` was initialized with
    /// unsupported characters. The anchor is respected by the parser.
    /// This is expected behavior, but in a strange situation.
    func testAnchorDecoding_undeclaredBehavior_2() throws {
        let sourceYAML = """
                           &a-different-tag
                           extraneousValue: 3
                           myCustomAnchorDeclaration: "deliver us from |()evil"

                           """

        let expectedValue = Example(myCustomAnchorDeclaration: "deliver us from |()evil",
                                    extraneousValue: 3)

        let decoder = YAMLDecoder()
        let decodedValue = try decoder.decode(Example.self, from: sourceYAML)
        XCTAssertEqual(decodedValue, expectedValue, "\(Example.self) did not round-trip to an equal value.")

    }

}
