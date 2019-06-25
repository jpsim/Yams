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
    /// Creates a `YAMLDecoder` instance.
    ///
    /// - parameter encoding: Encoding, `.default` if omitted.
    public init(encoding: Parser.Encoding = .default) {
        self.encoding = encoding
    }

    /// Decode a `Decodable` type from a given `String` and optional user info mapping.
    ///
    /// - parameter type:    `Decodable` type to decode.
    /// - parameter yaml:     YAML string to decode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to decode.
    ///
    /// - returns: Returns the decoded type `T`.
    ///
    /// - throws: `DecodingError` if something went wrong while decoding.
    public func decode<T>(_ type: T.Type = T.self,
                          from yaml: String,
                          userInfo: [CodingUserInfoKey: Any] = [:]) throws -> T where T: Swift.Decodable {
        do {
            let node = try Parser(yaml: yaml, resolver: .basic, encoding: encoding).singleRoot() ?? ""
            let decoder = _Decoder(referencing: node, options: options, userInfo: userInfo)
            let container = try decoder.singleValueContainer()
            return try container.decode(type)
        } catch let error as DecodingError {
            throw error
        } catch {
            throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                    debugDescription: "The given data was not valid YAML.",
                                                    underlyingError: error))
        }
    }

    /// Encoding
    public var encoding: Parser.Encoding
    public var options = Options()

    public struct Options {
        /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
        public var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    }

    /// The strategy to use for automatically changing the value of keys before decoding.
    public enum KeyDecodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Use the snake cased keys in the decoded types to accessing encoded YAML payload.
        case useSnakeCasedKeys

        /// Provide a custom conversion from the keys in the decoded types to the keys encoded YAML payload.
        /// The full path to the current decoding position is provided for context (in case you need to locate this
        /// key within the payload). The returned key is used in place of the last component in the coding path before
        /// decoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the container
        /// for the type to decode from.
        case useCustomizedKeys((_ codingPath: [CodingKey]) -> CodingKey)

        /// Provide a custom conversion from the key in the encoded YAML to the keys specified by the decoded types.
        /// The full path to the current decoding position is provided for context (in case you need to locate this
        /// key within the payload). The returned key is used in place of the last component in the coding path before
        /// decoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the container
        /// for the type to decode from.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
    }
}

private struct _Decoder: Decoder {
    typealias Options = YAMLDecoder.Options

    private let node: Node
    fileprivate let options: Options

    init(referencing node: Node, options: Options, userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
        self.node = node
        self.options = options
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    // MARK: - Swift.Decoder Methods

    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard let mapping = node.mapping else {
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

    /// Returns `String` applied `KeyDecodingStrategy`
    fileprivate func convert(_ key: CodingKey) -> String {
        switch options.keyDecodingStrategy {
        case .useDefaultKeys, .custom: return key.stringValue
        case .useSnakeCasedKeys: return key.stringValue.snakecased
        case let .useCustomizedKeys(converter): return converter(codingPath + [key]).stringValue
        }
    }

    /// create a new `_Decoder` instance referencing `node` as `key` inheriting `userInfo`
    func decoder(referencing node: Node, `as` key: CodingKey) -> _Decoder {
        return .init(referencing: node, options: options, userInfo: userInfo, codingPath: codingPath + [key])
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
        }
    }
}

private struct _KeyedDecodingContainer<Key: CodingKey> : KeyedDecodingContainerProtocol {

    private let decoder: _Decoder
    private let mapping: Node.Mapping

    init(decoder: _Decoder, wrapping mapping: Node.Mapping) {
        self.decoder = decoder
        switch self.decoder.options.keyDecodingStrategy {
        case let .custom(converter):
            self.mapping = .init(mapping.map { (arg) -> (Node, Node) in
                let (key, value) = arg
                let convertedKey = converter(decoder.codingPath + [_YAMLCodingKey(stringValue: key.string!)!])
                return (Node(convertedKey.stringValue), value)
            }, mapping.tag, mapping.style, mapping.mark)
        default:
            self.mapping = mapping
        }
    }

    // MARK: - Swift.KeyedDecodingContainerProtocol Methods

    var codingPath: [CodingKey] { return decoder.codingPath }
    var allKeys: [Key] { return Set(mapping.keys.compactMap { $0.string }).compactMap(Key.init) }
    func contains(_ key: Key) -> Bool { return mapping[decoder.convert(key)] != nil }

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
        let convertedKey = decoder.convert(key)
        guard let node = mapping[convertedKey] else {
            throw _keyNotFound(at: codingPath, key, "No value associated with key \(key) (\"\(convertedKey)\").")
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
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable & ScalarConstructible { return try construct(type) }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {return try construct(type) ?? type.init(from: self) }

    // MARK: -

    /// constuct `T` from `node`
    private func construct<T: ScalarConstructible>(_ type: T.Type) throws -> T {
        let scalar = try self.scalar()
        guard let constructed = type.construct(from: scalar) else {
            throw _typeMismatch(at: codingPath, expectation: type, reality: scalar)
        }
        return constructed
    }

    private func construct<T>(_ type: T.Type) throws -> T? {
        guard let constructibleType = type as? ScalarConstructible.Type else {
            return nil
        }
        let scalar = try self.scalar()
        guard let value = constructibleType.construct(from: scalar) else {
            throw _valueNotFound(at: codingPath, type, "Expected \(type) value but found \(scalar) instead.")
        }
        return value as? T
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
