//
//  Anchor.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

/// A representation of a YAML tag see: https://yaml.org/spec/1.2.2/
/// Types interested in Encoding and Decoding Anchors should
/// conform to YamlAnchorProviding and YamlAnchorCoding respectively.
public final class Anchor: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable {

    /// Returns true if and only if `character` is permitted by the underlying cyaml implementation
    /// (alphanumeric, hyphen, or underscore).
    public static func isPermittedCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "-" || character == "_"
    }

    /// Returns true if and only if `string` contains only characters which are also permitted
    /// (alphanumeric, hyphen, or underscore).
    public static func is_cyamlAlpha(_ string: String) -> Bool {
        string.allSatisfy(isPermittedCharacter)
    }

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

/// Conformance of Anchor to CustomStringConvertible returns `rawValue` as `description`
extension Anchor: CustomStringConvertible {
    public var description: String { rawValue }
}
