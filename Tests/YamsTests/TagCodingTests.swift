//
//  TagCodingTests.swift
//  Yams
//
//  Created by Adora Lynch on 9/18/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import XCTest
import Yams

class TagCodingTests: XCTestCase {

    /// Test the encoding of a yaml tag using a type that conforms to YamlTagProviding
    func testYamlTagProviding_valuePresent() throws {
        let simpleStruct = SimpleWithTag(nested: .init(stringValue: "it's a value"), intValue: 52)

        _testRoundTrip(of: simpleStruct,
                       expectedYAML: """
                                     !<simple>
                                     nested:
                                       stringValue: it's a value
                                     intValue: 52

                                     """ ) // ^ the Yams.Tag is encoded as a yaml tag
    }

    /// Test the encoding of a a type that does not conform to YamlTagProviding but none the less declares
    /// a coding member with the same name
    func testStringTypeTagName_valuePresent() throws {
        let simpleStruct = SimpleWithStringTypeTagName(nested: .init(stringValue: "it's a value"),
                                                          intValue: 52,
                                                          yamlTag: "but typed as a string")

        _testRoundTrip(of: simpleStruct,
                       expectedYAML: """
                                     nested:
                                       stringValue: it's a value
                                     intValue: 52
                                     yamlTag: but typed as a string

                                     """ ) // ^ the member is _not_ treated as an tag
    }

    /// Nothing interesting happens when a type does not conform to YamlTagProviding none the less
    /// declares a coding member with the same name but that value is nil
    func testStringTypeTagName_valueNotPresent() throws {
        let expectedStruct = SimpleWithStringTypeTagName(nested: .init(stringValue: "it's a value"),
                                                            intValue: 52,
                                                            yamlTag: nil)
        _testRoundTrip(of: expectedStruct,
                       expectedYAML: """
                                     nested:
                                       stringValue: it's a value
                                     intValue: 52

                                     """)
    }

    /// This test documents some undesirable behavior, but in an unlikely circumstance.
    /// If the decoded type does not conform to YamlTagProviding it can still have a coding key called
    /// `yamlTag`
    /// If Yams tries to decode such a type AND the document has a nil value for `yamlTag` AND the
    /// parent context is a mapping AND that mapping has an actual tag (in the document)
    /// THEN Yams wrongly tries to decode the tag as the declared type of key `yamlTag`.
    /// If that declared type can be decoded from a scalar string value (like String and RawRepresentable
    /// where RawValue == String) then the decoding will actually succeed.
    /// Which effectively injects an unexpected value into the decoded type.
    func testStringTypeTagName_withTagPresent_valueNil() throws {
        let expectedStruct = SimpleWithStringTypeTagName(nested: .init(stringValue: "it's a value"),
                                                            intValue: 52,
                                                            yamlTag: nil)
        let decoder = YAMLDecoder()
        let data = """
                   !<An:Actual:Tag>
                   nested:
                     stringValue: it's a value
                   intValue: 52

                   """.data(using: decoder.options.encoding.swiftStringEncoding)!

        let decodedStruct = try decoder.decode(SimpleWithStringTypeTagName.self, from: data)

        let fixBulletin = "YESS!!! YOU FIXED IT! See \(#file):\(#line) for explanation."

        // begin assertions of known-but-undesirable behavior
        XCTAssertNotEqual(decodedStruct, expectedStruct, fixBulletin) // We wish this was equal
        XCTAssertEqual(decodedStruct.yamlTag, "An:Actual:Tag", fixBulletin) // we wish .yamlTag was nil
        // end assertions of known-but-undesirable behavior

        // Check the remainder of the properties that the above confusion did not involve
        XCTAssertEqual(decodedStruct.nested, expectedStruct.nested)
        XCTAssertEqual(decodedStruct.intValue, expectedStruct.intValue)
    }
}

class TagWithAnchorCodingTests: XCTestCase {

