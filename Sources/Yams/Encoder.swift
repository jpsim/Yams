//
//  Encoder.swift
//  Yams
//
//  Created by Norio Nomura on 5/2/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import Foundation

public class YAMLEncoder {
    public var options = Options()
    public init() {}
    public func encode<T: Swift.Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> String {
        do {
            let encoder = _Encoder(options: options, userInfo: userInfo)
            var container = encoder.singleValueContainer()
            try container.encode(value)
            return try serialize(node: encoder.node, options: options.emitterOptions)
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

    public struct Options {
        /// Set if the output should be in the "canonical" format as in the YAML specification.
        public var canonical: Bool = false
        /// Set the intendation increment.
        public var indent: Int = 0
        /// Set the preferred line width. -1 means unlimited.
        public var width: Int = 0
        /// Set if unescaped non-ASCII characters are allowed.
        public var allowUnicode: Bool = false
        /// Set the preferred line break.
        public var lineBreak: Emitter.LineBreak = .ln

        // internal since we don't know if these should be exposed.
        var explicitStart: Bool = false
        var explicitEnd: Bool = false

        /// The %YAML directive value or nil
        public var version: (major: Int, minor: Int)?

        /// Set if emitter should sort keys in lexicographic order.
        public var sortKeys: Bool = false

        /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
        public var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys

        fileprivate var emitterOptions: Emitter.Options {
            return .init(canonical: canonical, indent: indent, width: width, allowUnicode: allowUnicode,
                         lineBreak: lineBreak, version: version, sortKeys: sortKeys)
        }
    }

    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to YAML payload.
        case convertToSnakeCase

        /// Provide a custom conversion to the key in the encoded YAML from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this
        /// key within the payload). The returned key is used in place of the last component in the coding path before
        /// encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
    }
}

extension YAMLEncoder.Options {
    // initializer without exposing internal properties
    public init(canonical: Bool = false, indent: Int = 0, width: Int = 0, allowUnicode: Bool = false,
                lineBreak: Emitter.LineBreak = .ln, version: (major: Int, minor: Int)? = nil, sortKeys: Bool = false,
                keyEncodingStrategy: YAMLEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        self.canonical = canonical
        self.indent = indent
        self.width = width
        self.allowUnicode = allowUnicode
        self.lineBreak = lineBreak
        self.version = version
        self.sortKeys = sortKeys
        self.keyEncodingStrategy = keyEncodingStrategy
    }
}

class _Encoder: Swift.Encoder { // swiftlint:disable:this type_name
    var node: Node = .unused
    typealias Options = YAMLEncoder.Options
    let options: Options

    init(options: Options, userInfo: [CodingUserInfoKey: Any] = [:], codingPath: [CodingKey] = []) {
        self.options = options
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    // MARK: - Swift.Encoder Methods

    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        if canEncodeNewValue {
            node = [:]
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
            node = []
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

    fileprivate var mapping: Node.Mapping {
        get { return node.mapping ?? [:] }
        set { node.mapping = newValue }
    }

    fileprivate var sequence: Node.Sequence {
        get { return node.sequence ?? [] }
        set { node.sequence = newValue }
    }

    /// Encode `ScalarRepresentable` to `node`
    fileprivate func represent<T: ScalarRepresentable>(_ value: T) throws {
        assertCanEncodeNewValue()
        node = try box(value)
    }

    fileprivate func represent<T: ScalarRepresentableCustomizedForCodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        node = value.representedForCodable()
    }

    /// create a new `_ReferencingEncoder` instance as `key` inheriting `userInfo`
    fileprivate func encoder(for key: CodingKey) -> _ReferencingEncoder {
        return .init(referencing: self, key: key)
    }

    /// create a new `_ReferencingEncoder` instance at `index` inheriting `userInfo`
    fileprivate func encoder(at index: Int) -> _ReferencingEncoder {
        return .init(referencing: self, at: index)
    }

    /// Create `Node` from `ScalarRepresentable`.
    /// Errors throwed by `ScalarRepresentable` will be boxed into `EncodingError`
    fileprivate func box(_ representable: ScalarRepresentable) throws -> Node {
        do {
            return try representable.represented()
        } catch {
            let context = EncodingError.Context(codingPath: codingPath,
                                                debugDescription: "Unable to encode the given value to YAML.",
                                                underlyingError: error)
            throw EncodingError.invalidValue(representable, context)
        }
    }

    fileprivate var canEncodeNewValue: Bool { return node == .unused }

    /// Returns `String` applied `KeyEncodingStrategy`
    fileprivate func convert(_ key: CodingKey) -> String {
        switch options.keyEncodingStrategy {
        case .useDefaultKeys: return key.stringValue
        case .convertToSnakeCase: return key.stringValue.snakecased
        case let .custom(converter): return converter(codingPath + [key]).stringValue
        }
    }
}

class _ReferencingEncoder: _Encoder { // swiftlint:disable:this type_name
    private enum Reference { case mapping(String), sequence(Int) }

    private let encoder: _Encoder
    private let reference: Reference

    fileprivate init(referencing encoder: _Encoder, key: CodingKey) {
        self.encoder = encoder
        reference = .mapping(encoder.convert(key))
        super.init(options: encoder.options, userInfo: encoder.userInfo, codingPath: encoder.codingPath + [key])
    }

