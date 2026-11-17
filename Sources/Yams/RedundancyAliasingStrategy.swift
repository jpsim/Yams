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
/// returned RedundancyAliasingOutcome.anchor(...). The identity of the Anchor values returned ultimately
/// informs the YAML encoder when to use aliases. When a custom strategy obtains an Anchor from
/// `UniqueAliasProvider`, that returned Anchor instance is authoritative and must be retained and used in
/// the strategy's outcomes.
/// N,B. It is essential that implementations release all references to Anchors which are created by this type
/// when releaseAnchorReferences() is called by the Encoder. After this call the implementation will no longer be
/// referenced by the Encoder and will itself be released.
public protocol RedundancyAliasingStrategy: AnyObject {

    /// Implementations should return RedundancyAliasingOutcome.anchor(...) for the first occurrence of a value.
    /// Subsequent occurrences of the same value (where same-ness is defined by the implementation) should
    /// return RedundancyAliasingOutcome.alias(...) where the contained Anchor has the same value as the previously
    /// returned RedundancyAliasingOutcome.anchor(...). The identity of the Anchor values returned ultimately
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

/// A helper for assigning unique YAML anchor names to custom
/// `RedundancyAliasingStrategy` implementations.
///
/// Built-in strategies use `uniqueAlias(for:)`, which preserves their existing behavior: a free
/// `YamlAnchorProviding` anchor is used as-is and a colliding preferred anchor follows the monotonic
/// numeric path. Custom strategies can opt in to preferred-name suffixing with
/// `uniqueAlias(preferredAnchor:)`. The `Anchor` instances returned by this helper are authoritative;
/// custom strategies must retain and return those same instances in their
/// `RedundancyAliasingOutcome` values.
public final class UniqueAliasProvider {
    private var counter = 0
    private var issuedAnchorNames: Set<String> = []
    private var issuedAnchors: [ObjectIdentifier: Anchor] = [:]

    /// Creates a provider with an empty set of active anchor reservations.
    public init() {}

    /// Returns an anchor for an encodable value using the built-in strategy behavior.
    ///
    /// If `encodable` provides a preferred anchor and that raw value is not currently reserved,
    /// the preferred anchor is returned unchanged. Otherwise, the next available monotonic
    /// numeric anchor is returned.
    public func uniqueAlias(for encodable: any Encodable) -> Anchor {
        if let anchorProviding = encodable as? YamlAnchorProviding,
           let anchor = anchorProviding.yamlAnchor {
            if !issuedAnchorNames.contains(anchor.rawValue) {
                return issue(anchor: anchor)
            }
        }

        return uniqueAlias(preferredAnchor: nil)
    }

    /// Returns a unique anchor for an optional preferred anchor name.
    ///
    /// Preferred-name matching is case-sensitive on `Anchor.rawValue`. A free preferred anchor
    /// is returned unchanged and reserved. If its raw value is already reserved, new anchors are
    /// generated by appending `_2`, `_3`, and so on, skipping every currently reserved candidate,
    /// including names reserved independently with this method. Passing `nil` uses the existing
    /// monotonic numeric counter and skips all active reservations.
    ///
    /// The returned `Anchor` instance is authoritative. Custom aliasing strategies must retain
    /// and use that exact instance in their aliasing outcomes.
    public func uniqueAlias(preferredAnchor: Anchor?) -> Anchor {
        guard let preferredAnchor else {
            return uniqueNumericAlias()
        }

        guard issuedAnchorNames.contains(preferredAnchor.rawValue) else {
            return issue(anchor: preferredAnchor)
        }

        var suffix = 2
        while issuedAnchorNames.contains("\(preferredAnchor.rawValue)_\(suffix)") {
            suffix += 1
        }
        return issue(anchor: Anchor(rawValue: "\(preferredAnchor.rawValue)_\(suffix)"))
    }

    /// Releases all active anchor reservations and retained anchor identities.
    ///
    /// The numeric counter remains monotonic and is not reset.
    public func releaseAnchorReferences() {
        issuedAnchorNames.removeAll()
        issuedAnchors.removeAll()
    }

    /// Releases the reservation for an issued anchor only when `anchor` is the exact issued instance.
    ///
    /// A different `Anchor` instance with the same raw value is ignored.
    public func remit(anchor: Anchor) {
        guard let issuedAnchor = issuedAnchors[ObjectIdentifier(anchor)], issuedAnchor === anchor else {
            return
        }
        issuedAnchors.removeValue(forKey: ObjectIdentifier(anchor))
        issuedAnchorNames.remove(anchor.rawValue)
    }

    private func uniqueNumericAlias() -> Anchor {
        repeat {
            counter += 1
        } while issuedAnchorNames.contains(String(counter))
        return issue(anchor: Anchor(rawValue: String(counter)))
    }

    private func issue(anchor: Anchor) -> Anchor {
        issuedAnchorNames.insert(anchor.rawValue)
        issuedAnchors[ObjectIdentifier(anchor)] = anchor
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
