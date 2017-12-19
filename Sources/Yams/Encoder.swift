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

    /// Configuration options to use when emitting YAML.
    public struct Options {
        /// Set if the output should be in the "canonical" format described in the YAML specification.
        public var canonical: Bool = false
        /// Set the indentation value.
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

        /// The `%YAML` directive value or nil.
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
    /// Create `YAMLEncoder.Options` with the specified values.
    ///
    /// - parameter canonical:     Set if the output should be in the "canonical" format described in the YAML
    ///                            specification.
    /// - parameter indent:        Set the indentation value.
    /// - parameter width:         Set the preferred line width. -1 means unlimited.
    /// - parameter allowUnicode:  Set if unescaped non-ASCII characters are allowed.
    /// - parameter lineBreak:     Set the preferred line break.
    /// - parameter explicitStart: Explicit document start `---`.
    /// - parameter explicitEnd:   Explicit document end `...`.
    /// - parameter version:       The `%YAML` directive value or nil.
    /// - parameter sortKeys:      Set if emitter should sort keys in lexicographic order.
    public init(canonical: Bool = false, indent: Int = 0, width: Int = 0, allowUnicode: Bool = false,
                lineBreak: Emitter.LineBreak = .ln, version: (major: Int, minor: Int)? = nil,
                sortKeys: Bool = false,
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

private class _Encoder: Swift.Encoder {
    typealias Options = YAMLEncoder.Options
    let options: Options
    var node: Node = .unused

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

    /// Returns `String` applied `KeyEncodingStrategy`
    fileprivate func convert(_ key: CodingKey) -> String {
        switch options.keyEncodingStrategy {
        case .useDefaultKeys: return key.stringValue
        case .convertToSnakeCase: return key.stringValue.snakecased
        case let .custom(converter): return converter(codingPath + [key]).stringValue
        }
    }
}

private class _ReferencingEncoder: _Encoder {
    private enum Reference { case mapping(String), sequence(Int) }

    private let encoder: _Encoder
    private let reference: Reference

    init(referencing encoder: _Encoder, key: CodingKey) {
        self.encoder = encoder
        reference = .mapping(encoder.convert(key))
        super.init(options: encoder.options, userInfo: encoder.userInfo, codingPath: encoder.codingPath + [key])
    }

    init(referencing encoder: _Encoder, at index: Int) {
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

private struct _KeyedEncodingContainer<Key: CodingKey> : KeyedEncodingContainerProtocol {

    private let encoder: _Encoder

    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    // MARK: - Swift.KeyedEncodingContainerProtocol Methods

    var codingPath: [CodingKey] { return encoder.codingPath }
    func encodeNil(forKey key: Key) throws { encoder.mapping[encoder.convert(key)] = .null }
    func encode<T>(_ value: T, forKey key: Key) throws where T: YAMLEncodable { try encoder(for: key).encode(value) }
    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable { try encoder(for: key).encode(value) }

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
        node = value.box()
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        assertCanEncodeNewValue()
        if let encodable = value as? YAMLEncodable {
            node = encodable.box()
        } else {
            try value.encode(to: self)
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