    fileprivate init(referencing encoder: _Encoder, at index: Int) {
        self.encoder = encoder
        reference = .sequence(index)
        super.init(options: encoder.options,
                   userInfo: encoder.userInfo,
                   codingPath: encoder.codingPath + [_YAMLCodingKey(index: index)])
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

struct _KeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol { // swiftlint:disable:this type_name
    typealias Key = K

    private let encoder: _Encoder

    fileprivate init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    // MARK: - Swift.KeyedEncodingContainerProtocol Methods

    var codingPath: [CodingKey] { return encoder.codingPath }
    func encodeNil(forKey key: Key)               throws { encoder.mapping[encoder.convert(key)] = .null }
    func encode(_ value: Bool, forKey key: Key)   throws { try encoder(for: key).represent(value) }
    func encode(_ value: Int, forKey key: Key)    throws { try encoder(for: key).represent(value) }
    func encode(_ value: Int8, forKey key: Key)   throws { try encoder(for: key).represent(value) }
    func encode(_ value: Int16, forKey key: Key)  throws { try encoder(for: key).represent(value) }
    func encode(_ value: Int32, forKey key: Key)  throws { try encoder(for: key).represent(value) }
    func encode(_ value: Int64, forKey key: Key)  throws { try encoder(for: key).represent(value) }
    func encode(_ value: UInt, forKey key: Key)   throws { try encoder(for: key).represent(value) }
    func encode(_ value: UInt8, forKey key: Key)  throws { try encoder(for: key).represent(value) }
    func encode(_ value: UInt16, forKey key: Key) throws { try encoder(for: key).represent(value) }
    func encode(_ value: UInt32, forKey key: Key) throws { try encoder(for: key).represent(value) }
    func encode(_ value: UInt64, forKey key: Key) throws { try encoder(for: key).represent(value) }
    func encode(_ value: Float, forKey key: Key)  throws { try encoder(for: key).represent(value) }
    func encode(_ value: Double, forKey key: Key) throws { try encoder(for: key).represent(value) }
    func encode(_ value: String, forKey key: Key) throws { encoder.mapping[encoder.convert(key)] = Node(value) }
    func encode<T>(_ value: T, forKey key: Key)   throws where T: Encodable { try encoder(for: key).encode(value) }

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

struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer { // swiftlint:disable:this type_name
    private let encoder: _Encoder

    fileprivate init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    // MARK: - Swift.UnkeyedEncodingContainer Methods

    var codingPath: [CodingKey] { return encoder.codingPath }
    var count: Int { return encoder.sequence.count }
    func encodeNil()             throws { encoder.sequence.append(.null) }
    func encode(_ value: Bool)   throws { try currentEncoder.represent(value) }
    func encode(_ value: Int)    throws { try currentEncoder.represent(value) }
    func encode(_ value: Int8)   throws { try currentEncoder.represent(value) }
    func encode(_ value: Int16)  throws { try currentEncoder.represent(value) }
    func encode(_ value: Int32)  throws { try currentEncoder.represent(value) }
    func encode(_ value: Int64)  throws { try currentEncoder.represent(value) }
    func encode(_ value: UInt)   throws { try currentEncoder.represent(value) }
    func encode(_ value: UInt8)  throws { try currentEncoder.represent(value) }
    func encode(_ value: UInt16) throws { try currentEncoder.represent(value) }
    func encode(_ value: UInt32) throws { try currentEncoder.represent(value) }
    func encode(_ value: UInt64) throws { try currentEncoder.represent(value) }
    func encode(_ value: Float)  throws { try currentEncoder.represent(value) }
    func encode(_ value: Double) throws { try currentEncoder.represent(value) }
    func encode(_ value: String) throws { encoder.sequence.append(Node(value)) }
    func encode<T>(_ value: T)   throws where T: Encodable { try currentEncoder.encode(value) }

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

    func encode(_ value: Bool)   throws { try represent(value) }
    func encode(_ value: Int)    throws { try represent(value) }
    func encode(_ value: Int8)   throws { try represent(value) }
    func encode(_ value: Int16)  throws { try represent(value) }
    func encode(_ value: Int32)  throws { try represent(value) }
    func encode(_ value: Int64)  throws { try represent(value) }
    func encode(_ value: UInt)   throws { try represent(value) }
    func encode(_ value: UInt8)  throws { try represent(value) }
    func encode(_ value: UInt16) throws { try represent(value) }
    func encode(_ value: UInt32) throws { try represent(value) }
    func encode(_ value: UInt64) throws { try represent(value) }
    func encode(_ value: Float)  throws { try represent(value) }
    func encode(_ value: Double) throws { try represent(value) }

    func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        node = Node(value)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        assertCanEncodeNewValue()
        if let customized = value as? ScalarRepresentableCustomizedForCodable {
            node = customized.representedForCodable()
        } else if let representable = value as? ScalarRepresentable {
            node = try box(representable)
        } else {
            try value.encode(to: self)
        }
    }

    // MARK: -

    /// Asserts that a single value can be encoded at the current coding path
    /// (i.e. that one has not already been encoded through this container).
    /// `preconditionFailure()`s if one cannot be encoded.
    fileprivate func assertCanEncodeNewValue() {
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
    static let null = Node("null", Tag(.null))
    static let unused = Node("", .unused)
}

private extension Tag {
    static let unused = Tag(.unused)
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
// swiftlint:disable:this file_length
