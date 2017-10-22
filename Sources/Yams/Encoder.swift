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
        public typealias Options = Emitter.Options
        public var options = Options()
        public init() {}
        public func encode<T: Swift.Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> String {
            do {
                let encoder = _YAMLEncoder(userInfo: userInfo)
                var container = encoder.singleValueContainer()
                try container.encode(value)
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

    private class _YAMLEncoder: Swift.Encoder {

        var node: Node = .unused

        init(userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
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

        var canEncodeNewValue: Bool { return node == .unused }

        var mapping: Node.Mapping {
            get { return node.mapping ?? [:] }
            set { node.mapping = newValue }
        }

        var sequence: Node.Sequence {
            get { return node.sequence ?? [] }
            set { node.sequence = newValue }
        }

        /// Create `Node` from `ScalarRepresentable`.
        /// Errors throwed by `ScalarRepresentable` will be boxed into `EncodingError`
        private func box(_ representable: ScalarRepresentable) throws -> Node {
            do {
                return try representable.represented()
            } catch {
                let context = EncodingError.Context(codingPath: codingPath,
                                                    debugDescription: "Unable to encode the given value to YAML.",
                                                    underlyingError: error)
                throw EncodingError.invalidValue(representable, context)
            }
        }

        /// Encode `ScalarRepresentable` to `node`
        func represent<T: ScalarRepresentable>(_ value: T) throws {
            assertCanEncodeNewValue()
            node = try box(value)
        }

        /// create a new `_YAMLReferencingEncoder` instance as `key` inheriting `userInfo`
        func encoder(for key: CodingKey) -> _YAMLReferencingEncoder {
            return .init(referencing: self, key: key)
        }

        /// create a new `_YAMLReferencingEncoder` instance at `index` inheriting `userInfo`
        func encoder(at index: Int) -> _YAMLReferencingEncoder {
            return .init(referencing: self, at: index)
        }
    }

    private class _YAMLReferencingEncoder: _YAMLEncoder {
        private enum Reference { case mapping(String), sequence(Int) }

        private let encoder: _YAMLEncoder
        private let reference: Reference

        init(referencing encoder: _YAMLEncoder, key: CodingKey) {
            self.encoder = encoder
            reference = .mapping(key.stringValue)
            super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath + [key])
        }

        init(referencing encoder: _YAMLEncoder, at index: Int) {
            self.encoder = encoder
            reference = .sequence(index)
            super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath + [_YAMLEncodingKey(index: index)])
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

    private struct _KeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol {
        typealias Key = K

        let encoder: _YAMLEncoder

        init(referencing encoder: _YAMLEncoder) {
            self.encoder = encoder
        }

        // MARK: - Swift.KeyedEncodingContainerProtocol Methods

        var codingPath: [CodingKey] { return encoder.codingPath }
        func encodeNil(forKey key: Key)               throws { encoder.mapping[key.stringValue] = .null }
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
        func encode(_ value: String, forKey key: Key) throws { encoder.mapping[key.stringValue] = Node(value) }
        func encode<T>(_ value: T, forKey key: Key)   throws where T: Encodable { try encoder(for: key).encode(value) }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                        forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            return encoder(for: key).container(keyedBy: type)
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder(for: key).unkeyedContainer()
        }

        func superEncoder() -> Encoder { return encoder(for: _YAMLEncodingKey.super) }
        func superEncoder(forKey key: Key) -> Encoder { return encoder(for: key) }

        // MARK: -

        private func encoder(for key: CodingKey) -> _YAMLReferencingEncoder { return encoder.encoder(for: key) }

        private func represent<T: ScalarRepresentable>(_ value: T, for key: Key) throws {
             try encoder(for: key).represent(value)
        }
    }

    private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {

        let encoder: _YAMLEncoder

        init(referencing encoder: _YAMLEncoder) {
            self.encoder = encoder
        }

        // MARK: - Swift.UnkeyedEncodingContainer Methods

        var codingPath: [CodingKey] { return encoder.codingPath }
        var count: Int { return encoder.sequence.count }
        func encodeNil()             throws { encoder.sequence.append(.null) }
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
        func encode(_ value: String) throws { encoder.sequence.append(Node(value)) }
        func encode<T>(_ value: T)   throws where T: Encodable { try currentEncoder.encode(value) }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            return currentEncoder.container(keyedBy: type)
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { return currentEncoder.unkeyedContainer() }
        func superEncoder() -> Encoder { return currentEncoder }

        // MARK: -

        private var currentEncoder: _YAMLReferencingEncoder {
            defer { encoder.sequence.append("") }
            return encoder.encoder(at: count)
        }

        private func represent<T: ScalarRepresentable>(_ value: T) throws {
            try currentEncoder.represent(value)
        }
    }

    extension _YAMLEncoder: SingleValueEncodingContainer {

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
            if let date = value as? Date {
                node = date.representedForCodable()
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
        private func assertCanEncodeNewValue() {
            precondition(
                canEncodeNewValue,
                "Attempt to encode value through single value container when previously value already encoded."
            )
        }
    }

    // MARK: - CodingKey for `_UnkeyedEncodingContainer` and `superEncoders`

    private struct _YAMLEncodingKey: CodingKey {
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
            version: options.version)
    }

#endif
