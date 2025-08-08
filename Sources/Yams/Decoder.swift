//
//  Decoder.swift
//  Yams
//
//  Created by Norio Nomura on 5/6/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import Foundation

/// `Codable`-style `Decoder` that can be used to decode a `Decodable` type from a given `String` and optional
/// user info mapping. Similar to `Foundation.JSONDecoder`.
public class YAMLDecoder {
    /// Options to use when decoding from YAML.
    public struct Options {
        /// Create `YAMLDecoder.Options` with the specified values.
        public init(encoding: Parser.Encoding = .default,
                    aliasDereferencingStrategy: AliasDereferencingStrategy? = nil) {
            self.encoding = encoding
            self.aliasDereferencingStrategy = aliasDereferencingStrategy
        }

        /// Encoding
        public var encoding: Parser.Encoding = .default

        /// Alias dereferencing strategy to use when decoding. Defaults to nil
        public var aliasDereferencingStrategy: AliasDereferencingStrategy?
    }

    /// Options to use when decoding from YAML.
    public var options = Options()

    /// Creates a `YAMLDecoder` instance.
    ///
    /// - parameter encoding: String encoding,
    public convenience init(encoding: Parser.Encoding) {
        self.init()
        self.options.encoding = encoding
    }

    /// Creates a `YAMLDecoder` instance.
    public init() {}

    /// Decode a `Decodable` type from a given `Node` and optional user info mapping.
    ///
    /// - parameter type:    `Decodable` type to decode.
    /// - parameter node:     YAML Node to decode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to decode.
    ///
    /// - returns: Returns the decoded type `T`.
    ///
    /// - throws: `DecodingError` or `YamlError` if something went wrong while decoding.
    public func decode<T>(_ type: T.Type = T.self,
                          from node: Node,
                          userInfo: [CodingUserInfoKey: Any] = [:]) throws -> T where T: Swift.Decodable {
        let decoder = _decoder(from: node, userInfo: userInfo)
        let container = try decoder.singleValueContainer()
        return try container.decode(type)
    }

    /// Decode a `Decodable` type from a given `String` and optional user info mapping.
    ///
    /// - parameter type:    `Decodable` type to decode.
    /// - parameter yaml:     YAML string to decode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to decode.
    ///
    /// - returns: Returns the decoded type `T`.
    ///
    /// - throws: `DecodingError` or `YamlError` if something went wrong while decoding.
    public func decode<T>(_ type: T.Type = T.self,
                          from yaml: String,
                          userInfo: [CodingUserInfoKey: Any] = [:]) throws -> T where T: Swift.Decodable {
        let decoded: T = try processYamlNode(type, from: yaml) { [type, userInfo] node in
            try self.decode(type, from: node, userInfo: userInfo)
        }

        return decoded
    }

    /// Decode a `Decodable` type from a given `Data` and optional user info mapping.
    ///
    /// - parameter type:    `Decodable` type to decode.
    /// - parameter yaml:     YAML data to decode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to decode.
    ///
    /// - returns: Returns the decoded type `T`.
    ///
    /// - throws: `DecodingError` or `YamlError` if something went wrong while decoding.
    public func decode<T>(_ type: T.Type = T.self,
                          from yamlData: Data,
                          userInfo: [CodingUserInfoKey: Any] = [:]) throws -> T where T: Swift.Decodable {
        guard let yamlString = String(data: yamlData, encoding: options.encoding.swiftStringEncoding) else {
            throw YamlError.dataCouldNotBeDecoded(encoding: options.encoding.swiftStringEncoding)
        }

        return try decode(type, from: yamlString, userInfo: userInfo)
    }

    /// Encoding
    @available(*, deprecated, renamed: "options.encoding")
    public var encoding: Parser.Encoding {
        options.encoding
    }
}

extension YAMLDecoder {
    /// Constructs a `_Decoder` referencing given YAML node to decode with a provided user info.
    ///
    /// - Parameters:
    ///   - node: YAML Node to decode.
    ///   - userInfo: Additional key/values which can be used when looking up keys to decode.
    ///
    /// - Returns: A constructed `_Decoder` instance.
    ///
    /// - Note: This is a single `_Decoder` constructor for decoding `Decodable`
    ///         and `DecodableWithConfiguration` objects.
    private func _decoder(from node: Node, userInfo: [CodingUserInfoKey: Any]) -> _Decoder {
        var finalUserInfo = userInfo
        if let dealiasingStrategy = options.aliasDereferencingStrategy {
            finalUserInfo[.aliasDereferencingStrategy] = dealiasingStrategy
        }

        let decoder = _Decoder(referencing: node, userInfo: finalUserInfo)

        return decoder
    }

