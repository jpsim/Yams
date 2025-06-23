//
//  NodeTests.swift
//  Yams
//
//  Created by Adora Lynch on 6/23/25.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import Foundation
import XCTest
@testable import Yams

final class NodeInternalHelpersTests: XCTestCase, @unchecked Sendable {
    // swiftlint:disable force_try
    func testIsScalar() {
        var node = Node("1") // a scalar
        XCTAssertEqual(node.isScalar, true)
        node = try! Node(["key": "1"]) // a mapping
        XCTAssertEqual(node.isScalar, false)
        node = try! Node(["one", "1"]) // a sequnce
        XCTAssertEqual(node.isScalar, false)
    }
    // swiftlint:enable force_try
}

extension NodeInternalHelpersTests {
    static var allTests: [(String, (NodeInternalHelpersTests) -> () throws -> Void)] {
        return [
            ("testIsScalar", testIsScalar)
        ]
    }
}
