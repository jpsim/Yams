//
//  Encoder.swift
//  Yams
//
//  Created by Norio Nomura on 5/2/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

/// `Codable`-style `Encoder` that can be used to encode an `Encodable` type to a YAML string using optional
/// user info mapping. Similar to `Foundation.JSONEncoder`.
public class YAMLEncoder {
    /// Options to use when encoding to YAML.
    public typealias Options = Emitter.Options

    /// Options to use when encoding to YAML.
    public var options = Options()

    /// Creates a `YAMLEncoder` instance.
    public init() {}

    /// Encode a value of type `T` to a YAML string.
    ///
    /// - parameter value:    Value to encode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to encode.
    ///
    /// - returns: The YAML string.
    ///
    /// - throws: `EncodingError` if something went wrong while encoding.
    public func encode<T: Swift.Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> String {
        do {
            var finalUserInfo = userInfo
            if let aliasingStrategy = options.redundancyAliasingStrategy {
                finalUserInfo[.redundancyAliasingStrategyKey] = aliasingStrategy
            }
            let encoder = _Encoder(userInfo: finalUserInfo, options: options)
            var container = encoder.singleValueContainer()
            try container.encode(value)
            try options.redundancyAliasingStrategy?.releaseAnchorReferences()
            return try serialize(node: encoder.node, options: options)
        } catch let error as EncodingError {
            throw error
        } catch {
            let description = "Unable to encode the given top-level value to YAML."
            let context = EncodingError.Context(codingPath: [],
                                                debugDescription: description,
                                                underlyingError: error)
            throw EncodingError.invalidValue(value, context)
        }
    }
}

private class _Encoder: Swift.Encoder {
    var node: Node = .unused

