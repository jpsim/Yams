//
//  RepresenterTests.swift
//  Yams
//
//  Created by Norio Nomura on 1/14/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import Foundation
import XCTest
@testable import Yams

class RepresenterTests: XCTestCase {
    func testBool() throws {
        XCTAssertEqual(try Node(true), "true")
        XCTAssertEqual(try Node(false), "false")
    }

    func testData() throws {
        let base64EncodedString = [
            "R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5",
            "OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+",
            "+f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC",
            "AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs="
            ].joined()
        let data = Data(base64Encoded: base64EncodedString, options: .ignoreUnknownCharacters)!
        XCTAssertEqual(try Node(data), Node(base64EncodedString, Tag(.binary)))
    }

    func testDate() throws {
        do {
            let date = timestamp( 0, 2001, 12, 15, 02, 59, 43)
            XCTAssertEqual(try Node(date), "2001-12-15T02:59:43Z")
        }
        do { // fractional seconds
            #if os(Linux)
                // FIXME: swift-corelibs-foundation can't format date with nanosecond.
                // https://bugs.swift.org/browse/SR-3158
            #else
                let date = timestamp( 0, 2001, 12, 15, 02, 59, 43, 0.1)
                XCTAssertEqual(try Node(date), "2001-12-15T02:59:43.1Z")
            #endif
        }
    }

    func testDouble() throws {
        XCTAssertEqual(try Node(Double.infinity), ".inf")
        XCTAssertEqual(try Node(-Double.infinity), "-.inf")
        XCTAssertEqual(try Node(Double.nan), ".nan")
        XCTAssertEqual(try Node(Double(6.8523015e+5)), "6.8523015e+5")
        XCTAssertEqual(try Node(Double(6.8523015e-5)), "6.8523015e-5")
    }

    func testFloat() throws {
        XCTAssertEqual(try Node(Float.infinity), ".inf")
        XCTAssertEqual(try Node(-Float.infinity), "-.inf")
        XCTAssertEqual(try Node(Float.nan), ".nan")
        XCTAssertEqual(try Node(Float(6.852301e+5)), "6.852301e+5")
        XCTAssertEqual(try Node(Float(6.852301e-5)), "6.852301e-5")
    }

    func testInteger() throws {
        #if arch(i386) || arch(arm)
            XCTAssertEqual(try Node(Int.max), "2147483647")
            XCTAssertEqual(try Node(Int.min), "-2147483648")
            XCTAssertEqual(try Node(UInt.max), "4294967295")
        #elseif arch(x86_64) || arch(arm64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
            XCTAssertEqual(try Node(Int.max), "9223372036854775807")
            XCTAssertEqual(try Node(Int.min), "-9223372036854775808")
            XCTAssertEqual(try Node(UInt.max), "18446744073709551615")
        #else
            XCTFail("Unknown architecture")
        #endif
        XCTAssertEqual(try Node(Int.allZeros), "0")
        XCTAssertEqual(try Node(UInt.allZeros), "0")

        XCTAssertEqual(try Node(Int16.max), "32767")
        XCTAssertEqual(try Node(Int16.allZeros), "0")
        XCTAssertEqual(try Node(Int16.min), "-32768")
        XCTAssertEqual(try Node(Int32.max), "2147483647")
        XCTAssertEqual(try Node(Int32.allZeros), "0")
        XCTAssertEqual(try Node(Int32.min), "-2147483648")
        XCTAssertEqual(try Node(Int64.max), "9223372036854775807")
        XCTAssertEqual(try Node(Int64.allZeros), "0")
        XCTAssertEqual(try Node(Int64.min), "-9223372036854775808")
        XCTAssertEqual(try Node(Int8.max), "127")
        XCTAssertEqual(try Node(Int8.allZeros), "0")
        XCTAssertEqual(try Node(Int8.min), "-128")

        XCTAssertEqual(try Node(UInt16.max), "65535")
        XCTAssertEqual(try Node(UInt16.allZeros), "0")
        XCTAssertEqual(try Node(UInt32.max), "4294967295")
        XCTAssertEqual(try Node(UInt32.allZeros), "0")
        XCTAssertEqual(try Node(UInt64.max), "18446744073709551615")
        XCTAssertEqual(try Node(UInt64.allZeros), "0")
        XCTAssertEqual(try Node(UInt8.max), "255")
        XCTAssertEqual(try Node(UInt8.allZeros), "0")
    }

    func testString() throws {
        XCTAssertEqual(Node("test"), "test")
    }

    func testOptional() throws {
        XCTAssertEqual(try Node(Int?.none), "null")
    }

    func testArray() throws {
        let ints = [1, 2, 3]
        XCTAssertEqual(try Node(ints), [1, 2, 3])
    }

    func testDictionary() throws {
        let stringToString = ["key": "value"]
        XCTAssertEqual(try Node(stringToString), ["key": "value"])

        let intToInt = [1: 2]
        XCTAssertEqual(try Node(intToInt), [1: 2])
    }
}

extension RepresenterTests {
    static var allTests: [(String, (RepresenterTests) -> () throws -> Void)] {
        return [
            ("testBool", testBool),
            ("testData", testData),
            ("testDate", testDate),
            ("testDouble", testDouble),
            ("testFloat", testFloat),
            ("testInteger", testInteger),
            ("testString", testString),
            ("testOptional", testOptional),
            ("testArray", testArray),
            ("testDictionary", testDictionary)
        ]
    }
}
