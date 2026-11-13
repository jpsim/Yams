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

    func testGeneratedAnchorAvoidsLaterCallerAnchor_HashableAliasingStrategy() throws {
        try _testGeneratedAnchorAvoidsLaterCallerAnchor(strategy: HashableAliasingStrategy())
    }

    func testGeneratedAnchorAvoidsLaterCallerAnchor_StrictCodableAliasingStrategy() throws {
        try _testGeneratedAnchorAvoidsLaterCallerAnchor(strategy: StrictEncodableAliasingStrategy())
    }

    func testRemitAnchorPreservesIdentityAndReservation_HashableAliasingStrategy() throws {
        try _testRemitAnchorPreservesIdentityAndReservation(strategy: HashableAliasingStrategy())
    }

    func testRemitAnchorPreservesIdentityAndReservation_StrictCodableAliasingStrategy() throws {
        try _testRemitAnchorPreservesIdentityAndReservation(strategy: StrictEncodableAliasingStrategy())
    }

    func testReleasePreservesMonotonicCounter_HashableAliasingStrategy() throws {
        try _testReleasePreservesMonotonicCounter(strategy: HashableAliasingStrategy())
    }

    func testReleasePreservesMonotonicCounter_StrictCodableAliasingStrategy() throws {
        try _testReleasePreservesMonotonicCounter(strategy: StrictEncodableAliasingStrategy())
    }

    func testFailedEncodeReleasesAnchors_HashableAliasingStrategy() throws {
        try _testFailedEncodeReleasesAnchors(strategy: HashableAliasingStrategy())
    }

    func testFailedEncodeReleasesAnchors_StrictCodableAliasingStrategy() throws {
        try _testFailedEncodeReleasesAnchors(strategy: StrictEncodableAliasingStrategy())
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

    private func _testGeneratedAnchorAvoidsLaterCallerAnchor(
        strategy: any RedundancyAliasingStrategy
    ) throws {
        let value = SiblingAnchoredValue(
            first: UnanchoredScalar(value: 1),
            second: UnanchoredScalar(value: 1),
            anchored: AnchoredScalar(value: 2, anchor: "1"),
            repeatedAnchor: AnchoredScalar(value: 2, anchor: "1")
        )
        let encoder = YAMLEncoder()
        encoder.options = .init(redundancyAliasingStrategy: strategy)
        let yaml = try encoder.encode(value)
        let firstAnchor = strategy is StrictEncodableAliasingStrategy ? "2" : "1"
        let callerAnchor = strategy is StrictEncodableAliasingStrategy ? "3" : "2"

        XCTAssertTrue(yaml.contains("first: &\(firstAnchor)"), yaml)
        XCTAssertTrue(yaml.contains("second: *\(firstAnchor)"), yaml)
        XCTAssertTrue(yaml.contains("anchored: &\(callerAnchor)"), yaml)
        XCTAssertTrue(yaml.contains("repeatedAnchor: *\(callerAnchor)"), yaml)
        XCTAssertEqual(_anchors(in: yaml), [firstAnchor, callerAnchor], yaml)
    }

    private func _testRemitAnchorPreservesIdentityAndReservation(
        strategy: any RedundancyAliasingStrategy
    ) throws {
        let original = UnanchoredScalar(value: 1)
        let originalOutcome = try strategy.alias(for: original)
        guard case let .anchor(originalAnchor) = originalOutcome else {
            XCTFail("should be anchor: \(originalOutcome)")
            return
        }

        try strategy.remit(anchor: Anchor(rawValue: originalAnchor.rawValue))

        guard case let .alias(survivingAnchor) = try strategy.alias(for: original) else {
            XCTFail("an equal but distinct Anchor should not evict the original")
            return
        }
        XCTAssertTrue(survivingAnchor === originalAnchor)

        let colliding = AnchoredScalar(value: 2, anchor: originalAnchor.rawValue)
        guard case let .anchor(replacementAnchor) = try strategy.alias(for: colliding) else {
            XCTFail("a colliding caller anchor should be replaced")
            return
        }
        XCTAssertEqual(replacementAnchor.rawValue, "2")

        try strategy.remit(anchor: originalAnchor)

        let reused = AnchoredScalar(value: 3, anchor: originalAnchor.rawValue)
        guard case let .anchor(reusedAnchor) = try strategy.alias(for: reused) else {
            XCTFail("the exact remitted anchor name should be reusable")
            return
        }
        XCTAssertTrue(reusedAnchor === reused.yamlAnchor)

        guard case let .anchor(nextAnchor) = try strategy.alias(for: original) else {
            XCTFail("remitting the original anchor should remove its alias mapping")
            return
        }
        XCTAssertEqual(nextAnchor.rawValue, "3")
    }

    private func _testReleasePreservesMonotonicCounter(
        strategy: any RedundancyAliasingStrategy
    ) throws {
        let encoder = YAMLEncoder()
        encoder.options = .init(redundancyAliasingStrategy: strategy)

        let value = [UnanchoredScalar(value: 1), UnanchoredScalar(value: 1)]
        let first = try encoder.encode(value)
        let second = try encoder.encode(value)
        let reused = try encoder.encode(AnchoredScalar(value: 1, anchor: "1"))

        XCTAssertTrue(first.contains("&2"), first)
        XCTAssertTrue(second.contains("&4"), second)
        XCTAssertTrue(reused.contains("&1"), reused)
    }

    private func _testFailedEncodeReleasesAnchors(
        strategy: any RedundancyAliasingStrategy
    ) throws {
        let flaky = FlakyValue()
        let value = FlakyPair(
            first: UnanchoredValue(value: 1),
            second: UnanchoredValue(value: 1),
            flaky: flaky
        )
        let encoder = YAMLEncoder()
        encoder.options = .init(redundancyAliasingStrategy: strategy)

        XCTAssertThrowsError(try encoder.encode(value))

        flaky.shouldFail = false
        let yaml = try encoder.encode(value)
        let firstAnchor = strategy is StrictEncodableAliasingStrategy ? "6" : "3"

        XCTAssertTrue(yaml.contains("first: &\(firstAnchor)"), yaml)
        XCTAssertTrue(yaml.contains("second: *\(firstAnchor)"), yaml)
        XCTAssertFalse(yaml.contains("*1"), yaml)
    }

    private func _anchors(in yaml: String) -> [String] {
        yaml.split(separator: "\n").compactMap { line in
            guard let ampersand = line.firstIndex(of: "&") else {
                return nil
            }
            return line[line.index(after: ampersand)...].split(separator: " ").first.map(String.init)
        }
    }
}

