//
//  AliasDereferencingStrategy.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

/// A class-bound protocol which implements a strategy for dereferencing aliases (or dealiasing) values during
/// YAML document decoding. YAML documents which do not contain anchors will not benefit from the use of
/// an AliasDereferencingStrategy in any way. The main use-case for dereferencing aliases in a YML document
/// is when decoding into class types. If the yaml document is large and contains many references
/// (perhaps it is a representation of a dense graph) then, decoding into structs will require the of large amounts
/// of system memory to represent highly redundant (duplicated) data structures.
/// However, if the same document is decoded into class types and the decoding uses
/// an `AliasDereferencingStrategy` such as `BasicAliasDereferencingStrategy` then the emitted value will have its
/// class references coalesced. No duplicate objects will be initialized (unless identical objects have multiple
/// distinct anchors in the YAML document). In some scenarios this may significantly reduce the memory footprint of
/// the decoded type.
public protocol AliasDereferencingStrategy: AnyObject {
    /// The stored exestential type of all AliasDereferencingStrategys
    typealias Value = (any Decodable)
    /// get and set cached references, keyed bo an Anchor
    subscript(_ key: Anchor) -> Value? { get set }
}

/// A AliasDereferencingStrategy which caches all values (even value-type values) in a Dictionary,
/// keyed by their Anchor.
/// For reference types, this strategy achieves reference coalescing
/// For value types, this strategy achieves short-cutting the decoding process when dereferencing aliases.
/// if the aliased structure is large, this may result in a time savings
public class BasicAliasDereferencingStrategy: AliasDereferencingStrategy {
    /// Create a new BasicAliasDereferencingStrategy
    public init() {}

    private var map: [Anchor: Value] = .init()

    /// get and set cached references, keyed bo an Anchor
    public subscript(_ key: Anchor) -> Value? {
        get { map[key] }
        set { map[key] = newValue }
    }
}

extension CodingUserInfoKey {
    internal static let aliasDereferencingStrategy = Self(rawValue: "aliasDereferencingStrategy")!
}
