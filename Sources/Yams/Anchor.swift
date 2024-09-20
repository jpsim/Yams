//
//  Anchor.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.

import Foundation

public final class Anchor: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable {
    
    public static let permittedCharacters = CharacterSet.lowercaseLetters
                                                .union(.uppercaseLetters)
                                                .union(.decimalDigits)
                                                .union(.init(charactersIn: "-_"))
    
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

extension Anchor: CustomStringConvertible {
    public var description: String { rawValue }
}