private struct AnchoredScalar: YAMLEncodable, Hashable, YamlAnchorCoding {
    let value: Int
    var yamlAnchor: Anchor?

    init(value: Int, anchor: Anchor?) {
        self.value = value
        yamlAnchor = anchor
    }

    init(value: Int, anchor: String) {
        self.init(value: value, anchor: Anchor(rawValue: anchor))
    }

    func box() -> Node {
        Node(String(value))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

private struct UnanchoredScalar: YAMLEncodable, Hashable {
    let value: Int

    func box() -> Node {
        Node(String(value))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

private struct UnanchoredValue: Codable, Hashable {
    let value: Int
}

private struct SiblingAnchoredValue: Encodable {
    let first: UnanchoredScalar
    let second: UnanchoredScalar
    let anchored: AnchoredScalar
    let repeatedAnchor: AnchoredScalar
}

private struct FlakyPair: Encodable {
    let first: UnanchoredValue
    let second: UnanchoredValue
    let flaky: FlakyValue

    enum CodingKeys: String, CodingKey {
        case first
        case second
        case flaky
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(first, forKey: .first)
        try container.encode(second, forKey: .second)
        try container.encode(flaky, forKey: .flaky)
    }
}

private final class FlakyValue: Encodable {
    var shouldFail = true

    func encode(to encoder: Encoder) throws {
        let strategyKey = CodingUserInfoKey(rawValue: "redundancyAliasingStrategy")!
        if shouldFail, encoder.userInfo[strategyKey] != nil {
            throw TestError.expectedFailure
        }
        var container = encoder.singleValueContainer()
        try container.encode("fixed")
    }
}

private enum TestError: Error {
    case expectedFailure
}
