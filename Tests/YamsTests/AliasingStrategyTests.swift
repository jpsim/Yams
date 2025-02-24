//
//  AliasingStrategyTests.swift
//  Yams
//
//  Created by Adora Lynch on 2/23/25.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import XCTest
import Yams

class AliasingStrategyTests: XCTestCase {

    func testRemitAnchor_HashableAliasingStrategy() throws {
        try _testRemitAnchor(strategy: HashableAliasingStrategy())
    }

    func testRemitAnchor_StrictCodableAliasingStrategy() throws {
        try _testRemitAnchor(strategy: StrictEncodableAliasingStrategy())
    }

    private func _testRemitAnchor(strategy: any RedundancyAliasingStrategy) throws {
        let subject = "subject"

        let response1 = try strategy.alias(for: subject)
        guard case let .anchor(anchor1) = response1 else {
            XCTFail("should be anchor: \(response1)")
            return
        }
//        _ = consume response1

        let response2 = try strategy.alias(for: subject)
        guard case let .alias(anchor2) = response2 else {
            XCTFail("should be alias: \(response2)")
            return
        }
//        _ = consume response2

        XCTAssertEqual(anchor1, anchor2)

        try strategy.remit(anchor: anchor2)

        let response3 = try strategy.alias(for: subject)
        guard case let .anchor(anchor3) = response3 else {
            XCTFail("should be anchor: \(response1)")
            return
        }
//        _ = consume response3

        XCTAssertNotEqual(anchor1, anchor3)
    }
}
