//
//  EmitterTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/29/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
import Yams

class EmitterTests: XCTestCase {

    func testScalar() throws {
        var node: Node = "key"

        let expectedAnyAndPlain = "key\n"
        node.scalar?.style = .any
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyAndPlain)
        node.scalar?.style = .plain
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyAndPlain)
        node.scalar?.style = .singleQuoted
        XCTAssertEqual(try Yams.serialize(node: node), "'key'\n")

        node.scalar?.style = .doubleQuoted
        XCTAssertEqual(try Yams.serialize(node: node), "\"key\"\n")
        node.scalar?.style = .literal
        XCTAssertEqual(try Yams.serialize(node: node), "|-\n  key\n")
        node.scalar?.style = .folded
        XCTAssertEqual(try Yams.serialize(node: node), ">-\n  key\n")
    }

    func testSequence() throws {
        var node: Node = ["a", "b", "c"]

        let expectedAnyIsBlock = """
            - a
            - b
            - c

            """
        node.sequence?.style = .any
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyIsBlock)
        node.sequence?.style = .block
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyIsBlock)

        node.sequence?.style = .flow
        XCTAssertEqual(try Yams.serialize(node: node), "[a, b, c]\n")
    }

    func testMapping() throws {
        var node: Node = ["key1": "value1", "key2": "value2"]

        let expectedAnyIsBlock = """
            key1: value1
            key2: value2

            """
        node.mapping?.style = .any
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyIsBlock)
        node.mapping?.style = .block
        XCTAssertEqual(try Yams.serialize(node: node), expectedAnyIsBlock)

        node.mapping?.style = .flow
        XCTAssertEqual(try Yams.serialize(node: node), "{key1: value1, key2: value2}\n")
    }

    func testLineBreaks() throws {
        let node: Node = "key"
        let expected = [
            "key",
            ""
        ]
        XCTAssertEqual(try Yams.serialize(node: node, lineBreak: .ln),
                       expected.joined(separator: "\n"))
        XCTAssertEqual(try Yams.serialize(node: node, lineBreak: .cr),
                       expected.joined(separator: "\r"))
        XCTAssertEqual(try Yams.serialize(node: node, lineBreak: .crln),
                       expected.joined(separator: "\r\n"))
    }

    func testAllowUnicode() throws {
        do {
            let node: Node = "あ"
            do {
                let yaml = try Yams.serialize(node: node)
                let expected = "\"\\u3042\"\n"
                XCTAssertEqual(yaml, expected)
            }
            do {
                let yaml = try Yams.serialize(node: node, allowUnicode: true)
                let expected = "あ\n"
                XCTAssertEqual(yaml, expected)
            }
        }
        do {
            // Emoji will be escaped whether `allowUnicode` is true or not
            let node: Node = "😀"
            do {
                let yaml = try Yams.serialize(node: node)
                let expected = "\"\\U0001F600\"\n"
                XCTAssertEqual(yaml, expected)
            }
            do {
                let yaml = try Yams.serialize(node: node, allowUnicode: true)
                let expected = "\"\\U0001F600\"\n"
                XCTAssertEqual(yaml, expected)
            }
        }
    }

    func testSortKeys() throws {
        let node: Node = [
            "key3": "value3",
            "key2": "value2",
            "key1": "value1"
        ]
        let yaml = try Yams.serialize(node: node)
        let expected = "key3: value3\nkey2: value2\nkey1: value1\n"
        XCTAssertEqual(yaml, expected)
        let yamlSorted = try Yams.serialize(node: node, sortKeys: true)
        let expectedSorted = "key1: value1\nkey2: value2\nkey3: value3\n"
        XCTAssertEqual(yamlSorted, expectedSorted)
    }
}

extension EmitterTests {
    static var allTests: [(String, (EmitterTests) -> () throws -> Void)] {
        return [
            ("testScalar", testScalar),
            ("testSequence", testSequence),
            ("testMapping", testMapping),
            ("testLineBreaks", testLineBreaks),
            ("testAllowUnicode", testAllowUnicode),
            ("testSortKeys", testSortKeys)
        ]
    }
}
