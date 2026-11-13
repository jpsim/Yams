//
//  RedundancyAliasingStrategy.swift
//  Yams
//
//  Created by Adora Lynch on 8/15/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

/// An enum indicating the outcome of a `RedundancyAliasingStrategy`
public enum RedundancyAliasingOutcome {
    /// encoder will encode an Anchor
    case anchor(Anchor)
    /// encoder will encode an alias to an anchor which should already have been specified.
    case alias(Anchor)
    /// encoder will encode without an anchor or an alias
    case none
}

/// A class-bound protocol which implements a strategy for detecting aliasable values in a YAML document.
/// Implementations should return RedundancyAliasingOutcome.anchor(...) for the first occurrence of a value.
/// Subsequent occurrences of the same value (where same-ness is defined by the implementation) should
/// return RedundancyAliasingOutcome.alias(...) where the contained Anchor has the same value as the previously
/// returned RedundancyAliasingOutcome.anchor(...). Its the identity of the Anchor values returned that ultimately
/// informs the YAML encoder when to use aliases.
/// N,B. It is essential that implementations release all references to Anchors which are created by this type
/// when releaseAnchorReferences() is called by the Encoder. After this call the implementation will no longer be
/// referenced by the Encoder and will itself be released.
public protocol RedundancyAliasingStrategy: AnyObject {

    /// Implementations should return RedundancyAliasingOutcome.anchor(...) for the first occurrence of a value.
    /// Subsequent occurrences of the same value (where same-ness is defined by the implementation) should
    /// return RedundancyAliasingOutcome.alias(...) where the contained Anchor has the same value as the previously
    /// returned RedundancyAliasingOutcome.anchor(...). Its the identity of the Anchor values returned that ultimately
    /// informs the YAML encoder when to use aliases.
    func alias(for encodable: any Encodable) throws -> RedundancyAliasingOutcome

    /// It is essential that implementations release all references to Anchors which are created by this type
    /// when releaseAnchorReferences() is called by the Encoder. After this call, the implementation will no longer be
    /// referenced by the Encoder and will itself be released.

    func releaseAnchorReferences() throws

    /// Implementations must remove all reference to the supplied anchor, permitting it to be deallocated.
    func remit(anchor: Anchor) throws
}

/// An implementation of RedundancyAliasingStrategy that defines alias-ability by Hashable-Equality.
/// i.e. if two values are Hashable-Equal, they will be aliased in the resultant YML document.
public class HashableAliasingStrategy: RedundancyAliasingStrategy {
    private var hashesToAliases: [AnyHashable: Anchor] = [:]

    let uniqueAliasProvider = UniqueAliasProvider()

    /// Initialize a new HashableAliasingStrategy
    public init() {}

    public func alias(for encodable: any Encodable) throws -> RedundancyAliasingOutcome {
        guard let hashable = encodable as? any Hashable & Encodable else {
            return .none
        }
        return try alias(for: hashable)
    }

    private func alias(for hashable: any Hashable & Encodable) throws -> RedundancyAliasingOutcome {
        let anyHashable = AnyHashable(hashable)
        if let existing = hashesToAliases[anyHashable] {
            return .alias(existing)
        } else {
            let newAlias = uniqueAliasProvider.uniqueAlias(for: hashable)
            hashesToAliases[anyHashable] = newAlias
            return .anchor(newAlias)
        }
    }

    public func releaseAnchorReferences() throws {
        hashesToAliases.removeAll()
        uniqueAliasProvider.releaseAnchorReferences()
    }

    public func remit(anchor: Anchor) throws {
        hashesToAliases.remove(keysForValue: anchor)
        uniqueAliasProvider.remit(anchor: anchor)
    }
}

/// An implementation of RedundancyAliasingStrategy that defines alias-ability by the coded representation
/// of the values. i.e. if two values encode to exactly the same, they will be aliased in the resultant YML
/// document even if the values themselves are of different types
public class StrictEncodableAliasingStrategy: RedundancyAliasingStrategy {
    private var codedToAliases: [String: Anchor] = [:]

    let uniqueAliasProvider = UniqueAliasProvider()

    /// Initialize a new StrictEncodableAliasingStrategy
    public init() {}

    private let encoder = YAMLEncoder()

    public func alias(for encodable: any Encodable) throws -> RedundancyAliasingOutcome {
        let coded = try encoder.encode(encodable)
        if let existing = codedToAliases[coded] {
            return .alias(existing)
        } else {
            let newAlias = uniqueAliasProvider.uniqueAlias(for: encodable)
            codedToAliases[coded] = newAlias
            return .anchor(newAlias)
        }
    }

    public func releaseAnchorReferences() throws {
        codedToAliases.removeAll()
        uniqueAliasProvider.releaseAnchorReferences()
    }

    public func remit(anchor: Anchor) throws {
        codedToAliases.remove(keysForValue: anchor)
        uniqueAliasProvider.remit(anchor: anchor)
    }
}

class UniqueAliasProvider {
    private var counter = 0
    private var issuedAnchorNames: Set<String> = []
    private var anchorNames: [ObjectIdentifier: String] = [:]

    func uniqueAlias(for encodable: any Encodable) -> Anchor {
        if let anchorProviding = encodable as? YamlAnchorProviding,
           let anchor = anchorProviding.yamlAnchor {
            if !issuedAnchorNames.contains(anchor.rawValue) {
                return issue(anchor: anchor)
            }
        }

        repeat {
            counter += 1
        } while issuedAnchorNames.contains(String(counter))
        return issue(anchor: Anchor(rawValue: String(counter)))
    }

    func releaseAnchorReferences() {
        issuedAnchorNames.removeAll()
        anchorNames.removeAll()
    }

    func remit(anchor: Anchor) {
        guard let rawValue = anchorNames.removeValue(forKey: ObjectIdentifier(anchor)) else {
            return
        }
        issuedAnchorNames.remove(rawValue)
    }

    private func issue(anchor: Anchor) -> Anchor {
        issuedAnchorNames.insert(anchor.rawValue)
        anchorNames[ObjectIdentifier(anchor)] = anchor.rawValue
        return anchor
    }
}

extension CodingUserInfoKey {
    internal static let redundancyAliasingStrategyKey = Self(rawValue: "redundancyAliasingStrategy")!
}

fileprivate extension Dictionary where Value: AnyObject {

    func removing(keysForValue: Value) -> Self {
        var mutable = Self(minimumCapacity: self.count)
        for (key, value) in self where value !== keysForValue {
            mutable[key] = value
        }
        return mutable
    }

    mutating func remove(keysForValue value: Value) {
        self = self.removing(keysForValue: value)
    }
}
