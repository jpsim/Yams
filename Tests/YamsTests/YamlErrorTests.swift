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
    func testYamlErrorEmitter() throws {
        XCTAssertThrowsError(try Yams.serialize(node: "test", version: (1, 2))) { error in
            XCTAssertTrue(error is YamlError)
            XCTAssertEqual("\(error)", "incompatible %YAML directive")
        }
    }

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
            XCTAssertEqual(error.description, expected)
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
            XCTAssertEqual(error.description, expected)
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
            XCTAssertEqual(error.description, expected)
        } catch {
            XCTFail("should not happen")
        }
    }

    func testNextRootThrowsOnInvalidYaml() throws {
        let invalidYAML = "|\na"

        let parser = try Parser(yaml: invalidYAML)
        // first iteration returns scalar
        XCTAssertEqual(try parser.nextRoot(), Node("", Tag(.null), .literal))
        // second iteration throws error
        XCTAssertThrowsError(try parser.nextRoot()) {
            if let error = $0 as? YamlError {
                XCTAssertEqual(error.description, "a\n^ did not find expected <document start> ")
            } else {
                XCTFail()
            }
        }
    }

    func testSingleRootThrowsOnInvalidYaml() throws {
        let invalidYAML = "|\na"

        let parser = try Parser(yaml: invalidYAML)
        XCTAssertThrowsError(try parser.singleRoot()) {
            if let error = $0 as? YamlError {
                XCTAssertEqual(error.description, "a\n^ did not find expected <document start> ")
            } else {
                XCTFail()
            }
        }
    }

    func testSingleRootThrowsOnMultipleDocuments() throws {
        let multipleDocuments = "document 1\n---\ndocument 2\n"
        let parser = try Parser(yaml: multipleDocuments)
        XCTAssertThrowsError(try parser.singleRoot()) {
            if let error = $0 as? YamlError {
                XCTAssertEqual(error.description,
                               "---\n^ but found another document expected a single document in the stream")
            } else {
                XCTFail()
            }
        }
    }

    func testUndefinedAliasCausesError() throws {
        let undefinedAlias = "*undefinedAlias\n"
        let parser = try Parser(yaml: undefinedAlias)
        XCTAssertThrowsError(try parser.singleRoot()) {
            if let error = $0 as? YamlError {
                XCTAssertEqual(error.description,
                               "*undefinedAlias\n^ found undefined alias ")
            } else {
                XCTFail()
            }
        }
    }
}

extension YamlErrorTests {
    static var allTests: [(String, (YamlErrorTests) -> () throws -> Void)] {
        #if swift(>=3.1)
            return [
                ("testYamlErrorReader", testYamlErrorReader),
                ("testYamlErrorScanner", testYamlErrorScanner),
                ("testYamlErrorParser", testYamlErrorParser),
                ("testNextRootThrowsOnInvalidYaml", testNextRootThrowsOnInvalidYaml),
                ("testSingleRootThrowsOnInvalidYaml", testSingleRootThrowsOnInvalidYaml),
                ("testSingleRootThrowsOnMultipleDocuments", testSingleRootThrowsOnMultipleDocuments),
                ("testUndefinedAliasCausesError", testUndefinedAliasCausesError)
            ]
        #else
            return [] // https://bugs.swift.org/browse/SR-3366
        #endif
    }
}
