//
//  AnchorEncodingTests.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import XCTest
import Yams

class AnchorCodingTests: XCTestCase {
    
    /// Test the encoding of a yaml anchor using a type that conforms to YamlAnchorProviding
    func testYamlAnchorProviding_valuePresent() throws {
        let simpleStruct = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        
        _testRoundTrip(of: simpleStruct,
                       expectedYAML:"""
                                    &simple
                                    nested:
                                      stringValue: it's a value
                                    intValue: 52
                                    
                                    """ ) // ^ the Yams.Anchor is encoded as a yaml anchor
    }
    
    /// Test the encoding of a a type that does not conform to YamlAnchorProviding but none the less declares a coding member with the same name
    func testStringTypeAnchorName_valuePresent() throws {
        let simpleStruct = SimpleWithStringTypeAnchorName(nested: .init(stringValue: "it's a value"), 
                                                          intValue: 52,
                                                          yamlAnchor: "but typed as a string")
        
        _testRoundTrip(of: simpleStruct,
                       expectedYAML:"""
                                    nested:
                                      stringValue: it's a value
                                    intValue: 52
                                    yamlAnchor: but typed as a string
                                    
                                    """ ) // ^ the member is _not_ treated as an anchor
    }
    
    /// Nothing interesting happens when a type does not conform to YamlAnchorProviding none the less declares a coding member with the same name but that value is nil
    func testStringTypeAnchorName_valueNotPresent() throws {
        let expectedStruct = SimpleWithStringTypeAnchorName(nested: .init(stringValue: "it's a value"),
                                                            intValue: 52,
                                                            yamlAnchor: nil)
        _testRoundTrip(of: expectedStruct,
                       expectedYAML: """
                                     nested:
                                       stringValue: it's a value
                                     intValue: 52
                                     
                                     """)
    }
    
    /// This test documents some undesirable behavior, but in an unlikely circumstance.
    /// If the decoded type does not conform to YamlAnchorProviding it can still have a coding key called `yamlAnchor`
    /// If Yams tries to decode such a type AND the document has a nil value for `yamlAnchor` AND the parent context is a mapping AND that mapping has an actual anchor (in the document)
    /// THEN Yams wrongly tries to decode the anchor as the declared type of key `yamlAnchor`.
    /// If that declared type can be decoded from a scalar string value (like String and RawRepresentable where RawValue == String) then the decoding will actually succeed.
    /// Which effectively injects an unexpected value into the decoded type.
    func testStringTypeAnchorName_withAnchorPresent_valueNil() throws {
        let expectedStruct = SimpleWithStringTypeAnchorName(nested: .init(stringValue: "it's a value"),
                                                            intValue: 52,
                                                            yamlAnchor: nil)
        let decoder = YAMLDecoder()
        let data = """
                   &AnActualAnchor
                   nested:
                     stringValue: it's a value
                   intValue: 52
                   
                   """.data(using: decoder.encoding.swiftStringEncoding)!
        
        let decodedStruct = try decoder.decode(SimpleWithStringTypeAnchorName.self, from: data)
        
        let fixBulletin = "YESS!!! YOU FIXED IT! See \(#file):\(#line) for explanation."
        
        // begin assertions of known-but-undesirable behavior
        XCTAssertNotEqual(decodedStruct, expectedStruct, fixBulletin) // We wish this was equal
        XCTAssertEqual(decodedStruct.yamlAnchor, "AnActualAnchor", fixBulletin) // we wish .yamlAnchor was nil
        // end assertions of known-but-undesirable behavior
        
        
        // Check the remainder of the properties that the above confusion did not involve
        XCTAssertEqual(decodedStruct.nested, expectedStruct.nested)
        XCTAssertEqual(decodedStruct.intValue, expectedStruct.intValue)
    }
}
    
class AnchorAliasingTests: XCTestCase {
    
    /// CYaml library does not detect identical values and automatically alias them.
    func testCyamlDoesNotAutoAlias_noAnchor() throws {
        let simpleNoAnchor = SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let differentTypesOneAnchor = SimplePair(first: simpleNoAnchor,
                                                second: simpleNoAnchor)
        
        _testRoundTrip(of: differentTypesOneAnchor,
                       expectedYAML:"""
                                    first:
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    second:
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    
                                    """ )
    }
    
    /// CYaml library does not detect identical values and automatically alias them even if the first occurrence has an anchor.
    func testCyamlDoesNotAutoAlias_uniqueAnchor() throws {
        let simpleStruct = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let simpleNoAnchor = SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let differentTypesOneAnchor = SimplePair(first: simpleStruct,
                                                second: simpleNoAnchor)
        
        _testRoundTrip(of: differentTypesOneAnchor,
                       expectedYAML:"""
                                    first: &simple
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    second:
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    
                                    """ )
    }
    