    /// Returns a value of the type you specify, decoded from a YAML object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML object.
    ///   - yaml: The YAML object `String` to process.
    ///   - userInfo: Additional key/values which can be used when looking up keys to decode.
    ///   - block: A block to decode a given object type from the YAML node with a given user info.
    ///     Block takes 1 argument:
    ///     - `node`: The YAML node to process.
    ///
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    ///
    /// - Note: This is a single parser function for decoding `Decodable` and `DecodableWithConfiguration` objects.
    private func processYamlNode<T>(
        _ type: T.Type,
        from yaml: String,
        with block: (_ node: Node) throws -> T
    ) throws -> T {
        do {
            let parser = try Parser(yaml: yaml, resolver: Resolver([.merge]), encoding: options.encoding)
            // ^ the parser holds the references to Anchors while parsing,
            return try withExtendedLifetime(parser) {
                // ^ so we hold an explicit reference to the parser during decoding
                let node = try parser.singleRoot() ?? ""
                // ^ nodes only have weak references to Anchors (the Anchors would disappear if not held by the parser)
                return try block(node)
                // ^ if the decoded type or contained types are YamlAnchorCoding,
                // those types have taken ownership of Anchors.
                // Otherwise the Anchors are deallocated when this function exits just like Tag and Mark
            }
        } catch let error as DecodingError {
            throw error
        } catch {
            throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                    debugDescription: "The given data was not valid YAML.",
                                                    underlyingError: error))
        }
    }
}

private struct _Decoder: Decoder {

    fileprivate let node: Node

    init(referencing node: Node, userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
        self.node = node
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    // MARK: - Swift.Decoder Methods

    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard let mapping = node.mapping?.flatten() else {
            throw _typeMismatch(at: codingPath, expectation: Node.Mapping.self, reality: node)
        }
        return .init(_KeyedDecodingContainer<Key>(decoder: self, wrapping: mapping))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let sequence = node.sequence else {
            throw _typeMismatch(at: codingPath, expectation: Node.Sequence.self, reality: node)
        }
        return _UnkeyedDecodingContainer(decoder: self, wrapping: sequence)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer { return self }

    // MARK: -

    /// create a new `_Decoder` instance referencing `node` as `key` inheriting `userInfo`
    func decoder(referencing node: Node, `as` key: CodingKey) -> _Decoder {
        return .init(referencing: node, userInfo: userInfo, codingPath: codingPath + [key])
    }

    /// returns `Node.Scalar` or throws `DecodingError.typeMismatch`
    private func scalar() throws -> Node.Scalar {
        switch node {
        case .scalar(let scalar):
            return scalar
        case .mapping(let mapping):
            throw _typeMismatch(at: codingPath, expectation: Node.Scalar.self, reality: mapping)
        case .sequence(let sequence):
            throw _typeMismatch(at: codingPath, expectation: Node.Scalar.self, reality: sequence)
        case .alias(let alias):
            throw _typeMismatch(at: codingPath, expectation: Node.Scalar.self, reality: alias)
        }
    }
}

private struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

    private let decoder: _Decoder
    private let mapping: Node.Mapping

    init(decoder: _Decoder, wrapping mapping: Node.Mapping) {
        self.decoder = decoder

        let keys = mapping.keys

        let decodeAnchor: Anchor?
        let decodeTag: Tag?

        if let anchor = mapping.anchor, keys.contains(.anchorKeyNode) == false {
            decodeAnchor = anchor
        } else {
            decodeAnchor = nil
        }

        if mapping.tag.name != .implicit && keys.contains(.tagKeyNode) == false {
            decodeTag = mapping.tag
        } else {
            decodeTag = nil
        }

        switch (decodeAnchor, decodeTag) {
        case (nil, nil):
            self.mapping = mapping
        case (let anchor?, nil):
            var mutableMapping = mapping
            mutableMapping[.anchorKeyNode] = .scalar(.init(anchor.rawValue))
            self.mapping = mutableMapping
        case (nil, let tag?):
            var mutableMapping = mapping
            mutableMapping[.tagKeyNode] = .scalar(.init(tag.name.rawValue))
            self.mapping = mutableMapping
        case let (anchor?, tag?):
            var mutableMapping = mapping
            mutableMapping[.anchorKeyNode] = .scalar(.init(anchor.rawValue))
            mutableMapping[.tagKeyNode] = .scalar(.init(tag.name.rawValue))
            self.mapping = mutableMapping
        }
    }