    init(
        userInfo: [CodingUserInfoKey: Any] = [:],
        codingPath: [CodingKey] = [],
        options: YAMLEncoder.Options
    ) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.options = options
    }

    // MARK: - Swift.Encoder Methods

    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let options: YAMLEncoder.Options

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        if canEncodeNewValue {
            node = Node([(Node, Node)](), .implicit, options.mappingStyle)
        } else {
            precondition(
                node.isMapping,
                "Attempt to push new keyed encoding container when already previously encoded at this path."
            )
        }
        return .init(_KeyedEncodingContainer<Key>(referencing: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        if canEncodeNewValue {
            node = Node([], .implicit, options.sequenceStyle)
        } else {
            precondition(
                node.isSequence,
                "Attempt to push new keyed encoding container when already previously encoded at this path."
            )
        }
        return _UnkeyedEncodingContainer(referencing: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer { return self }

    // MARK: -

    var mapping: Node.Mapping {
        get { return node.mapping ?? [:] }
        set { node.mapping = newValue }
    }

    var sequence: Node.Sequence {
        get { return node.sequence ?? [] }
        set { node.sequence = newValue }
    }

    /// create a new `_ReferencingEncoder` instance as `key` inheriting `userInfo`
    func encoder(for key: CodingKey) -> _ReferencingEncoder {
        return .init(referencing: self, key: key)
    }

    /// create a new `_ReferencingEncoder` instance at `index` inheriting `userInfo`
    func encoder(at index: Int) -> _ReferencingEncoder {
        return .init(referencing: self, at: index)
    }

    private var canEncodeNewValue: Bool { return node == .unused }
}

private class _ReferencingEncoder: _Encoder {
    private enum Reference { case mapping(String), sequence(Int) }

    private let encoder: _Encoder
    private let reference: Reference

    init(referencing encoder: _Encoder, key: CodingKey) {
        self.encoder = encoder
        reference = .mapping(key.stringValue)
        super.init(userInfo: encoder.userInfo,
                   codingPath: encoder.codingPath + [key],
                   options: encoder.options)
    }

    init(referencing encoder: _Encoder, at index: Int) {
        self.encoder = encoder
        reference = .sequence(index)
        super.init(userInfo: encoder.userInfo,
                   codingPath: encoder.codingPath + [_YAMLCodingKey(index: index)],
                   options: encoder.options)
    }

    deinit {
        switch reference {
        case .mapping(let key):
            encoder.node[key] = node
        case .sequence(let index):
            encoder.node[index] = node
        }
    }
}

private struct _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {

    private let encoder: _Encoder

    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    // MARK: - Swift.KeyedEncodingContainerProtocol Methods

    var codingPath: [CodingKey] { return encoder.codingPath }
    func encodeNil(forKey key: Key) throws { encoder.mapping[key.stringValue] = .null }
    func encode<T>(_ value: T, forKey key: Key) throws where T: YAMLEncodable { try encoder(for: key).encode(value) }
    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if let anchor = value as? Anchor, key.stringValue == Node.anchorKeyNode.string {
            encoder.node = encoder.node.setting(anchor: anchor)
        } else if let tag = value as? Tag, key.stringValue == Node.tagKeyNode.string {
            encoder.node = encoder.node.setting(tag: tag)
        } else {
            try encoder(for: key).encode(value)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        return encoder(for: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder(for: key).unkeyedContainer()
    }

    func superEncoder() -> Encoder { return encoder(for: _YAMLCodingKey.super) }
    func superEncoder(forKey key: Key) -> Encoder { return encoder(for: key) }

    // MARK: -

    private func encoder(for key: CodingKey) -> _ReferencingEncoder { return encoder.encoder(for: key) }
}

private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {
    private let encoder: _Encoder

    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    // MARK: - Swift.UnkeyedEncodingContainer Methods

    var codingPath: [CodingKey] { return encoder.codingPath }
    var count: Int { return encoder.sequence.count }
    func encodeNil()           throws { encoder.sequence.append(.null) }
    func encode<T>(_ value: T) throws where T: YAMLEncodable { try currentEncoder.encode(value) }
    func encode<T>(_ value: T) throws where T: Encodable { try currentEncoder.encode(value) }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        return currentEncoder.container(keyedBy: type)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { return currentEncoder.unkeyedContainer() }
    func superEncoder() -> Encoder { return currentEncoder }

    // MARK: -

    private var currentEncoder: _ReferencingEncoder {
        defer { encoder.sequence.append("") }
        return encoder.encoder(at: count)
    }
}

extension _Encoder: SingleValueEncodingContainer {

    // MARK: - Swift.SingleValueEncodingContainer Methods

    func encodeNil() throws {
        assertCanEncodeNewValue()
        node = .null
    }

    func encode<T>(_ value: T) throws where T: YAMLEncodable {
        assertCanEncodeNewValue()
        try encode(yamlEncodable: value)
    }

    private func encode(yamlEncodable encodable: YAMLEncodable) throws {
        func encodeNode() {
            node = encodable.box(options: options)
            if let stringValue = encodable as? (any StringProtocol), stringValue.contains("\n") {
                node.scalar?.style = options.newLineScalarStyle
            }
        }
        try resolveAlias(for: encodable, encode: encodeNode)
    }

    private func resolveAlias(for encodable: any Encodable, encode: () throws -> Void) throws {
        if let redundancyAliasingStrategy = userInfo[.redundancyAliasingStrategyKey] as? RedundancyAliasingStrategy {
            switch try redundancyAliasingStrategy.alias(for: encodable) {
            case let .anchor(anchor):
                self.node = self.node.setting(anchor: anchor) // a hack
                try encode()

                guard self.node.anchor != anchor else {
                    return // nothing left to do
                }

                if let orphanedAnchor = self.node.anchor {
                    // our sub-tree was a single value container which declared an anchor
                    // that anchor will not be represented in the final tree
                    // because `anchor` is the prevailing value in this context
                    // therefore the encoding strategy must remit the anchor,
                    // allowing it to be deallocated, so no aliases can be made to it.
                    try redundancyAliasingStrategy.remit(anchor: orphanedAnchor)
                }

                self.node = self.node.setting(anchor: anchor)

            case let .alias(anchor):
                if self.node.anchor == nil {
                    self.node = .alias(.init(anchor))
                } else {
                    // This node can't be both an anchor and an alias.
                    // The ambiguity arises from single-value container types
                    // like RawRepresentable types. In this case, we encode
                    // normally, allowing the exiting anchor to remain.
                    fallthrough
                }
            case .none:
                try encode()
            }
        } else {
            try encode()
        }
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        assertCanEncodeNewValue()
        if let encodable = value as? YAMLEncodable {
            try encode(yamlEncodable: encodable)
        } else {
            try resolveAlias(for: value) {
                try value.encode(to: self)
            }
        }
    }

    // MARK: -

    /// Asserts that a single value can be encoded at the current coding path
    /// (i.e. that one has not already been encoded through this container).
    /// `preconditionFailure()`s if one cannot be encoded.
    private func assertCanEncodeNewValue() {
        precondition(
            canEncodeNewValue,
            "Attempt to encode value through single value container when previously value already encoded."
        )
    }
}

// MARK: - CodingKey for `_UnkeyedEncodingContainer`, `_UnkeyedDecodingContainer`, `superEncoder` and `superDecoder`

struct _YAMLCodingKey: CodingKey { // swiftlint:disable:this type_name
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    static let `super` = _YAMLCodingKey(stringValue: "super")!
}

// MARK: -

private extension Node {
    static var null: Node { Node("null", Tag(.null)) }
    static var unused: Node { Node("", .unused) }
}

private extension Tag {
    static var unused: Tag { Tag(.unused) }
}

private extension Tag.Name {
    static let unused: Tag.Name = "tag:yams.encoder:unused"
}

private func serialize(node: Node, options: Emitter.Options) throws -> String {
    return try serialize(
        nodes: [node],
        canonical: options.canonical,
        indent: options.indent,
        width: options.width,
        allowUnicode: options.allowUnicode,
        lineBreak: options.lineBreak,
        explicitStart: options.explicitStart,
        explicitEnd: options.explicitEnd,
        version: options.version,
        sortKeys: options.sortKeys)
}
