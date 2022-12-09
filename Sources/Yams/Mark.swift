//
//  Mark.swift
//  Yams
//
//  Created by Norio Nomura on 4/11/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

/// The pointer position.
public struct Mark {
    /// Line number starting from 1.
    public let line: Int
    /// Column number starting from 1. libYAML counts columns in `UnicodeScalar`.
    public let column: Int
}

// MARK: - CustomStringConvertible Conformance

extension Mark: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String { return "\(line):\(column)" }
}

// MARK: Snippet

extension Mark {
    /// Returns snippet string pointed by Mark instance from YAML String.
    public func snippet(from yaml: String) -> String {
        fatalError("Unimplemented")
    }
}
