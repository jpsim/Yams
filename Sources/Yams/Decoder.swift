//
//  Decoder.swift
//  Yams
//
//  Created by Norio Nomura on 5/6/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

#if swift(>=4.0)

    import Foundation

    public class YAMLDecoder {
        public init() {}
        public func decode<T: Swift.Decodable>(_ type: T.Type, from data: Data) throws -> T {
            // TODO: Detect string encoding
            let yaml = String(data: data, encoding: .utf8)! // swiftlint:disable:this force_unwrapping
            let node = try Yams.compose(yaml: yaml) ?? ""
            let decoder = _YAMLDecoder(referencing: node)
            let container = try decoder.singleValueContainer()
            return try container.decode(T.self)
        }
    }

    fileprivate class _YAMLDecoder: Decoder {

        let node: Node

        init(referencing node: Node, codingPath: [CodingKey] = []) {
            self.node = node
            self.codingPath = codingPath
        }

        // MARK: - Swift.Decoder Methods

        /// The path to the current point in encoding.
        var codingPath: [CodingKey]

        /// Contextual user-provided information for use during encoding.
        var userInfo: [CodingUserInfoKey : Any] = [:]

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
            guard let mapping = node.mapping else {
                throw _typeMismatch(at: codingPath, expectation: Node.Mapping.self, reality: node)
            }
            let wrapper = _YAMLKeyedDecodingContainer<Key>(decoder: self, wrapping: mapping)
            return KeyedDecodingContainer(wrapper)
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let sequence = node.sequence else {
                throw _typeMismatch(at: codingPath, expectation: Node.Sequence.self, reality: node)
            }
            return _YAMLUnkeyedDecodingContainer(decoder: self, wrapping: sequence)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return self
        }
    }

    fileprivate struct _YAMLKeyedDecodingContainer<K: CodingKey> : KeyedDecodingContainerProtocol {

        typealias Key = K

        let decoder: _YAMLDecoder
        let mapping: Node.Mapping

        init(decoder: _YAMLDecoder, wrapping mapping: Node.Mapping) {
            self.decoder = decoder
            self.mapping = mapping
        }

        // MARK: - KeyedDecodingContainerProtocol

        var codingPath: [CodingKey] {
            return decoder.codingPath
        }

        var allKeys: [Key] {
            return mapping.keys.flatMap { $0.string.flatMap(Key.init(stringValue:)) }
        }

        func contains(_ key: K) -> Bool {
            if mapping[key.stringValue] != nil {
                return true
            }
            return false
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            guard let node = mapping[key.stringValue] else {
                throw _keyNotFound(at: codingPath, key, "No value associated with key \(key) (\"\(key.stringValue)\").")
            }
            return node == Node("null", Tag(.null))
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { return try construct(for: key) }
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int { return try construct(for: key) }
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { return try construct(for: key) }
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { return try construct(for: key) }
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { return try construct(for: key) }
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { return try construct(for: key) }
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { return try construct(for: key) }
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { return try construct(for: key) }
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try construct(for: key) }
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try construct(for: key) }
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try construct(for: key) }
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float { return try construct(for: key) }
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try construct(for: key) }
        func decode(_ type: String.Type, forKey key: Key) throws -> String { return try construct(for: key) }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let node = mapping[key.stringValue] else {
                throw _keyNotFound(at: codingPath, key, "No value associated with key \(key) (\"\(key.stringValue)\").")
            }

            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            if let constructibleType = type.self as? ScalarConstructible.Type {
                guard let value = constructibleType.construct(from: node) else {
                    throw _valueNotFound(at: codingPath, T.self, "Expected \(T.self) value but found null instead.")
                }
                return value as! T // swiftlint:disable:this force_cast
            }

            return try T(from: _YAMLDecoder(referencing: node, codingPath: codingPath))
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                        forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            guard let node = mapping[key.stringValue] else {
                let description =
                "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""
                throw _keyNotFound(at: codingPath, key, description)
            }

            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            guard let mapping = node.mapping else {
                throw _typeMismatch(at: codingPath, expectation: Node.Mapping.self, reality: node)
            }

            let nestedDecoder = _YAMLDecoder(referencing: node, codingPath: codingPath)
            let wrapping =  _YAMLKeyedDecodingContainer<NestedKey>(decoder: nestedDecoder, wrapping: mapping)
            return KeyedDecodingContainer(wrapping)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            guard let node = mapping[key.stringValue] else {
                let description = "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""
                throw _keyNotFound(at: codingPath, key, description)
            }

            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            guard let sequence = node.sequence else {
                throw _typeMismatch(at: codingPath, expectation: Node.Sequence.self, reality: node)
            }

            let nestedDecoder = _YAMLDecoder(referencing: node, codingPath: codingPath)
            return _YAMLUnkeyedDecodingContainer(decoder: nestedDecoder, wrapping: sequence)
        }

        private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            let node = mapping[key.stringValue]  ?? ""
            return _YAMLDecoder(referencing: node, codingPath: codingPath)
        }

        func superDecoder() throws -> Decoder {
            return try _superDecoder(forKey: _YAMLDecodingKey.super)
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return try _superDecoder(forKey: key)
        }

        // MARK: Utility

        /// Decode ScalarConstructible
        private func construct<T: ScalarConstructible>(for key: Key) throws -> T {
            guard let node = mapping[key.stringValue] else {
                throw _keyNotFound(at: codingPath, key, "No value associated with key \(key) (\"\(key.stringValue)\").")
            }

            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            guard let value = T.construct(from: node) else {
                throw _valueNotFound(at: codingPath, T.self, "Expected \(T.self) value but found null instead.")
            }
            return value
        }
    }

    fileprivate struct _YAMLDecodingKey: CodingKey {
        public var stringValue: String
        public var intValue: Int?

        public init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        public init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }

        fileprivate init(index: Int) {
            self.stringValue = "Index \(index)"
            self.intValue = index
        }

        fileprivate static let `super` = _YAMLDecodingKey(stringValue: "super")!
    }

    fileprivate struct _YAMLUnkeyedDecodingContainer: UnkeyedDecodingContainer {

        let decoder: _YAMLDecoder
        let sequence: Node.Sequence

        /// The index of the element we're about to decode.
        var currentIndex: Int

        init(decoder: _YAMLDecoder, wrapping sequence: Node.Sequence) {
            self.decoder = decoder
            self.sequence = sequence
            self.currentIndex = 0
        }

        // MARK: - UnkeyedDecodingContainer
        var codingPath: [CodingKey] {
            return decoder.codingPath
        }

        var count: Int? {
            return sequence.count
        }

        var isAtEnd: Bool {
            return currentIndex >= sequence.count
        }

        mutating func decodeNil() throws -> Bool {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, Any?.self, "Unkeyed container is at end.")
            }

            if sequence[currentIndex] == Node("null", Tag(.null)) {
                currentIndex += 1
                return true
            } else {
                return false
            }
        }

        mutating func decode(_ type: Bool.Type) throws -> Bool { return try construct() }
        mutating func decode(_ type: Int.Type) throws -> Int { return try construct() }
        mutating func decode(_ type: Int8.Type) throws -> Int8 { return try construct() }
        mutating func decode(_ type: Int16.Type) throws -> Int16 { return try construct() }
        mutating func decode(_ type: Int32.Type) throws -> Int32 { return try construct() }
        mutating func decode(_ type: Int64.Type) throws -> Int64 { return try construct() }
        mutating func decode(_ type: UInt.Type) throws -> UInt { return try construct() }
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 { return try construct() }
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try construct() }
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try construct() }
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try construct() }
        mutating func decode(_ type: Float.Type) throws -> Float { return try construct() }
        mutating func decode(_ type: Double.Type) throws -> Double { return try construct() }
        mutating func decode(_ type: String.Type) throws -> String { return try construct() }

        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, T.self, "Unkeyed container is at end.")
            }

            let node = sequence[currentIndex]
            if let constructibleType = type.self as? ScalarConstructible.Type {
                guard let value = constructibleType.construct(from: node) else {
                    throw _valueNotFound(at: codingPath, T.self, "Expected \(T.self) value but found null instead.")
                }
                currentIndex += 1
                return value as! T // swiftlint:disable:this force_cast
            }

            let value = try T(from: _YAMLDecoder(referencing: node, codingPath: codingPath))
            currentIndex += 1
            return value
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, KeyedDecodingContainer<NestedKey>.self,
                                     "Cannot get nested keyed container -- unkeyed container is at end.")
            }

            let node = sequence[currentIndex]
            guard let mapping = node.mapping else {
                throw _typeMismatch(at: codingPath, expectation: Node.Mapping.self, reality: node)
            }

            currentIndex += 1
            let nestedDecoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
            let wrapping =  _YAMLKeyedDecodingContainer<NestedKey>(decoder: nestedDecoder, wrapping: mapping)
            return KeyedDecodingContainer(wrapping)
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, UnkeyedDecodingContainer.self,
                                     "Cannot get UnkeyedDecodingContainer -- unkeyed container is at end.")
            }

            let node = sequence[currentIndex]
            guard let sequence = node.sequence else {
                throw _typeMismatch(at: codingPath, expectation: Node.Sequence.self, reality: node)
            }

            let nestedDecoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
            return _YAMLUnkeyedDecodingContainer(decoder: nestedDecoder, wrapping: sequence)
        }

        mutating func superDecoder() throws -> Decoder {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, Decoder.self,
                                     "Cannot get superDecoder() -- unkeyed container is at end.")
            }

            let node = sequence[currentIndex]
            self.currentIndex += 1
            return _YAMLDecoder(referencing: node, codingPath: codingPath)
        }

        // MARK: Utility

        /// Decode ScalarConstructible
        mutating func construct<T: ScalarConstructible>() throws -> T {
            decoder.codingPath.append(_YAMLDecodingKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }

            guard !self.isAtEnd else {
                throw _valueNotFound(at: codingPath, T.self, "Unkeyed container is at end.")
            }

            guard let decoded = T.construct(from: sequence[currentIndex]) else {
                throw _valueNotFound(at: codingPath, T.self, "Expected \(T.self) but found null instead.")
            }

            currentIndex += 1
            return decoded
        }
    }

    extension _YAMLDecoder : SingleValueDecodingContainer {

        // MARK: SingleValueDecodingContainer Methods

        func decodeNil() -> Bool { return node.null == NSNull() }
        func decode(_ type: Bool.Type)   throws -> Bool { return try construct() }
        func decode(_ type: Int.Type)    throws -> Int { return try construct() }
        func decode(_ type: Int8.Type)   throws -> Int8 { return try construct() }
        func decode(_ type: Int16.Type)  throws -> Int16 { return try construct() }
        func decode(_ type: Int32.Type)  throws -> Int32 { return try construct() }
        func decode(_ type: Int64.Type)  throws -> Int64 { return try construct() }
        func decode(_ type: UInt.Type)   throws -> UInt { return try construct() }
        func decode(_ type: UInt8.Type)  throws -> UInt8 { return try construct() }
        func decode(_ type: UInt16.Type) throws -> UInt16 { return try construct() }
        func decode(_ type: UInt32.Type) throws -> UInt32 { return try construct() }
        func decode(_ type: UInt64.Type) throws -> UInt64 { return try construct() }
        func decode(_ type: Float.Type)  throws -> Float { return try construct() }
        func decode(_ type: Double.Type) throws -> Double { return try construct() }
        func decode(_ type: String.Type) throws -> String { return try construct() }
        func decode(_ type: Data.Type)   throws -> Data { return try construct() }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try expectNonNull(T.self)

            if let scalarConstructibleType = type.self as? ScalarConstructible.Type {
                guard let value = scalarConstructibleType.construct(from: node) else {
                    throw _valueNotFound(at: codingPath, T.self, "Expected \(T.self) value but found null instead.")
                }
                return value as! T // swiftlint:disable:this force_cast
            }

            let decoder = _YAMLDecoder(referencing: node)
            return try T(from: decoder)
        }

        // MARK: Utility

        /// Decode ScalarConstructible
        private func construct<T: ScalarConstructible>() throws -> T {
            try expectNonNull(T.self)
            guard let decoded = T.construct(from: node) else {
                throw _typeMismatch(at: codingPath, expectation: T.self, reality: node)
            }
            return decoded
        }

        private func expectNonNull<T>(_ type: T.Type) throws {
            guard !self.decodeNil() else {
                throw _valueNotFound(at: codingPath, type, "Expected \(type) but found null value instead.")
            }
        }

    }

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

    extension BinaryInteger {
        public static func construct(from node: Node) -> Self? {
            return Int.construct(from: node) as? Self
        }
    }

    extension Int16: ScalarConstructible {}
    extension Int32: ScalarConstructible {}
    extension Int64: ScalarConstructible {}
    extension Int8: ScalarConstructible {}
    extension UInt: ScalarConstructible {}
    extension UInt16: ScalarConstructible {}
    extension UInt32: ScalarConstructible {}
    extension UInt64: ScalarConstructible {}
    extension UInt8: ScalarConstructible {}

    extension Float: ScalarConstructible {
        public static func construct(from node: Node) -> Float? {
            return Double.construct(from: node) as? Float
        }
    }

#endif // swiftlint:disable:this file_length
