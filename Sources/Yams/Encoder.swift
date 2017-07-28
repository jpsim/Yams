//
//  Encoder.swift
//  Yams
//
//  Created by Norio Nomura on 5/2/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

#if swift(>=4.0)

    import Foundation

    public class YAMLEncoder {
        public init() {}
        public func encode<T: Swift.Encodable>(_ value: T) throws -> Data {
            let encoder = _YAMLEncoder()
            do {
                var container = encoder.singleValueContainer()
                try container.encode(value)
            }
            return try serialize(node: encoder.node).data(using: .utf8, allowLossyConversion: false) ?? Data()
        }
    }

    fileprivate class _YAMLEncoder: Swift.Encoder {

        var node: Node = ""

        init(codingPath: [CodingKey] = []) {
            self.codingPath = codingPath
        }

        // MARK: - Swift.Encoder Methods

        /// The path to the current point in encoding.
        var codingPath: [CodingKey]

        /// Contextual user-provided information for use during encoding.
        var userInfo: [CodingUserInfoKey : Any] = [:]

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            assertCanRequestNewContainer()
            node = [:]
            let wrapper = _KeyedEncodingContainer<Key>(referencing: self)
            return KeyedEncodingContainer(wrapper)
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            assertCanRequestNewContainer()
            node = []
            return _UnkeyedEncodingContainer(referencing: self)
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            assertCanRequestNewContainer()
            return self
        }

        // MARK: Utility

        /// Performs the given closure with the given key pushed onto the end of the current coding path.
        ///
        /// - parameter key: The key to push. May be nil for unkeyed containers.
        /// - parameter work: The work to perform with the key in the path.
        func with(pushedKey key: CodingKey, _ work: () throws -> Void) rethrows {
            self.codingPath.append(key)
            try work()
            self.codingPath.removeLast()
        }

        /// Asserts that a new container can be requested at this coding path.
        /// `preconditionFailure()`s if one cannot be requested.
        func assertCanRequestNewContainer() {
            guard node == "" else {
                let previousContainerType: String
                switch node {
                case .mapping:
                    previousContainerType = "keyed"
                case .sequence:
                    previousContainerType = "unkeyed"
                case .scalar:
                    previousContainerType = "single value"
                }
                preconditionFailure(
                    "Attempt to encode with new container when already encoded with \(previousContainerType) container."
                )
            }
        }
    }

    fileprivate class _YAMLReferencingEncoder: _YAMLEncoder {
        enum Reference {
            case sequence(Int)
            case mapping(String)
        }
        let encoder: _YAMLEncoder
        let reference: Reference

        init(referencing encoder: _YAMLEncoder, at index: Int) {
            self.encoder = encoder
            reference = .sequence(index)
            super.init(codingPath: encoder.codingPath)
        }

        init(referencing encoder: _YAMLEncoder, key: String) {
            self.encoder = encoder
            reference = .mapping(key)
            super.init(codingPath: encoder.codingPath)
        }

        deinit {
            switch reference {
            case .sequence(let index):
                encoder.node[index] = node
            case .mapping(let key):
                encoder.node[key] = node
            }
        }
    }

    fileprivate struct _KeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol {
        typealias Key = K

        let encoder: _YAMLEncoder

        init(referencing encoder: _YAMLEncoder) {
            self.encoder = encoder
        }

        // MARK: - KeyedEncodingContainerProtocol

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        // assumes following methods never throws
        func encodeNil(forKey key: K) throws {
            encoder.node.mapping?[key.stringValue] = Node("null", Tag(.null))
        }

        func encode(_ value: Bool, forKey key: Key)   throws { try represent(value, for: key) }
        func encode(_ value: Int, forKey key: Key)    throws { try represent(value, for: key) }
        func encode(_ value: Int8, forKey key: Key)   throws { try represent(value, for: key) }
        func encode(_ value: Int16, forKey key: Key)  throws { try represent(value, for: key) }
        func encode(_ value: Int32, forKey key: Key)  throws { try represent(value, for: key) }
        func encode(_ value: Int64, forKey key: Key)  throws { try represent(value, for: key) }
        func encode(_ value: UInt, forKey key: Key)   throws { try represent(value, for: key) }
        func encode(_ value: UInt8, forKey key: Key)  throws { try represent(value, for: key) }
        func encode(_ value: UInt16, forKey key: Key) throws { try represent(value, for: key) }
        func encode(_ value: UInt32, forKey key: Key) throws { try represent(value, for: key) }
        func encode(_ value: UInt64, forKey key: Key) throws { try represent(value, for: key) }
        func encode(_ value: Float, forKey key: Key)  throws { try represent(value, for: key) }
        func encode(_ value: Double, forKey key: Key) throws { try represent(value, for: key) }
        func encode(_ value: String, forKey key: Key) throws { encoder.node.mapping?[key.stringValue] = Node(value) }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            try encoder.with(pushedKey: key) {
                if let date = value as? Date {
                    encoder.node.mapping?[key.stringValue] = date.representedForCodable()
                } else if let representable = value as? ScalarRepresentable {
                    encoder.node.mapping?[key.stringValue] = try representable.represented()
                } else {
                    try value.encode(to: referencingEncoder(for: key.stringValue))
                }
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type,
                                        forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            let wrapper = _KeyedEncodingContainer<NestedKey>(referencing: referencingEncoder(for: key.stringValue))
            return KeyedEncodingContainer(wrapper)
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(referencing: referencingEncoder(for: key.stringValue))
        }

        func superEncoder() -> Encoder {
            return referencingEncoder(for: "super")
        }

        func superEncoder(forKey key: Key) -> Encoder {
            return referencingEncoder(for: key.stringValue)
        }

        // MARK: Utility

        /// Encode ScalarRepresentable
        private func represent<T: ScalarRepresentable>(_ value: T, for key: Key) throws {
            // assumes this function is used for types that never throws.
            encoder.node.mapping?[key.stringValue] = try Node(value)
        }

        private func referencingEncoder(for key: String) -> _YAMLReferencingEncoder {
            return _YAMLReferencingEncoder(referencing: self.encoder, key: key)
        }
    }

    fileprivate struct _YAMLEncodingKey: CodingKey {
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

        fileprivate static let `super` = _YAMLEncodingKey(stringValue: "super")!
    }

    fileprivate struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {

        let encoder: _YAMLEncoder

        init(referencing encoder: _YAMLEncoder) {
            self.encoder = encoder
        }

        // MARK: - UnkeyedEncodingContainer

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        var count: Int {
            return encoder.node.sequence?.count ?? 0
        }

        func encodeNil() throws {
            encoder.node.sequence?.append(Node("null", Tag(.null)))
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
        func encode(_ value: String) throws { encoder.node.sequence?.append(Node(value)) }

        func encode<T>(_ value: T) throws where T : Encodable {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            if let date = value as? Date {
                encoder.node.sequence?.append(date.representedForCodable())
            } else if let representable = value as? ScalarRepresentable {
                encoder.node.sequence?.append(try representable.represented())
            } else {
                try value.encode(to: referencingEncoder())
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            let wrapper = _KeyedEncodingContainer<NestedKey>(referencing: referencingEncoder())
            return KeyedEncodingContainer(wrapper)
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            return _UnkeyedEncodingContainer(referencing: referencingEncoder())
        }

        func superEncoder() -> Encoder {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            return referencingEncoder()
        }

        // MARK: Utility

        /// Encode ScalarRepresentable
        private func represent<T: ScalarRepresentable>(_ value: T) throws {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            // assumes this function is used for types that never throws.
            encoder.node.sequence?.append(try Node(value))
        }

        private func referencingEncoder() -> _YAMLReferencingEncoder {
            let index: Int = encoder.node.sequence?.count ?? 0
            encoder.node.sequence?.append("")
            return _YAMLReferencingEncoder(referencing: self.encoder, at: index)
        }
    }

    extension _YAMLEncoder: SingleValueEncodingContainer {

        // MARK: - SingleValueEncodingContainer Methods

        func encodeNil() throws {
            assertCanEncodeSingleValue()
            node = Node("null", Tag(.null))
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
            assertCanEncodeSingleValue()
            node = Node(value)
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            if let date = value as? Date {
                node = date.representedForCodable()
            } else if let representable = value as? ScalarRepresentable {
                node = try representable.represented()
            } else {
                try value.encode(to: self)
            }
        }

        // MARK: Utility

        /// Asserts that a single value can be encoded at the current coding path
        /// (i.e. that one has not already been encoded through this container).
        /// `preconditionFailure()`s if one cannot be encoded.
        ///
        /// This is similar to assertCanRequestNewContainer above.
        func assertCanEncodeSingleValue() {
            guard node == "" else {
                let previousContainerType: String
                switch node {
                case .mapping:
                    previousContainerType = "keyed"
                case .sequence:
                    previousContainerType = "unkeyed"
                case .scalar:
                    preconditionFailure("Attempt to encode multiple values in a single value container.")
                }
                preconditionFailure(
                    "Attempt to encode with new container when already encoded with \(previousContainerType) container."
                )
            }
        }

        /// Encode ScalarRepresentable
        func represent<T: ScalarRepresentable>(_ value: T) throws {
            assertCanEncodeSingleValue()
            node = try Node(value)
        }
    }

#endif
