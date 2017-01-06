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
        let node: Node = "key"
        let yaml = try Yams.serialize(node: node)
        let expected = "'key'\n"
        XCTAssertEqual(yaml, expected)
    }

    func testSequence() throws {
        let node: Node = ["a", "b", "c"]
        let yaml = try Yams.serialize(node: node)
        let expected = [
            "- 'a'",
            "- 'b'",
            "- 'c'",
            ""
        ].joined(separator: "\n")
        XCTAssertEqual(yaml, expected)
    }

    func testMapping() throws {
        let node: Node = ["key1": "value1", "key2": "value2"]
        let yaml = try Yams.serialize(node: node)
        let expected = [
            "'key1': 'value1'",
            "'key2': 'value2'",
            ""
            ].joined(separator: "\n")
        XCTAssertEqual(yaml, expected)
    }

    func testLineBreaks() throws {
        let node: Node = "key"
        do {
            let yaml = try Yams.serialize(node: node, lineBreak: .ln)
            let expected = "'key'\n"
            XCTAssertEqual(yaml, expected)
        }
        do {
            let yaml = try Yams.serialize(node: node, lineBreak: .cr)
            let expected = "'key'\r"
            XCTAssertEqual(yaml, expected)
        }
        do {
            let yaml = try Yams.serialize(node: node, lineBreak: .crln)
            let expected = "'key'\r\n"
            XCTAssertEqual(yaml, expected)
        }
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
                let expected = "'あ'\n"
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
}

extension EmitterTests {
    static var allTests: [(String, (EmitterTests) -> () throws -> Void)] {
        return [
            ("testScalar", testScalar),
            ("testSequence", testSequence),
            ("testMapping", testMapping),
            ("testLineBreaks", testLineBreaks),
            ("testAllowUnicode", testAllowUnicode)
        ]
    }
}
