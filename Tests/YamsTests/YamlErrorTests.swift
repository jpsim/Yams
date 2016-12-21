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
        let yaml = "test: 'test\u{12}'"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "test: 'test\u{12}'",
                "           ^ control characters are not allowed"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        } catch {
            XCTFail("should not happen")
        }
    }

    func testYamlErrorScanner() throws {
        let yaml = "test: 'test"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "test: 'test",
                "           ^ found unexpected end of stream while scanning a quoted scalar"
                ].joined(separator: "\n")
            XCTAssertEqual(error.describing(with: yaml), expected)
        } catch {
            XCTFail("should not happen")
        }
    }

    func testYamlErrorParser() throws {
        let yaml = "[key1: value1, key2: ,"
        do {
            _ = try Parser(yaml: yaml).nextRoot()
            XCTFail("should not happen")
        } catch let error as YamlError {
            let expected = [
                "[key1: value1, key2: ,",
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
            ("testYamlErrorReader", testYamlErrorReader),
            ("testYamlErrorScanner", testYamlErrorScanner),
            ("testYamlErrorParser", testYamlErrorParser)
        ]
    }
}
