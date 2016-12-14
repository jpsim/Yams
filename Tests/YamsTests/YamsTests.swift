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

    func testYamsErrorReader() throws {
        // reader
        let yaml = "test: 'test\u{12}'"
        do {
            _ = try Node(string: yaml)
        } catch let error as YamsError {
            let expected = [
                "test: 'test\u{12}'",
                "           ^ control characters are not allowed"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        }
    }

    func testYamsErrorScanner() throws {
        let yaml = "test: 'test"
        do {
            _ = try Node(string: yaml)
        } catch let error as YamsError {
            let expected = [
                "test: 'test",
                "           ^ found unexpected end of stream while scanning a quoted scalar"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        }
    }
    
    func testYamsErrorParser() throws {
        let yaml = "[key1: value1, key2: ,"
        do {
            _ = try Node(string: yaml)
        } catch let error as YamsError {
            let expected = [
                "[key1: value1, key2: ,",
                "^ did not find expected node content while parsing a flow node"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        }
    }
}

extension YamsTests {
    static var allTests: [(String, (YamsTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
            ("testYamsErrorReader", testYamsErrorReader),
            ("testYamsErrorScanner", testYamsErrorScanner),
            ("testYamsErrorParser", testYamsErrorParser),
        ]
    }
}
