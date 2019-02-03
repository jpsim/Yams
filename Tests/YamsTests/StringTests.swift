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
    // column     1 2 3 4 5 6 7 8 9  10 11
    // line 1     L I N E 1 _ 6 7 あ \n
    // line 2     L I N E 2 _ 7 8 9  0 \n
    // line 3     L I N E 3 _ 8 9 0  1 \n
    let string = "LINE1_67あ\nLINE2_7890\nLINE3_8901\n"

    // Confirm behavior of Standard Library API
    func testConfirmBehaviorOfStandardLibraryAPI() {
        let rangeOfFirstLine = string.lineRange(for: string.startIndex..<string.startIndex)
        let firstLine = string[rangeOfFirstLine]
        XCTAssertEqual(firstLine, "LINE1_67あ\n")
    }

    // `String.lineNumberColumnAndContents(at:)`
    func testLineNumberColumnAndContentsAtOffset() {
        // offset     0 1 2 3 4 5 6 7 8 9 10
        // line 1     L I N E 1 _ 6 7 あ \n
        // line 2     L I N E 2 _ 7 8 9 0 \n
        // line 3     L I N E 3 _ 8 9 0 1 \n
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 0)!
            XCTAssertEqual(number, 0)
            XCTAssertEqual(column, 0)
            XCTAssertEqual(content, "LINE1_67あ\n")
        }
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 9)!
            XCTAssertEqual(number, 0)
            XCTAssertEqual(column, 9)
            XCTAssertEqual(content, "LINE1_67あ\n")
        }
        do {
            let (number, column, content) = string.lineNumberColumnAndContents(at: 10)!
            XCTAssertEqual(number, 1)
            XCTAssertEqual(column, 0)
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
            ("testConfirmBehaviorOfStandardLibraryAPI", testConfirmBehaviorOfStandardLibraryAPI),
            ("testLineNumberColumnAndContentsAtOffset", testLineNumberColumnAndContentsAtOffset),
            ("testSubstringAtLine", testSubstringAtLine)
        ]
    }
}
