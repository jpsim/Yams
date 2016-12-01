//
//  YamsTests.swift
//  Yams
//
//  Created by JP Simard on 2016-11-19.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

class YamsTests: XCTestCase {
    func testExample() throws {
        let node = try Node(string: "- 1: test")
        if case let .sequence(seq) = node {
            XCTAssert(seq.count > 0)
            if case let .mapping(map) = seq[0] {
                XCTAssertEqual(map.count, 1)
                XCTAssertEqual(map[0].0, "1")
                if case let .scalar(string) = map[0].1 {
                    XCTAssertEqual(string, "test")
                } else {
                    XCTFail("first map value is not a string")
                }
            } else {
                XCTFail("first seq is not a mapping")
            }
        } else {
            XCTFail("node is not a sequence")
        }
    }
}

extension YamsTests {
    static var allTests: [(String, (YamsTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
