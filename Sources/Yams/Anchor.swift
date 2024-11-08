//
//  Anchor.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.

import Foundation

/// A representation of a YAML tag see: https://yaml.org/spec/1.2.2/
/// Types interested in Encoding and Decoding Anchors should
/// conform to YamlAnchorProviding and YamlAnchorCoding respectively.
public final class Anchor: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable {

    /// A CharacterSet containing only characters which are permitted by the underlying cyaml implementation
    public static let permittedCharacters = CharacterSet.lowercaseLetters
                                                .union(.uppercaseLetters)
                                                .union(.decimalDigits)
                                                .union(.init(charactersIn: "-_"))

    /// Returns true if and only if `string` contains only characters which are also in `permittedCharacters`
    public static func is_cyamlAlpha(_ string: String) -> Bool {
        Anchor.permittedCharacters.isSuperset(of: .init(charactersIn: string))
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
