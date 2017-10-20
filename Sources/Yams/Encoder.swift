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
        public func encode<T: Swift.Encodable>(_ value: T) throws -> String {
            do {
                let encoder = _YAMLEncoder()
                var container = encoder.singleValueContainer()
                try container.encode(value)
                return try serialize(node: encoder.node)
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

    private extension Node {
        static let unused = Node("", .unused)
    }

    private extension Tag {
        static let unused = Tag(.unused)
    }

    private extension Tag.Name {
        static let unused: Tag.Name = "tag:yams.encoder:unused"
    }

    private class _YAMLEncoder: Swift.Encoder {

        var node: Node = .unused

        init(codingPath: [CodingKey] = []) {
            self.codingPath = codingPath
        }

        // MARK: - Swift.Encoder Methods

        /// The path to the current point in encoding.
        var codingPath: [CodingKey]

        /// Contextual user-provided information for use during encoding.
        var userInfo: [CodingUserInfoKey: Any] = [:]

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            if canEncodeNewValue {
                node = [:]
            } else {
                precondition(
                    node.isMapping,
                    "Attempt to push new keyed encoding container when already previously encoded at this path."
                )
            }
            let wrapper = _KeyedEncodingContainer<Key>(referencing: self)
            return KeyedEncodingContainer(wrapper)
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

        func singleValueContainer() -> SingleValueEncodingContainer {
            return self
        }

        // MARK: Utility

        fileprivate var canEncodeNewValue: Bool {
            return node == .unused
        }

        fileprivate var mapping: Node.Mapping {
            get {
                return node.mapping ?? [:]
            }
            set {
                node.mapping = newValue
            }
        }

        fileprivate var sequence: Node.Sequence {
            get {
                return node.sequence ?? []
            }
            set {
                node.sequence = newValue
            }
        }

        fileprivate final func box(_ representable: ScalarRepresentable) throws -> Node {
            do {
                return try representable.represented()
            } catch {
                let context = EncodingError.Context(codingPath: codingPath,
                                                    debugDescription: "Unable to encode the given value to YAML.",
                                                    underlyingError: error)
                throw EncodingError.invalidValue(representable, context)
            }
        }
    }

    private class _YAMLReferencingEncoder: _YAMLEncoder {
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

        init(referencing encoder: _YAMLEncoder, key: CodingKey) {
            self.encoder = encoder
            reference = .mapping(key.stringValue)
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

    private struct _KeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol {
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
            encoder.mapping[key.stringValue] = Node("null", Tag(.null))
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
        func encode(_ value: String, forKey key: Key) throws { encoder.mapping[key.stringValue] = Node(value) }

        func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            if let date = value as? Date {
                encoder.mapping[key.stringValue] = date.representedForCodable()
            } else if let representable = value as? ScalarRepresentable {
                encoder.mapping[key.stringValue] = try encoder.box(representable)
            } else {
                try value.encode(to: referencingEncoder(for: key))
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type,
                                        forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            let wrapper = _KeyedEncodingContainer<NestedKey>(referencing: referencingEncoder(for: key))
            return KeyedEncodingContainer(wrapper)
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(referencing: referencingEncoder(for: key))
        }

        func superEncoder() -> Encoder {
            return referencingEncoder(for: _YAMLEncodingKey.super)
        }

        func superEncoder(forKey key: Key) -> Encoder {
            return referencingEncoder(for: key)
        }

        // MARK: Utility

        /// Encode ScalarRepresentable
        private func represent<T: ScalarRepresentable>(_ value: T, for key: Key) throws {
            // assumes this function is used for types that never throws.
            encoder.mapping[key.stringValue] = try encoder.box(value)
        }

        private func referencingEncoder(for key: CodingKey) -> _YAMLReferencingEncoder {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }

            return _YAMLReferencingEncoder(referencing: self.encoder, key: key)
        }
    }

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

    private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {

        let encoder: _YAMLEncoder

        init(referencing encoder: _YAMLEncoder) {
            self.encoder = encoder
        }

        // MARK: - UnkeyedEncodingContainer

        var codingPath: [CodingKey] {
            return encoder.codingPath
        }

        var count: Int {
            return encoder.sequence.count
        }

        func encodeNil() throws {
            encoder.sequence.append(Node("null", Tag(.null)))
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
        func encode(_ value: String) throws { encoder.sequence.append(Node(value)) }

        func encode<T>(_ value: T) throws where T: Encodable {
            if let date = value as? Date {
                encoder.sequence.append(date.representedForCodable())
            } else if let representable = value as? ScalarRepresentable {
                encoder.sequence.append(try encoder.box(representable))
            } else {
                try value.encode(to: referencingEncoder())
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            let wrapper = _KeyedEncodingContainer<NestedKey>(referencing: referencingEncoder())
            return KeyedEncodingContainer(wrapper)
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(referencing: referencingEncoder())
        }

        func superEncoder() -> Encoder {
            return referencingEncoder()
        }

        // MARK: Utility

        /// Encode ScalarRepresentable
        private func represent<T: ScalarRepresentable>(_ value: T) throws {
            encoder.codingPath.append(_YAMLEncodingKey(index: count))
            defer { encoder.codingPath.removeLast() }

            // assumes this function is used for types that never throws.
            encoder.sequence.append(try encoder.box(value))
        }

        private func referencingEncoder() -> _YAMLReferencingEncoder {
            let index = count

            encoder.codingPath.append(_YAMLEncodingKey(index: index))
            defer { encoder.codingPath.removeLast() }

            encoder.sequence.append("")
            return _YAMLReferencingEncoder(referencing: self.encoder, at: index)
        }
    }

    extension _YAMLEncoder: SingleValueEncodingContainer {

        // MARK: - SingleValueEncodingContainer Methods

        func encodeNil() throws {
            assertCanEncodeNewValue()
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

        // MARK: Utility

        /// Asserts that a single value can be encoded at the current coding path
        /// (i.e. that one has not already been encoded through this container).
        /// `preconditionFailure()`s if one cannot be encoded.
        ///
        /// This is similar to assertCanRequestNewContainer above.
        fileprivate func assertCanEncodeNewValue() {
            precondition(
                canEncodeNewValue,
                "Attempt to encode value through single value container when previously value already encoded."
            )
        }

        /// Encode ScalarRepresentable
        func represent<T: ScalarRepresentable>(_ value: T) throws {
            assertCanEncodeNewValue()
            node = try box(value)
        }
    }

#endif
