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

        init(referencing node: Node, codingPath: [CodingKey?] = []) {
            self.node = node
            self.codingPath = codingPath
        }

        // MARK: - Swift.Decoder Methods

        /// The path to the current point in encoding.
        var codingPath: [CodingKey?]

        /// Contextual user-provided information for use during encoding.
        var userInfo: [CodingUserInfoKey : Any] = [:]

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
            guard let mapping = node.mapping else {
                // FIXME: Should throw type mismatch error
                throw DecodingError.valueNotFound(
                    KeyedDecodingContainer<Key>.self,
                    DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Cannot get keyed decoding container -- found null value instead."
                    )
                )
            }
            let wrapper = _YAMLKeyedDecodingContainer<Key>(decoder: self, wrapping: mapping)
            return KeyedDecodingContainer(wrapper)
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let sequence = node.sequence else {
                // FIXME: Should throw type mismatch error
                throw DecodingError.valueNotFound(
                    UnkeyedDecodingContainer.self,
                    DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Cannot get unkeyed decoding container -- found null value instead."
                    )
                )
            }
            return _YAMLUnkeyedDecodingContainer(decoder: self, wrapping: sequence)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return self
        }

        // MARK: Utility

        /// Performs the given closure with the given key pushed onto the end of the current coding path.
        ///
        /// - parameter key: The key to push. May be nil for unkeyed containers.
        /// - parameter work: The work to perform with the key in the path.
        func with<T>(pushedKey key: CodingKey?, _ work: () throws -> T) rethrows -> T {
            self.codingPath.append(key)
            let ret: T = try work()
            self.codingPath.removeLast()
            return ret
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

        var codingPath: [CodingKey?] {
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

        func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? { return try construct(for: key) }
        func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { return try construct(for: key) }
        func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? { return try construct(for: key) }
        func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? { return try construct(for: key) }
        func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? { return try construct(for: key) }
        func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { return try construct(for: key) }
        func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? { return try construct(for: key) }
        func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? { return try construct(for: key) }
        func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? { return try construct(for: key) }
        func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? { return try construct(for: key) }
        func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? { return try construct(for: key) }
        func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { return try construct(for: key) }
        func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { return try construct(for: key) }
        func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? { return try construct(for: key) }

        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            return try decoder.with(pushedKey: key) {
                guard let node = mapping[key.stringValue] else { return nil }
                if T.self == Data.self {
                    return Data.construct(from: node) as? T
                } else if T.self == Date.self {
                    return Date.construct(from: node) as? T
                }

                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                return try T(from: decoder)
            }
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                        forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            return try decoder.with(pushedKey: key) {
                guard let node = mapping[key.stringValue] else {
                    // FIXME: Should throw type mismatch error
                    throw DecodingError.keyNotFound(
                        key,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""
                        )
                    )
                }
                guard let mapping = node.mapping else {
                    fatalError("should throw type mismatch error")
                }
                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                let wrapping =  _YAMLKeyedDecodingContainer<NestedKey>(decoder: decoder, wrapping: mapping)
                return KeyedDecodingContainer(wrapping)
            }
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.with(pushedKey: key) {
                guard let node = mapping[key.stringValue], let sequence = node.sequence else {
                    // FIXME: Should throw type mismatch error
                    throw DecodingError.keyNotFound(
                        key,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""
                        )
                    )
                }
                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                return _YAMLUnkeyedDecodingContainer(decoder: decoder, wrapping: sequence)
            }
        }

        private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
            return try self.decoder.with(pushedKey: key) {
                guard let node = mapping[key.stringValue] else {
                    throw DecodingError.keyNotFound(
                        key,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get superDecoder() -- no value found for key \"\(key.stringValue)\""
                        )
                    )
                }

                return _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
            }
        }

        func superDecoder() throws -> Decoder {
            return try _superDecoder(forKey: _YAMLDecodingSuperKey())
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return try _superDecoder(forKey: key)
        }

        // MARK: Utility

        /// Encode ScalarConstructible
        func construct<T: ScalarConstructible>(for key: Key) throws -> T? {
            return decoder.with(pushedKey: key) {
                guard let node = mapping[key.stringValue] else { return nil }
                return T.construct(from: node)
            }
        }
    }

    fileprivate struct _YAMLDecodingSuperKey: CodingKey {
        init() {}

        var stringValue: String { return "super" }
        init?(stringValue: String) {
            guard stringValue == "super" else { return nil }
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) {
            return nil
        }
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
        var codingPath: [CodingKey?] {
            return decoder.codingPath
        }

        var count: Int? {
            return sequence.count
        }

        var isAtEnd: Bool {
            return self.currentIndex >= sequence.count
        }

        mutating func decodeIfPresent(_ type: Bool.Type) throws -> Bool? { return try construct() }
        mutating func decodeIfPresent(_ type: Int.Type) throws -> Int? { return try construct() }
        mutating func decodeIfPresent(_ type: Int8.Type) throws -> Int8? { return try construct() }
        mutating func decodeIfPresent(_ type: Int16.Type) throws -> Int16? { return try construct() }
        mutating func decodeIfPresent(_ type: Int32.Type) throws -> Int32? { return try construct() }
        mutating func decodeIfPresent(_ type: Int64.Type) throws -> Int64? { return try construct() }
        mutating func decodeIfPresent(_ type: UInt.Type) throws -> UInt? { return try construct() }
        mutating func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? { return try construct() }
        mutating func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? { return try construct() }
        mutating func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? { return try construct() }
        mutating func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? { return try construct() }
        mutating func decodeIfPresent(_ type: Float.Type) throws -> Float? { return try construct() }
        mutating func decodeIfPresent(_ type: Double.Type) throws -> Double? { return try construct() }
        mutating func decodeIfPresent(_ type: String.Type) throws -> String? { return try construct() }

        mutating func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T : Decodable {
            guard !self.isAtEnd else { return nil }

            let decoded: T? = try decoder.with(pushedKey: nil) {
                let node = sequence[currentIndex]
                if T.self == Data.self {
                    return Data.construct(from: node) as? T
                } else if T.self == Date.self {
                    return Date.construct(from: node) as? T
                }

                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                return try T(from: decoder)
            }
            currentIndex += 1
            return decoded
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            return try decoder.with(pushedKey: nil) {
                guard !self.isAtEnd else {
                    throw DecodingError.valueNotFound(
                        KeyedDecodingContainer<NestedKey>.self,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."
                        )
                    )
                }
                let node = sequence[currentIndex]
                guard let mapping = node.mapping else {
                    // FIXME: Should throw type mismatch error
                    throw DecodingError.valueNotFound(
                        KeyedDecodingContainer<NestedKey>.self,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found at index \"\(currentIndex)\""
                        )
                    )
                }

                currentIndex += 1
                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                let wrapping =  _YAMLKeyedDecodingContainer<NestedKey>(decoder: decoder, wrapping: mapping)
                return KeyedDecodingContainer(wrapping)
            }
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return try decoder.with(pushedKey: nil) {
                guard !self.isAtEnd else {
                    throw DecodingError.valueNotFound(
                        UnkeyedDecodingContainer.self,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get UnkeyedDecodingContainer -- unkeyed container is at end."
                        )
                    )
                }
                let node = sequence[currentIndex]
                guard let sequence = node.sequence else {
                    // FIXME: Should throw type mismatch error
                    throw DecodingError.typeMismatch(
                        type(of: node),
                        DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found at index \"\(currentIndex)\""
                        )
                    )
                }
                let decoder = _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
                return _YAMLUnkeyedDecodingContainer(decoder: decoder, wrapping: sequence)
            }
        }

        mutating func superDecoder() throws -> Decoder {
            return try decoder.with(pushedKey: nil) {
                guard !self.isAtEnd else {
                    throw DecodingError.valueNotFound(
                        Decoder.self,
                        DecodingError.Context(
                            codingPath: self.codingPath,
                            debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."
                        )
                    )
                }

                let node = sequence[currentIndex]
                self.currentIndex += 1
                return _YAMLDecoder(referencing: node, codingPath: self.decoder.codingPath)
            }
        }

        // MARK: Utility

        /// Encode ScalarConstructible
        mutating func construct<T: ScalarConstructible>() throws -> T? {
            guard !self.isAtEnd else { return nil }

            return decoder.with(pushedKey: nil) {
                let node = sequence[currentIndex]
                currentIndex += 1
                return T.construct(from: node)
            }
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
            if T.self == Data.self {
                return Data.construct(from: node) as! T // swiftlint:disable:this force_cast
            } else if T.self == Date.self {
                return Date.construct(from: node) as! T // swiftlint:disable:this force_cast
            }

            let decoder = _YAMLDecoder(referencing: node)
            return try T(from: decoder)
        }

        // MARK: Utility

        /// Encode ScalarConstructible
        func construct<T: ScalarConstructible>() throws -> T {
            return try with(pushedKey: nil) {
                guard let decoded = T.construct(from: node) else {
                    // FIXME: Should throw type mismatch error
                    throw DecodingError.typeMismatch(
                        T.self,
                        DecodingError.Context(
                            codingPath: codingPath, debugDescription: ""
                        )
                    )
                }
                return decoded
            }
        }
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
