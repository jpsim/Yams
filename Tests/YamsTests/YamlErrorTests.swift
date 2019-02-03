//
//  YamlErrorTests.swift
//  Yams
//
//  Created by JP Simard on 2016-11-19.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
import Yams

class YamlErrorTests: XCTestCase {
    func testYamlErrorEmitter() throws {
        XCTAssertThrowsError(try Yams.serialize(node: "test", version: (1, 2))) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", "incompatible %YAML directive")
        }
    }

    func testYamlErrorReader() throws {
        // reader
        let yaml = "test: 'テスト\u{12}'"
        XCTAssertThrowsError(_ = try Parser(yaml: yaml).nextRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                1:11: error: reader: control characters are not allowed:
                test: 'テスト\u{12}'
                          ^
                """
            )
        }
    }

    func testYamlErrorScanner() throws {
        let yaml = "test: 'テスト"
        XCTAssertThrowsError(_ = try Parser(yaml: yaml).nextRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                1:11: error: scanner: while scanning a quoted scalar in line 1, column 7
                found unexpected end of stream:
                test: 'テスト
                          ^
                """
            )
        }
    }

    func testYamlErrorParser() throws {
        let yaml = "- [キー1: 値1]\n- [key1: value1, key2: ,"
        XCTAssertThrowsError(_ = try Parser(yaml: yaml).nextRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                3:1: error: parser: while parsing a flow node in line 3, column 1
                did not find expected node content:
                - [key1: value1, key2: ,
                ^
                """
            )
        }
    }

    func testNextRootThrowsOnInvalidYaml() throws {
        let invalidYAML = "|\na"

        let parser = try Parser(yaml: invalidYAML)
        // first iteration returns scalar
        XCTAssertEqual(try parser.nextRoot(), Node("", Tag(.str), .literal))
        // second iteration throws error
        XCTAssertThrowsError(try parser.nextRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                2:1: error: parser: did not find expected <document start>:
                a
                ^
                """
            )
        }
    }

    func testSingleRootThrowsOnInvalidYaml() throws {
        let invalidYAML = "|\na"

        let parser = try Parser(yaml: invalidYAML)
        XCTAssertThrowsError(try parser.singleRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                2:1: error: parser: did not find expected <document start>:
                a
                ^
                """
            )
        }
    }

    func testSingleRootThrowsOnMultipleDocuments() throws {
        let multipleDocuments = "document 1\n---\ndocument 2\n"
        let parser = try Parser(yaml: multipleDocuments)
        XCTAssertThrowsError(try parser.singleRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                2:1: error: composer: expected a single document in the stream in line 1, column 1
                but found another document:
                ---
                ^
                """
            )
        }
    }

    func testUndefinedAliasCausesError() throws {
        let undefinedAlias = "*undefinedAlias\n"
        let parser = try Parser(yaml: undefinedAlias)
        XCTAssertThrowsError(try parser.singleRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                1:1: error: composer: found undefined alias:
                *undefinedAlias
                ^
                """
            )
        }
    }

    func testScannerErrorMayHaveNullContext() throws {
        // https://github.com/realm/SwiftLint/issues/1436
        let swiftlint1436 = "large_tuple: warning: 3"
        let parser = try Parser(yaml: swiftlint1436)
        XCTAssertThrowsError(try parser.singleRoot()) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", """
                1:21: error: scanner: mapping values are not allowed in this context:
                large_tuple: warning: 3
                                    ^
                """
            )
        }
    }
}

extension YamlErrorTests {
    static var allTests: [(String, (YamlErrorTests) -> () throws -> Void)] {
        return [
            ("testYamlErrorReader", testYamlErrorReader),
            ("testYamlErrorScanner", testYamlErrorScanner),
            ("testYamlErrorParser", testYamlErrorParser),
            ("testNextRootThrowsOnInvalidYaml", testNextRootThrowsOnInvalidYaml),
            ("testSingleRootThrowsOnInvalidYaml", testSingleRootThrowsOnInvalidYaml),
            ("testSingleRootThrowsOnMultipleDocuments", testSingleRootThrowsOnMultipleDocuments),
            ("testUndefinedAliasCausesError", testUndefinedAliasCausesError),
            ("testScannerErrorMayHaveNullContext", testScannerErrorMayHaveNullContext)
        ]
    }
}