    /// If types conform to YamlTagProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_duplicateValue_commonTag() throws {
        let simpleStruct = SimpleWithTag(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct]

        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: duplicatedStructArray,
                       with: options,
                       expectedYAML: """
                                     - &2 !<simple>
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     - *2

                                     """ )
    }

    /// If types conform to YamlTagProviding and are NOT Hashable-Equal then HashableAliasingStrategy
    /// does not alias them
    /// even though their members may still be Hashable-Equal and therefor maybe aliased.
    func testEncoderAutoAlias_Hashable_uniqueTag() throws {
        let differentTypesOneTags = SimplePair(first:
                                                SimpleWithTag(nested: .init(stringValue: "it's a value"),
                                                              intValue: 52),
                                               second:
                                                SimpleWithoutTag(nested: .init(stringValue: "it's a value"),
                                                                 intValue: 52))

        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: differentTypesOneTags,
                       with: options,
                       expectedYAML: """
                                     first: !<simple>
                                       nested: &3
                                         stringValue: it's a value
                                       intValue: &5 52
                                     second:
                                       nested: *3
                                       intValue: *5

                                     """ )
    }

    /// If types conform to YamlTagProviding can declare to have the same tag and still be NOT
    /// Hashable-Equal then HashableAliasingStrategy does not alias them
    /// even though their members may still be Hashable-Equal and therefor maybe aliased.
    func testEncoderAutoAlias_Hashable_distinctValues_commonTag() throws {
        let differentTypesOneTags = SimplePair(first:
                                                SimpleWithTag(nested: .init(stringValue: "it's a value"),
                                                              intValue: 52),
                                               second:
                                                SimpleWithTag2(nested: .init(stringValue: "it's a value"),
                                                               intValue: 52))

        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: differentTypesOneTags,
                       with: options,
                       expectedYAML: """
                                     first: !<simple>
                                       nested: &3
                                         stringValue: it's a value
                                       intValue: &5 52
                                     second: !<simple>
                                       nested: *3
                                       intValue: *5

                                     """ )
    }

    /// If different types conform to YamlTagProviding they can declare to have the same tag and further,
    /// have exactly the same encoded representation.
    /// In thisi case StrictEncodableAliasingStrategy will still alias them even though they are encoded and
    /// decoded from different types.
    func testEncoderAutoAlias_StrictEncodable_distinctValues_commonTag() throws {
        let differentTypesOneTags = SimplePair(first:
                                                SimpleWithTag(nested: .init(stringValue: "it's a value"),
                                                              intValue: 52),
                                               second:
                                                SimpleWithTag2(nested: .init(stringValue: "it's a value"),
                                                               intValue: 52))

        var options = YAMLEncoder.Options()
        options.redundancyAliasingStrategy = StrictEncodableAliasingStrategy()
        _testRoundTrip(of: differentTypesOneTags,
                       with: options,
                       expectedYAML: """
                                     first: &2 !<simple>
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     second: *2

                                     """ )
    }

    /// If types conform to YamlTagProviding and YamlAnchorProviding, both are respected.
    func testEncoderAutoAlias_Hashable_commonTagAndAnchor() throws {
        let simpleStruct = SimpleWithTagAndAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct]

        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: duplicatedStructArray,
                       with: options,
                       expectedYAML: """
                                     - &simple-Anchor !<simple:Tag>
                                       nested:
                                         stringValue: it's a value
                                       intValue: 52
                                     - *simple-Anchor

                                     """ )
    }

    /// A type used to contain values used during testing
    private struct SimplePair<First: SimpleProtocol, Second: SimpleProtocol>: Hashable, Codable {
        let first: First
        let second: Second
    }

}
// MARK: - Types used for Tag encoding tests.

private struct NestedStruct: Codable, Hashable {
    let stringValue: String
}
private protocol SimpleProtocol: Codable, Hashable {
    // swiftlint:disable unused_declaration
    var nested: NestedStruct { get }
    // swiftlint:disable unused_declaration
    var intValue: Int { get }
}

private struct SimpleWithTag: SimpleProtocol, YamlTagProviding {
    let nested: NestedStruct
    let intValue: Int
    var yamlTag: Tag? = "simple"
}

private struct SimpleWithTag2: SimpleProtocol, YamlTagProviding {
    let nested: NestedStruct
    let intValue: Int
    var yamlTag: Tag? = "simple"
}

private struct SimpleWithoutTag: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int
}

private struct SimpleWithStringTypeTagName: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int
    var yamlTag: String? = "StringTypeTag"
}

private struct SimpleWithTagAndAnchor: SimpleProtocol, YamlTagProviding, YamlAnchorProviding {
    let nested: NestedStruct
    let intValue: Int
    var yamlTag: Tag? = "simple:Tag"
    var yamlAnchor: Anchor? = "simple-Anchor"
}
