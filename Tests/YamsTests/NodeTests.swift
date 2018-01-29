//
//  NodeTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/25/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

class NodeTests: XCTestCase {

    func testExpressibleByArrayLiteral() {
        let sequence: Node = [
            Node("1"),
            Node("2"),
            Node("3")
        ]
        let expected: Node = Node([
            Node("1"),
            Node("2"),
            Node("3")
            ])
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByDictionaryLiteral() {
        let sequence: Node = [Node("key"): Node("value")]
        let expected: Node = Node([
            (Node("key"), Node("value"))
            ])
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByFloatLiteral() {
        let sequence: Node = 0.0
        let expected: Node = Node(String(0.0))
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByIntegerLiteral() {
        let sequence: Node = 0
        let expected: Node = Node(String(0))
        XCTAssertEqual(sequence, expected)
    }

    func testExpressibleByStringLiteral() {
        let sequence: Node = "string"
        let expected: Node = Node("string")
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

        let base64String = """
             R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\
             OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\
             +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\
             AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=
            """
        let scalarBinary: Node = Node(base64String)
        XCTAssertEqual(scalarBinary.binary, Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!)

        let scalarTimestamp: Node = "2001-12-15T02:59:43.1Z"
        XCTAssertEqual(scalarTimestamp.timestamp, timestamp( 0, 2001, 12, 15, 02, 59, 43, 0.1))
    }

    func testArray() {
        let base64String = """
             R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\
             OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\
             +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\
             AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=
            """
        let sequence: Node = [
            "true",
            "1.0",
            "1",
            Node(base64String)
        ]
        XCTAssertEqual(sequence.array(), ["true", "1.0", "1", Node(base64String)] as [Node])
        XCTAssertEqual(sequence.array(of: String.self), ["true", "1.0", "1", base64String])
        XCTAssertEqual(sequence.array() as [String], ["true", "1.0", "1", base64String])
        XCTAssertEqual(sequence.array(of: Bool.self), [true])
        XCTAssertEqual(sequence.array() as [Bool], [true])
        XCTAssertEqual(sequence.array(of: Double.self), [1.0, 1.0])
        XCTAssertEqual(sequence.array() as [Double], [1.0, 1.0])
        XCTAssertEqual(sequence.array(of: Int.self), [1])
        XCTAssertEqual(sequence.array() as [Int], [1])

        let expectedData = [
            Data(base64Encoded: "true", options: .ignoreUnknownCharacters)!,
            Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
        ]
        XCTAssertEqual(sequence.array(of: Data.self), expectedData)
        XCTAssertEqual(sequence.array() as [Data], expectedData)
    }

    func testSubscriptMapping() {
        let mapping: Node = ["key1": "value1", "key2": "value2", "key3": "value3"]
        XCTAssertEqual(mapping["key1" as Node]?.string, "value1") // Node resolvable as String
        XCTAssertEqual(mapping["key2"]?.string, "value2") // String Literal
        XCTAssertEqual(mapping[String("key3")]?.string, "value3") // String
    }

    func testSubscriptSequence() {
        let mapping: Node = ["value1", "value2", "value3"]
        XCTAssertEqual(mapping["0" as Node]?.string, "value1") // Node resolvable as Integer
        XCTAssertEqual(mapping[1]?.string, "value2")         // Integer Literal
        XCTAssertEqual(mapping[Int(2)]?.string, "value3")    // Int
    }

    func testSubscriptWithNonDefaultResolver() {
        let yaml = "200: value"
        XCTAssertEqual(try Yams.compose(yaml: yaml)?["200"]?.string, "value")
        XCTAssertEqual(try Yams.compose(yaml: yaml, .basic)?["200"]?.string, "value")
    }

    func testMappingBehavesLikeADictionary() {
        let node: Node = ["key1": "value1", "key2": "value2"]
        let mapping = node.mapping!
        XCTAssertEqual(mapping.count, 2)
        XCTAssertEqual(mapping.endIndex, 2)
        XCTAssertTrue(mapping.first! == ("key1", "value1"))
        XCTAssertFalse(mapping.isEmpty)
        XCTAssertEqual(Set(mapping.keys), ["key1", "key2"])
        XCTAssertEqual(mapping.lazy.count, 2)
        XCTAssertEqual(mapping.startIndex, 0)
        XCTAssertEqual(mapping.underestimatedCount, 2)
        XCTAssertEqual(Set(mapping.values), ["value1", "value2"])

        // subscript
        var mutableMapping = mapping
        mutableMapping["key3"] = "value3"
        XCTAssertEqual(mutableMapping["key3"], "value3")
        mutableMapping["key3"] = "value3changed"
        XCTAssertEqual(mutableMapping["key3"], "value3changed")
        mutableMapping["key3"] = nil
        XCTAssertNil(mutableMapping["key3"])

        // iterator
        var iterator = mapping.makeIterator()
        XCTAssertTrue(iterator.next()! == ("key1", "value1"))
        XCTAssertTrue(iterator.next()! == ("key2", "value2"))
        XCTAssertNil(iterator.next())

        // ExpressibleByDictionaryLiteral
        XCTAssertEqual(mapping, ["key1": "value1", "key2": "value2"])
    }

    func testSequenceBehavesLikeAnArray() {
        let node: Node = ["value1", "value2", "value3"]
        let sequence = node.sequence!
        XCTAssertEqual(sequence.count, 3)
        XCTAssertEqual(sequence.endIndex, 3)
        XCTAssertEqual(sequence.first, "value1")
        XCTAssertFalse(sequence.isEmpty)
        XCTAssertEqual(sequence.last, "value3")
        XCTAssertEqual(sequence.lazy.count, 3)
        XCTAssertEqual(sequence.startIndex, 0)
        XCTAssertEqual(sequence.underestimatedCount, 3)

        // subscript
        var mutableSequence = sequence
        mutableSequence.append("value4")
        XCTAssertEqual(mutableSequence.count, 4)
        XCTAssertEqual(mutableSequence[3], "value4")
        mutableSequence.remove(at: 2)
        XCTAssertEqual(mutableSequence.count, 3)
        XCTAssertEqual(Array(mutableSequence), ["value1", "value2", "value4"])

        // iterator
        var iterator = sequence.makeIterator()
        XCTAssertEqual(iterator.next(), "value1")
        XCTAssertEqual(iterator.next(), "value2")
        XCTAssertEqual(iterator.next(), "value3")
        XCTAssertNil(iterator.next())

        // ExpressibleByArrayLiteral
        XCTAssertEqual(sequence, ["value1", "value2", "value3"])
    }

    func testScalar() {
        var node = Node("1")
        XCTAssertEqual(node.tag, Tag(.int))
        node.scalar?.string = "test"
        XCTAssertEqual(node.tag, Tag(.str))
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
            ("testTypedAccessorProperties", testTypedAccessorProperties),
            ("testArray", testArray),
            ("testSubscriptMapping", testSubscriptMapping),
            ("testSubscriptSequence", testSubscriptSequence),
            ("testSubscriptWithNonDefaultResolver", testSubscriptWithNonDefaultResolver),
            ("testMappingBehavesLikeADictionary", testMappingBehavesLikeADictionary),
            ("testSequenceBehavesLikeAnArray", testSequenceBehavesLikeAnArray),
            ("testScalar", testScalar)
        ]
    }
}
