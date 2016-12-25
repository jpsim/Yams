//
//  NodeTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/25/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
@testable import Yams

class NodeTests: XCTestCase {

    func testExpressibleByArrayLiteral() {
        let sequence: Node = [.scalar("1", .implicit), .scalar("2", .implicit), .scalar("3", .implicit)]
        let expected: Node = .sequence([
            .scalar("1", .implicit),
            .scalar("2", .implicit),
            .scalar("3", .implicit)
            ], .implicit)
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByDictionaryLiteral() {
        let sequence: Node = [.scalar("key", .implicit): .scalar("value", .implicit)]
        let expected: Node = .mapping([
            Pair(.scalar("key", .implicit), .scalar("value", .implicit))
            ], .implicit)
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByFloatLiteral() {
        let sequence: Node = 0.0
        let expected: Node = .scalar(String(0.0), .implicit)
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByIntegerLiteral() {
        let sequence: Node = 0
        let expected: Node = .scalar(String(0), .implicit)
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByStringLiteral() {
        let sequence: Node = "string"
        let expected: Node = .scalar("string", .implicit)
        XCTAssertEqual(sequence, expected)
    }

    func testTypedAccessorProperties() {
        let scalarBool: Node = "true"
        XCTAssertEqual(scalarBool.bool, true)

        let scalarFloat: Node = "1.0"
        XCTAssertEqual(scalarFloat.float, 1.0)

        let scalarNull: Node = "null"
        XCTAssertEqual(scalarNull.null, NSNull())

        let scalarInt: Node = "1"
        XCTAssertEqual(scalarInt.int, 1)

        let base64String = [
            " R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5",
            " OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+",
            " +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC",
            " AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs="
            ].joined()
        let scalarBinary: Node = .scalar(base64String, .implicit)
        XCTAssertEqual(scalarBinary.binary, Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!)

        let scalarTimestamp: Node = "2001-12-15T02:59:43.1Z"
        XCTAssertEqual(scalarTimestamp.timestamp, timestamp( 0, 2001, 12, 15, 02, 59, 43, 0.1))
    }

    func testSubscriptMapping() {
        let mapping: Node = ["key1": "value1", "key2": "value2"]
        let valueForKey1 = mapping["key1"]?.string
        XCTAssertEqual(valueForKey1, "value1")
    }

    func testSubscriptSequence() {
        let mapping: Node = ["value1", "value2", "value3"]
        let valueAtSecond = mapping[1]?.string
        XCTAssertEqual(valueAtSecond, "value2")
    }
}

extension NodeTests {
    static var allTests: [(String, (NodeTests) -> () throws -> Void)] {
        return [
            ("testExpressibleByArrayLiteral", testExpressibleByArrayLiteral),
            ("testExpressibleByDictionaryLiteral", testExpressibleByDictionaryLiteral),
            ("testExpressibleByFloatLiteral", testExpressibleByFloatLiteral),
            ("testExpressibleByIntegerLiteral", testExpressibleByIntegerLiteral),
            ("testExpressibleByStringLiteral", testExpressibleByStringLiteral),
            ("testSubscriptMapping", testSubscriptMapping),
            ("testSubscriptSequence", testSubscriptSequence)
        ]
    }
}
