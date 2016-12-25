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

    func testExpressibleByStringLiteral() {
        let sequence: Node = "string"
        let expected: Node = .scalar("string", .implicit)
        XCTAssertEqual(sequence, expected)
    }
}

extension NodeTests {
    static var allTests: [(String, (NodeTests) -> () throws -> Void)] {
        return [
            ("testExpressibleByArrayLiteral", testExpressibleByArrayLiteral),
            ("testExpressibleByDictionaryLiteral", testExpressibleByDictionaryLiteral),
            ("testExpressibleByFloatLiteral", testExpressibleByFloatLiteral),
            ("testExpressibleByStringLiteral", testExpressibleByStringLiteral)
        ]
    }
}
