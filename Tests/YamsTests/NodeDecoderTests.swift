//
//  NodeDecoderTests.swift
//  
//
//  Created by Rob Napier on 6/3/23.
//

import XCTest
import Yams

final class NodeDecoderTests: XCTestCase {
    func testMultiLevelPartialDecode() throws {
        let yaml = """
        ---
        topLevel:
          secondLevel:
            desired:
              name: My Name
              age: 123
        """

        struct Desired: Decodable {
            var name: String
            var age: Int
        }

        let node = try Yams.compose(yaml: yaml)!

        let desiredNode = try XCTUnwrap(node["topLevel"]?["secondLevel"]?["desired"])

        let desired = try YAMLDecoder().decode(Desired.self, from: desiredNode)

        XCTAssertEqual(desired.name, "My Name")
        XCTAssertEqual(desired.age, 123)
    }

    func testDecodeBools() throws {
        let yaml = """
        ---
        topLevel:
          unquotedBool: true
          explicitBool: !!bool true
          explicitStringNotBool: !!str true
          singleQuotedStringNotBool: 'true'
          doubleQuotedStringNotBool: "true"
        """

        struct TopLevel: Decodable {
            var unquotedBool: BoolOrString
            var explicitBool: BoolOrString
            var explicitStringNotBool: BoolOrString
            var singleQuotedStringNotBool: BoolOrString
            var doubleQuotedStringNotBool: BoolOrString
        }

        let node = try Yams.compose(yaml: yaml)!

        let desiredNode = try XCTUnwrap(node["topLevel"])

        let desired = try YAMLDecoder().decode(TopLevel.self, from: desiredNode)

        XCTAssertEqual(desired.unquotedBool, true)
        XCTAssertEqual(desired.explicitBool, true)
        XCTAssertEqual(desired.explicitStringNotBool, "true")
        XCTAssertEqual(desired.singleQuotedStringNotBool, "true")
        XCTAssertEqual(desired.doubleQuotedStringNotBool, "true")
    }
}

enum BoolOrString: Equatable {
    case bool(Bool)
    case string(String)
}

extension BoolOrString: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else {
            self = .string(try container.decode(String.self))
        }
    }
}

extension BoolOrString: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension BoolOrString: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}
