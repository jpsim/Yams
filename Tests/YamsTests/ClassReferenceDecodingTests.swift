//
//  ClassReferenceDecodingTests.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import XCTest
import Yams

class ClassReferenceDecodingTests: XCTestCase {

    /// If types conform to YamlAnchorProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_duplicateAnchor() throws {
        let simpleStruct = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct]

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: duplicatedStructArray,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     - &simple
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     - *simple

                                     """ )

        guard let decoded else { return }

        XCTAssertTrue(decoded[0] === decoded[1], "Class reference not unique")
    }

    /// If types conform to YamlAnchorProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_duplicateAnchor_objectCoalescing() throws {
        let simpleStruct1 = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let simpleStruct2 = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)

        let sameTypeOneAnchorPair = SimplePair(first: simpleStruct1, second: simpleStruct2)

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: sameTypeOneAnchorPair,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     first: &simple
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     second: *simple

                                     """ )

        guard let decoded else { return }

        XCTAssertTrue(decoded.first === decoded.first, "Class reference not unique")
    }

    /// If types do NOT conform to YamlAnchorProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_noAnchors() throws {
        let simpleStruct = SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct] // zero specified anchor

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: duplicatedStructArray,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     - &2
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     - *2

                                     """ )

        guard let decoded else { return }

        XCTAssertTrue(decoded[0] === decoded[1], "Class reference not unique")
    }

    /// If types conform to YamlAnchorProviding and are NOT Hashable-Equal then
    /// HashableAliasingStrategy does not alias them even though their members may still be
    /// Hashable-Equal and therefor maybe aliased.
    func testEncoderAutoAlias_Hashable_uniqueAnchor() throws {
        let differentTypesOneAnchors = SimplePair(first:
                                                    SimpleWithAnchor(nested: .init(stringValue: "it's a value"),
                                                                     intValue: 52),
                                                 second:
                                                    SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"),
                                                                        intValue: 52))

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: differentTypesOneAnchors,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     first: &simple
                                       nested: &2
                                         stringValue: it's a value
                                       intValue: &4 52
                                     second:
                                       nested: *2
                                       intValue: *4

                                     """ )

        guard let decoded else { return }

        XCTAssertTrue(decoded.first.nested === decoded.second.nested, "Class reference not unique")
    }

    /// If types conform to YamlAnchorProviding and are NOT Hashable-Equal then
    /// HashableAliasingStrategy does not alias them even though their members may still be
    /// Hashable-Equal and therefor maybe aliased.
    /// Note particularly that the to Simple* values here have exactly the same encoded representation,
    /// they're just different types and thus not Hashable-Equal
    func testEncoderAutoAlias_Hashable_noAnchor() throws {
        let differentTypesNoAnchors = SimplePair(first:
                                                    SimpleWithoutAnchor2(nested: .init(stringValue: "it's a value"),
                                                                         intValue: 52),
                                                 second:
                                                    SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"),
                                                                        intValue: 52))

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: differentTypesNoAnchors,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     first:
                                       nested: &3
                                         stringValue: it's a value
                                       intValue: &5 52
                                     second:
                                       nested: *3
                                       intValue: *5

                                     """ )

        guard let decoded else { return }

        XCTAssertTrue(decoded.first.nested === decoded.second.nested, "Class reference not unique")
    }

    /// If types conform to YamlAnchorProviding and have exactly the same encoded representation then
    /// StrictEncodableAliasingStrategy alias them even though they are encoded and decoded from
    ///  different types.
    func testEncoderAutoAlias_StrictEncodable_NoAnchors() throws {
        let differentTypesNoAnchors = SimplePair(first:
                                                    SimpleWithoutAnchor2(nested: .init(stringValue: "it's a value"),
                                                                         intValue: 52),
                                                second:
                                                    SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"),
                                                                        intValue: 52))

        let encodingOptions = YAMLEncoder.Options(redundancyAliasingStrategy: StrictEncodableAliasingStrategy())
        let decodingOptions = YAMLDecoder.Options(aliasDereferencingStrategy: BasicAliasDereferencingStrategy())
        let decoded =
        _testRoundTrip(of: differentTypesNoAnchors,
                       with: encodingOptions,
                       decodingOptions: decodingOptions,
                       expectedYAML: """
                                     first: &2
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     second: *2

                                     """ )

        guard let decoded else { return }

        /// It is expected and rational behavior that if an aliased value is decoded into two different types
        /// that those types cannot share object identity (a memory address)
        XCTAssertTrue(decoded.first !== decoded.second, "Class reference is unique")

        /// It would be nice,
        ///  if objects contained within aliased values which are decoded different types could still identify and
        ///  preserve the object identity of those contained objects.
        ///  (If ivars of different types could share reference to common data)
        /// but is asking too much....
        XCTAssertFalse(decoded.first.nested === decoded.second.nested, "You fixed it!")

        /// The reality of the behavior is that if you declared to decode an aliased value into two different classes,
        /// you forfeit the possibility of down-graph reference sharing.
        XCTAssertTrue(decoded.first.nested !== decoded.second.nested, "Class reference is unique")
    }

    /// A type used to contain values used during testing
    private struct SimplePair<First: SimpleProtocol, Second: SimpleProtocol>: Hashable, Codable {
        let first: First
        let second: Second
    }

}

// MARK: - Types used for Anchor encoding tests.

private class NestedStruct: Codable, Hashable {
    let stringValue: String

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    static func == (lhs: NestedStruct, rhs: NestedStruct) -> Bool {
        lhs.stringValue == rhs.stringValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }
}
private protocol SimpleProtocol: Codable, Hashable {
    // swiftlint:disable unused_declaration
    var nested: NestedStruct { get }
    // swiftlint:disable unused_declaration
    var intValue: Int { get }
}

private class SimpleWithAnchor: SimpleProtocol, YamlAnchorProviding {

    let nested: NestedStruct
    let intValue: Int
    let yamlAnchor: Anchor?

    init(nested: NestedStruct, intValue: Int, yamlAnchor: Anchor? = "simple") {
        self.nested = nested
        self.intValue = intValue
        self.yamlAnchor = yamlAnchor
    }

    static func == (lhs: SimpleWithAnchor, rhs: SimpleWithAnchor) -> Bool {
        lhs.nested == rhs.nested &&
        lhs.intValue == rhs.intValue &&
        lhs.yamlAnchor == rhs.yamlAnchor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nested)
        hasher.combine(intValue)
        hasher.combine(yamlAnchor)
    }
}

private class SimpleWithoutAnchor: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int

    init(nested: NestedStruct, intValue: Int) {
        self.nested = nested
        self.intValue = intValue
    }

    static func == (lhs: SimpleWithoutAnchor, rhs: SimpleWithoutAnchor) -> Bool {
        lhs.nested == rhs.nested &&
        lhs.intValue == rhs.intValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nested)
        hasher.combine(intValue)
    }
}

private class SimpleWithoutAnchor2: SimpleProtocol {

    let nested: NestedStruct
    let intValue: Int
    let unrelatedValue: String?

    init(nested: NestedStruct, intValue: Int, unrelatedValue: String? = nil) {
        self.nested = nested
        self.intValue = intValue
        self.unrelatedValue = unrelatedValue
    }

    static func == (lhs: SimpleWithoutAnchor2, rhs: SimpleWithoutAnchor2) -> Bool {
        lhs.nested == rhs.nested &&
        lhs.intValue == rhs.intValue &&
        lhs.unrelatedValue == rhs.unrelatedValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nested)
        hasher.combine(intValue)
        hasher.combine(unrelatedValue)
    }

}

private class SimpleWithStringTypeAnchorName: SimpleProtocol {

    let nested: NestedStruct
    let intValue: Int
    let yamlAnchor: String?

    init(nested: NestedStruct, intValue: Int, yamlAnchor: String? = "StringTypeAnchor") {
        self.nested = nested
        self.intValue = intValue
        self.yamlAnchor = yamlAnchor
    }

    static func == (lhs: SimpleWithStringTypeAnchorName, rhs: SimpleWithStringTypeAnchorName) -> Bool {
        lhs.nested == rhs.nested &&
        lhs.intValue == rhs.intValue &&
        lhs.yamlAnchor == rhs.yamlAnchor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nested)
        hasher.combine(intValue)
        hasher.combine(yamlAnchor)
    }
}
