//
//  StringTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/7/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
@testable import Yams

class StringTests: XCTestCase {
    // byteoffset 01234567890 12345678901 23456789012
    // column     12345678901 12345678901 12345678901
    let string = "LINE1_6789\nLINE2_7890\nLINE3_8901\n"

    // Confirm behavior of Standard Library API
    func testConfirmBehaviorOfStandardLibraryAPI() {
        let rangeOfFirstLine = string.lineRange(for: string.startIndex..<string.startIndex)
        let firstLine = string.substring(with: rangeOfFirstLine)
        XCTAssertEqual(firstLine, "LINE1_6789\n")
    }

    // `String.lineNumberColumnAndContents(at:)`
    func testLineNumberColumnAndContentsAtByteOffset() {
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 0)!
            XCTAssertEqual(number, 1)
            XCTAssertEqual(column, 1)
            XCTAssertEqual(content, "LINE1_6789\n")
        }
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 10)!
            XCTAssertEqual(number, 1)
            XCTAssertEqual(column, 11)
            XCTAssertEqual(content, "LINE1_6789\n")
        }
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 11)!
            XCTAssertEqual(number, 2)
            XCTAssertEqual(column, 1)
            XCTAssertEqual(content, "LINE2_7890\n")
        }
    }

    // `String.substring(at:)`
    func testSubstringAtLine() {
        let scecondLine = string.substring(at: 1)
        XCTAssertEqual(scecondLine, "LINE2_7890\n")
    }
}

extension StringTests {
    static var allTests: [(String, (StringTests) -> () throws -> Void)] {
        return [
            /* FIXME: https://bugs.swift.org/browse/SR-3366
            ("testConfirmBehaviorOfStandardLibraryAPI", testConfirmBehaviorOfStandardLibraryAPI),
            ("testLineNumberColumnAndContentsAtByteOffset", testLineNumberColumnAndContentsAtByteOffset),
            ("testSubstringAtLine", testSubstringAtLine),
             */
        ]
    }
}