    /// CYaml library does not detect identical values and automatically alias them even if they have identical anchors.
    // This one is not a shortcoming of CYaml. The yaml spec requires that nodes can shadow earlier anchors.
    func testCyamlDoesNotAutoAlias_duplicateAnchor() throws {
        let simpleStruct = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructPair = SimplePair(first: simpleStruct, second: simpleStruct)
        
        _testRoundTrip(of: duplicatedStructPair,
                       expectedYAML:"""
                                    first: &simple
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    second: &simple
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    
                                    """ )
    }
    
    
    /// If types conform to YamlAnchorProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_duplicateAnchor() throws {
        let simpleStruct = SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct]
        
        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: duplicatedStructArray,
                       with: options,
                       expectedYAML:"""
                                    - &simple
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    - *simple
                                    
                                    """ )
    }
    
    /// If types do NOT conform to YamlAnchorProviding and are Hashable-Equal then HashableAliasingStrategy aliases them
    func testEncoderAutoAlias_Hashable_noAnchors() throws {
        let simpleStruct = SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52)
        let duplicatedStructArray = [simpleStruct, simpleStruct] // zero specified anchor
        
        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: duplicatedStructArray,
                       with: options,
                       expectedYAML:"""
                                    - &2
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    - *2
                                    
                                    """ )
    }
    
    /// If types conform to YamlAnchorProviding and are NOT Hashable-Equal then HashableAliasingStrategy does not alias them
    /// even though their members may still be Hashable-Equal and therefor maybe aliased.
    func testEncoderAutoAlias_Hashable_uniqueAnchor() throws {
        let differentTypesOneAnchors = SimplePair(first: SimpleWithAnchor(nested: .init(stringValue: "it's a value"), intValue: 52),
                                                 second: SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52))
        
        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: differentTypesOneAnchors,
                       with: options,
                       expectedYAML:"""
                                    first: &simple
                                      nested: &2
                                        stringValue: it's a value
                                      intValue: &4 52
                                    second:
                                      nested: *2
                                      intValue: *4
                                    
                                    """ )
    }
    
    /// If types conform to YamlAnchorProviding and are NOT Hashable-Equal then HashableAliasingStrategy does not alias them
    /// even though their members may still be Hashable-Equal and therefor maybe aliased.
    /// Note particularly that the to Simple* values here have exactly the same encoded representation, they're just different types and thus not Hashable-Equal
    func testEncoderAutoAlias_Hashable_noAnchor() throws {
        let differentTypesNoAnchors = SimplePair(first: SimpleWithoutAnchor2(nested: .init(stringValue: "it's a value"), intValue: 52),
                                                 second: SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52))
        
        let options = YAMLEncoder.Options(redundancyAliasingStrategy: HashableAliasingStrategy())
        _testRoundTrip(of: differentTypesNoAnchors,
                       with: options,
                       expectedYAML:"""
                                    first:
                                      nested: &3
                                        stringValue: it's a value
                                      intValue: &5 52
                                    second:
                                      nested: *3
                                      intValue: *5
                                    
                                    """ )
    }
    
    /// If types conform to YamlAnchorProviding and have exactly the same encoded representation then StrictEncodableAliasingStrategy alias them
    /// even though they are encoded and decoded from different types.
    func testEncoderAutoAlias_StrictEncodable_NoAnchors() throws {
        let differentTypesNoAnchors = SimplePair(first: SimpleWithoutAnchor2(nested: .init(stringValue: "it's a value"), intValue: 52),
                                                second: SimpleWithoutAnchor(nested: .init(stringValue: "it's a value"), intValue: 52))
        
        var options = YAMLEncoder.Options()
        options.redundancyAliasingStrategy = StrictEncodableAliasingStrategy()
        _testRoundTrip(of: differentTypesNoAnchors,
                       with: options,
                       expectedYAML:"""
                                    first: &2
                                      nested:
                                        stringValue: it's a value
                                      intValue: 52
                                    second: *2
                                    
                                    """ )
    }
    
    /// A type used to contain values used during testing
    private struct SimplePair<First: SimpleProtocol, Second: SimpleProtocol>: Hashable, Codable {
        let first: First
        let second: Second
    }
    
}

// MARK: - Types used for Anchor encoding tests.

fileprivate struct NestedStruct: Codable, Hashable {
    let stringValue: String
}
fileprivate protocol SimpleProtocol: Codable, Hashable {
    var nested: NestedStruct { get }
    var intValue: Int { get }
}

fileprivate struct SimpleWithAnchor: SimpleProtocol, YamlAnchorProviding {
    let nested: NestedStruct
    let intValue: Int
    var yamlAnchor: Anchor? = "simple"
}

fileprivate struct SimpleWithoutAnchor: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int
}

fileprivate struct SimpleWithoutAnchor2: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int
    var unrelatedValue: String?
}

fileprivate struct SimpleWithStringTypeAnchorName: SimpleProtocol {
    let nested: NestedStruct
    let intValue: Int
    var yamlAnchor: String? = "StringTypeAnchor"
}