    // MARK: - Swift.KeyedDecodingContainerProtocol Methods

    var codingPath: [CodingKey] { return decoder.codingPath }
    var allKeys: [Key] {
        return mapping.keys
            .filter { $0 != .anchorKeyNode && $0 != .tagKeyNode }
            .compactMap { $0.string.flatMap(Key.init(stringValue:)) }
    }
    func contains(_ key: Key) -> Bool { return mapping[key.stringValue] != nil }

    func decodeNil(forKey key: Key) throws -> Bool {
        return try decoder(for: key).decodeNil()
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable & ScalarConstructible {
        return try decoder(for: key).decode(type)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        return try decoder(for: key).decode(type)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return try decoder(for: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try decoder(for: key).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder { return try decoder(for: _YAMLCodingKey.super) }
    func superDecoder(forKey key: Key) throws -> Decoder { return try decoder(for: key) }

    // MARK: -

    private func node(for key: CodingKey) throws -> Node {
        guard let node = mapping[key.stringValue] else {
            throw _keyNotFound(at: codingPath, key, "No value associated with key \(key) (\"\(key.stringValue)\").")
        }
        return node
    }

    private func decoder(for key: CodingKey) throws -> _Decoder {
        return decoder.decoder(referencing: try node(for: key), as: key)
    }
}

private struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {

    private let decoder: _Decoder
    private let sequence: Node.Sequence

    init(decoder: _Decoder, wrapping sequence: Node.Sequence) {
        self.decoder = decoder
        self.sequence = sequence
        self.currentIndex = 0
    }

    // MARK: - Swift.UnkeyedDecodingContainer Methods

    var codingPath: [CodingKey] { return decoder.codingPath }
    var count: Int? { return sequence.count }
    var isAtEnd: Bool { return currentIndex >= sequence.count }
    var currentIndex: Int

    mutating func decodeNil() throws -> Bool {
        try throwErrorIfAtEnd(Any?.self)
        return try currentDecoder { $0.decodeNil() }
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable & ScalarConstructible {
        return try currentDecoder { try $0.decode(type) }
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try currentDecoder { try $0.decode(type) }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return try currentDecoder { try $0.container(keyedBy: type) }
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try currentDecoder { try $0.unkeyedContainer() }
    }

    mutating func superDecoder() throws -> Decoder { return try currentDecoder { $0 } }

    // MARK: -

    private var currentKey: CodingKey { return _YAMLCodingKey(index: currentIndex) }
    private var currentNode: Node { return sequence[currentIndex] }

    private func throwErrorIfAtEnd<T>(_ type: T.Type) throws {
        if isAtEnd { throw _valueNotFound(at: codingPath + [currentKey], type, "Unkeyed container is at end.") }
    }

    private mutating func currentDecoder<T>(closure: (_Decoder) throws -> T) throws -> T {
        try throwErrorIfAtEnd(T.self)
        let decoded: T = try closure(decoder.decoder(referencing: currentNode, as: currentKey))
        currentIndex += 1
        return decoded
    }
}

extension _Decoder: SingleValueDecodingContainer {

    // MARK: - Swift.SingleValueDecodingContainer Methods

    func decodeNil() -> Bool { return node.null == NSNull() }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable & ScalarConstructible { return try _decode(type) }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {return try _decode(type) }

    // MARK: -

    private func _decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let dereferenced = dereferenceAnchor(type) {
            return dereferenced
        }

        var constructed = try _construct(type)

        if var anchorCoding = constructed as? YamlAnchorCoding,
           anchorCoding.yamlAnchor == nil,
           let anchor = self.node.anchor {
            anchorCoding.yamlAnchor = anchor
            constructed = anchorCoding as! T // swiftlint:disable:this force_cast
        }

        recordAnchor(constructed)

        return constructed
    }

    private func _construct<T: Decodable>(_ type: T.Type) throws -> T {
        if let constructibleType = type as? ScalarConstructible.Type {
            let scalarConstructed = try constructScalar(constructibleType)
            guard let scalarT = scalarConstructed as? T else {
                throw _typeMismatch(at: codingPath, expectation: type, reality: scalarConstructed)
            }
            return scalarT
        }
        // not scalar constructable, initialize as Decodable
        return try type.init(from: self)
    }

    /// constuct `T` from `node`
    private func constructScalar<T: ScalarConstructible>(_ type: T.Type) throws -> T {
        let scalar = try self.scalar()
        guard let constructed = type.construct(from: scalar) else {
            throw _typeMismatch(at: codingPath, expectation: type, reality: scalar)
        }
        return constructed
    }

    private func dereferenceAnchor<T>(_ type: T.Type) -> T? {
        guard let anchor = self.node.anchor else {
            return nil
        }

        guard let strategy = userInfo[.aliasDereferencingStrategy] as? any AliasDereferencingStrategy else {
            return nil
        }

        guard let existing = strategy[anchor] as? T else {
            return nil
        }

        return existing
    }

    private func recordAnchor<T: Decodable>(_ constructed: T) {
        guard let anchor = self.node.anchor else {
            return
        }

        guard let strategy = userInfo[.aliasDereferencingStrategy] as? any AliasDereferencingStrategy else {
            return
        }

        return strategy[anchor] = constructed
    }
}

// MARK: - DecodingError helpers

private func _keyNotFound(at codingPath: [CodingKey], _ key: CodingKey, _ description: String) -> DecodingError {
    let context = DecodingError.Context(codingPath: codingPath, debugDescription: description)
    return.keyNotFound(key, context)
}

private func _valueNotFound(at codingPath: [CodingKey], _ type: Any.Type, _ description: String) -> DecodingError {
    let context = DecodingError.Context(codingPath: codingPath, debugDescription: description)
    return .valueNotFound(type, context)
}

private func _typeMismatch(at codingPath: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
    let description = "Expected to decode \(expectation) but found \(type(of: reality)) instead."
    let context = DecodingError.Context(codingPath: codingPath, debugDescription: description)
    return .typeMismatch(expectation, context)
}

// MARK: - ScalarConstructible FixedWidthInteger & SignedInteger Conformance

extension FixedWidthInteger where Self: SignedInteger {
    /// Construct an instance of `Self`, if possible, from the specified scalar.
    ///
    /// - parameter scalar: The `Node.Scalar` from which to extract a value of type `Self`, if possible.
    ///
    /// - returns: An instance of `Self`, if one was successfully extracted from the scalar.
    public static func construct(from scalar: Node.Scalar) -> Self? {
        return Int64.construct(from: scalar).flatMap(Self.init(exactly:))
    }
}

// MARK: - ScalarConstructible FixedWidthInteger & UnsignedInteger Conformance

extension FixedWidthInteger where Self: UnsignedInteger {
    /// Construct an instance of `Self`, if possible, from the specified scalar.
    ///
    /// - parameter scalar: The `Node.Scalar` from which to extract a value of type `Self`, if possible.
    ///
    /// - returns: An instance of `Self`, if one was successfully extracted from the scalar.
    public static func construct(from scalar: Node.Scalar) -> Self? {
        return UInt64.construct(from: scalar).flatMap(Self.init(exactly:))
    }
}

// MARK: - ScalarConstructible Int8 Conformance
extension Int8: ScalarConstructible {}
// MARK: - ScalarConstructible Int16 Conformance
extension Int16: ScalarConstructible {}
// MARK: - ScalarConstructible Int32 Conformance
extension Int32: ScalarConstructible {}
// MARK: - ScalarConstructible UInt8 Conformance
extension UInt8: ScalarConstructible {}
// MARK: - ScalarConstructible UInt16 Conformance
extension UInt16: ScalarConstructible {}
// MARK: - ScalarConstructible UInt32 Conformance
extension UInt32: ScalarConstructible {}

// MARK: - ScalarConstructible Decimal Conformance

extension Decimal: ScalarConstructible {
    /// Construct an instance of `Decimal`, if possible, from the specified scalar.
    ///
    /// - parameter scalar: The `Node.Scalar` from which to extract a value of type `Decimal`, if possible.
    ///
    /// - returns: An instance of `Decimal`, if one was successfully extracted from the scalar.
    public static func construct(from scalar: Node.Scalar) -> Decimal? {
        return Decimal(string: scalar.string)
    }
}

// MARK: - ScalarConstructible URL Conformance

extension URL: ScalarConstructible {
    /// Construct an instance of `URL`, if possible, from the specified scalar.
    ///
    /// - parameter scalar: The `Node.Scalar` from which to extract a value of type `URL`, if possible.
    ///
    /// - returns: An instance of `URL`, if one was successfully extracted from the scalar.
    public static func construct(from scalar: Node.Scalar) -> URL? {
        return URL(string: scalar.string)
    }
}

// MARK: Decoder.mark

extension Decoder {
    /// The `Mark` for the underlying `Node` that has been decoded.
    public var mark: Mark? {
        return (self as? _Decoder)?.node.mark
    }
}

// MARK: TopLevelDecoder

#if canImport(Combine)
import protocol Combine.TopLevelDecoder

extension YAMLDecoder: TopLevelDecoder {
    public typealias Input = Data

    public func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable {
        try decode(type, from: from, userInfo: [:])
    }
}
#endif

// MARK: DecodableWithConfiguration

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
extension YAMLDecoder {

    // MARK: JSONDecoder API

    /// Returns a value of the type you specify, decoded from a YAML object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML object.
    ///   - data: The YAML object `Data` to decode.
    ///   - configuration: A decoding configuration that provides additional information necessary for decoding.
    ///
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T>(_ type: T.Type = T.self,
                          from data: Data,
                          configuration: T.DecodingConfiguration) throws -> T where T: DecodableWithConfiguration {
        try self.decode(type, from: data, configuration: configuration, userInfo: [:])
    }

    /// Returns a value of the type you specify, decoded from a YAML object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML object.
    ///   - data: The YAML object `Data` to decode.
    ///   - configuration: A configuration instance provider to help decode types that don’t support
    ///                    encoding by themselves.
    ///
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(
        _ type: T.Type = T.self,
        from data: Data,
        configuration: C.Type
    ) throws -> T where T.DecodingConfiguration == C.DecodingConfiguration {
        try self.decode(type, from: data, configuration: configuration, userInfo: [:])
    }

    // MARK: Yams API

    /// Returns a value of the type you specify, decoded from a YAML object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML object.
    ///   - data: The YAML object `Data` to decode.
    ///   - configuration: A configuration instance provider to help decode types that don’t support
    ///                    encoding by themselves.
    ///   - userInfo: A dictionary you use to customize the decoding process by providing contextual information.
    ///
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T>(_ type: T.Type = T.self,
                          from data: Data,
                          configuration: T.DecodingConfiguration,
                          userInfo: [CodingUserInfoKey: Any]) throws -> T where T: DecodableWithConfiguration {
        guard let yaml = String(data: data, encoding: options.encoding.swiftStringEncoding) else {
            throw YamlError.dataCouldNotBeDecoded(encoding: options.encoding.swiftStringEncoding)
        }

        let decoded: T = try self.processYamlNode(type, from: yaml) { [type, configuration, userInfo] node in
            try self.decode(type, from: node, configuration: configuration, userInfo: userInfo)
        }

        return decoded
    }

    /// Returns a value of the type you specify, decoded from a YAML object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML object.
    ///   - data: The YAML object `Data` to decode.
    ///   - configuration: A configuration instance provider to help decode types that don’t support
    ///                    encoding by themselves.
    ///   - userInfo: A dictionary you use to customize the decoding process by providing contextual information.
    ///
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(
        _ type: T.Type = T.self,
        from data: Data,
        configuration: C.Type,
        userInfo: [CodingUserInfoKey: Any]
    ) throws -> T where T.DecodingConfiguration == C.DecodingConfiguration {
        try self.decode(type, from: data, configuration: configuration.decodingConfiguration, userInfo: userInfo)
    }

    // MARK: Node decoder

    /// Decode a `Decodable` type from a given `Node` and optional user info mapping.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied YAML node.
    ///   - node: YAML Node to decode.
    ///   - configuration: A configuration instance that provides additional information necessary for decoding.
    ///   - userInfo: A dictionary you use to customize the decoding process by providing contextual information.
    ///
    /// - returns: Returns the decoded type `T`.
    ///
    /// - throws: `DecodingError` or `YamlError` if something went wrong while decoding.
    public func decode<T>(_ type: T.Type = T.self,
                          from node: Node,
                          configuration: T.DecodingConfiguration,
                          userInfo: [CodingUserInfoKey: Any] = [:]) throws -> T where T: DecodableWithConfiguration {
        let decoder = _decoder(from: node, userInfo: userInfo)
        let decoded: T = try type.init(from: decoder, configuration: configuration)
        return decoded
    }
}

// swiftlint:disable:this file_length
