//
//  ParserTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
import Yams

class ParserTests: XCTestCase {
    func testExample() throws {
        let node = try Parser(yaml: "- 1: test").nextRoot()!
        if let seq = node.array {
            XCTAssert(seq.count > 0)
            if let map = seq[0].dictionary {
                XCTAssertEqual(map.count, 1)
                XCTAssertEqual(map.keys.first, "1")
                if let string = map["1"] {
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

extension ParserTests {
    static var allTests: [(String, (ParserTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
