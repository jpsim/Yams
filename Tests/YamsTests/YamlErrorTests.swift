//
//  YamlErrorTests.swift
//  Yams
//
//  Created by JP Simard on 2016-11-19.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

class YamlErrorTests: XCTestCase {
    func testYamlErrorReader() throws {
        // reader
        let yaml = "test: 'テスト\u{12}'"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "test: 'テスト\u{12}'",
                "          ^ control characters are not allowed"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        } catch {
            XCTFail("should not happen")
        }
    }

    func testYamlErrorScanner() throws {
        let yaml = "test: 'テスト"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "test: 'テスト",
                "          ^ found unexpected end of stream while scanning a quoted scalar"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        } catch {
            XCTFail("should not happen")
        }
    }

    func testYamlErrorParser() throws {
        let yaml = "- [キー1: 値1]\n- [key1: value1, key2: ,"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "- [key1: value1, key2: ,",
                "^ did not find expected node content while parsing a flow node"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        } catch {
            XCTFail("should not happen")
        }
    }
}

extension YamlErrorTests {
    static var allTests: [(String, (YamlErrorTests) -> () throws -> Void)] {
        return [
            /* FIXME: https://bugs.swift.org/browse/SR-3366
            ("testYamlErrorReader", testYamlErrorReader),
            ("testYamlErrorScanner", testYamlErrorScanner),
            ("testYamlErrorParser", testYamlErrorParser)
             */
        ]
    }
}
