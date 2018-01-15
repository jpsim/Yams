//
//  DecoderTests.swift
//  Yams
//
//  Created by Dan Cutting on 15/01/2018.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

class DecoderTests: XCTestCase {

    private struct Sample: Codable, Equatable {
        let values: [String]

        static func == (lhs: Sample, rhs: Sample) -> Bool {
            return lhs.values == rhs.values
        }
    }

    func testWellFormedSequenceOfStringsInMap() {
        let text = """
values:
- hello
"""
        do {
            let actual = try YAMLDecoder().decode(Sample.self, from: text)
            let expected = Sample(values: ["hello"])
            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMalformedSequenceOfStringsInMap() {
        let text = """
values:
- hello:
"""
        XCTAssertThrowsError(try YAMLDecoder().decode(Sample.self, from: text))
    }
}
