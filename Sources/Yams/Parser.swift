//
//  Parser.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

#if SWIFT_PACKAGE
    import CYaml
#endif
import Foundation

/// Parse all YAML documents in a String
/// and produce corresponding Swift objects.
///
/// - Parameters:
///   - yaml: String
///   - resolver: Resolver
///   - constructor: Constructor
/// - Returns: YamlSequence<Any>
/// - Throws: ParserError or YamlError
public func load_all(yaml: String,
                     _ resolver: Resolver = .default,
                     _ constructor: Constructor = .default) throws -> YamlSequence<Any> {
    let parser = try Parser(yaml: yaml, resolver: resolver, constructor: constructor)
    return YamlSequence { try parser.nextRoot()?.any }
}

/// Parse the first YAML document in a String
/// and produce the corresponding Swift object.
///
/// - Parameters:
///   - yaml: String
///   - resolver: Resolver
///   - constructor: Constructor
/// - Returns: Any?
/// - Throws: ParserError or YamlError
public func load(yaml: String,
                 _ resolver: Resolver = .default,
                 _ constructor: Constructor = .default) throws -> Any? {
    return try Parser(yaml: yaml, resolver: resolver, constructor: constructor).nextRoot()?.any
}

/// Parse all YAML documents in a String
/// and produce corresponding representation trees.
///
/// - Parameters:
///   - yaml: String
///   - resolver: Resolver
///   - constructor: Constructor
/// - Returns: YamlSequence<Node>
/// - Throws: ParserError or YamlError
public func compose_all(yaml: String,
                        _ resolver: Resolver = .default,
                        _ constructor: Constructor = .default) throws -> YamlSequence<Node> {
    let parser = try Parser(yaml: yaml, resolver: resolver, constructor: constructor)
    return YamlSequence(parser.nextRoot)
}

/// Parse the first YAML document in a String
/// and produce the corresponding representation tree.
///
/// - Parameters:
///   - yaml: String
///   - resolver: Resolver
///   - constructor: Constructor
/// - Returns: Node?
/// - Throws: ParserError or YamlError
public func compose(yaml: String,
                    _ resolver: Resolver = .default,
                    _ constructor: Constructor = .default) throws -> Node? {
    return try Parser(yaml: yaml, resolver: resolver, constructor: constructor).nextRoot()
}

/// Sequence that holds error
public struct YamlSequence<T>: Sequence, IteratorProtocol {
    public private(set) var error: Swift.Error? = nil

    public mutating func next() -> T? {
        do {
            return try closure()
        } catch {
            self.error = error
            return nil
        }
    }

    fileprivate init(_ closure: @escaping () throws -> T?) {
        self.closure = closure
    }

    private let closure: () throws -> T?
}

public enum ParserError: Swift.Error {
    case unexpectedEvent(UInt32)
    case undefinedAlias(String)
}

public final class Parser {
    // MARK: public
    public let yaml: String
    public let resolver: Resolver
    public let constructor: Constructor

    /// Set up Parser.
    ///
    /// - Parameter string: YAML
    /// - Parameter resolver: Resolver
    /// - Parameter constructor: Constructor
    /// - Throws: ParserError or YamlError
    public init(yaml string: String,
                resolver: Resolver = .default,
                constructor: Constructor = .default) throws {
        yaml = string
        self.resolver = resolver
        self.constructor = constructor

        yaml_parser_initialize(&parser)
#if USE_UTF16
        yaml_parser_set_encoding(&parser, YAML_UTF16BE_ENCODING)
        data = yaml.data(using: .utf16BigEndian)!
        data.withUnsafeBytes { bytes in
            yaml_parser_set_input_string(&parser, bytes, data.count)
        }
#else
        yaml_parser_set_encoding(&parser, YAML_UTF8_ENCODING)
        utf8CString = string.utf8CString
        utf8CString.withUnsafeBytes { bytes in
            let input = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
            yaml_parser_set_input_string(&parser, input, bytes.count - 1)
        }
#endif
        try expectNextEvent(oneOf: [YAML_STREAM_START_EVENT])
    }

    deinit {
        yaml_parser_delete(&parser)
    }

    /// Parse next document and return root Node.
    ///
    /// - Returns: next Node
    /// - Throws: ParserError or YamlError
    public func nextRoot() throws -> Node? {
        if streamEndProduced { return nil }
        switch try expectNextEvent(oneOf: [YAML_DOCUMENT_START_EVENT, YAML_STREAM_END_EVENT]) {
        case YAML_DOCUMENT_START_EVENT:
            let node = try loadNode(from: parse())
            try expectNextEvent(oneOf: [YAML_DOCUMENT_END_EVENT])
            return node
        default: // YAML_STREAM_END_EVENT
            return nil
        }
    }

    // MARK: private
    fileprivate var anchors = [String: Node]()
    fileprivate var parser = yaml_parser_t()
#if USE_UTF16
    private let data: Data
#else
    private let utf8CString: ContiguousArray<CChar>
#endif
}

extension ParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .undefinedAlias(alias): return "Undefined Alias: \(alias)"
        case let .unexpectedEvent(type): return "Unexpected event type: \(type)"
        }
    }
}

// MARK: implementation details
extension Parser {
    fileprivate var streamEndProduced: Bool {
        return parser.stream_end_produced != 0
    }

    @discardableResult
    fileprivate func expectNextEvent(oneOf eventTypes: [yaml_event_type_t]) throws -> yaml_event_type_t {
        let event = try parse()
        guard eventTypes.contains(event.type) else {
            throw ParserError.unexpectedEvent(event.type.rawValue)
        }
        return event.type
    }

    fileprivate func loadNode(from event: Event) throws -> Node {
        switch event.type {
        case YAML_ALIAS_EVENT:
            return try loadAlias(from: event)
        case YAML_SCALAR_EVENT:
            return try loadScalar(from: event)
        case YAML_SEQUENCE_START_EVENT:
            return try loadSequence(from: event)
        case YAML_MAPPING_START_EVENT:
            return try loadMapping(from: event)
        default:
            throw ParserError.unexpectedEvent(event.type.rawValue)
        }
    }

    fileprivate func parse() throws -> Event {
        let event = Event()
        guard yaml_parser_parse(&parser, &event.event) == 1 else {
            throw YamlError(from: parser)
        }
        return event
    }

    private func loadAlias(from event: Event) throws -> Node {
        guard let alias = event.aliasAnchor else {
            throw ParserError.undefinedAlias("(empty)")
        }
        guard let node = anchors[alias] else {
            throw ParserError.undefinedAlias(alias)
        }
        return node
    }

    private func loadScalar(from event: Event) throws -> Node {
        let node = Node.scalar(event.scalarValue, Tag(event.scalarTag, resolver, constructor))
        if let anchor = event.scalarAnchor {
            anchors[anchor] = node
        }
        return node
    }

    private func loadSequence(from firstEvent: Event) throws -> Node {
        var array = [Node]()
        var event = try parse()
        while event.type != YAML_SEQUENCE_END_EVENT {
            array.append(try loadNode(from: event))
            event = try parse()
        }
        let node = Node.sequence(array, Tag(firstEvent.sequenceTag, resolver, constructor))
        if let anchor = firstEvent.sequenceAnchor {
            anchors[anchor] = node
        }
        return node
    }

    private func loadMapping(from firstEvent: Event) throws -> Node {
        var pairs = [Pair<Node>]()
        var event = try parse()
        while event.type != YAML_MAPPING_END_EVENT {
            let key = try loadNode(from: event)
            event = try parse()
            let value = try loadNode(from: event)
            pairs.append(Pair(key, value))
            event = try parse()
        }
        let node = Node.mapping(pairs, Tag(firstEvent.mappingTag, resolver, constructor))
        if let anchor = firstEvent.mappingAnchor {
            anchors[anchor] = node
        }
        return node
    }
}

/// Representation of `yaml_event_t`
fileprivate class Event {
    var event = yaml_event_t()
    deinit { yaml_event_delete(&event) }

    var type: yaml_event_type_t {
        return event.type
    }

    // alias
    var aliasAnchor: String? {
        return string(from: event.data.alias.anchor)
    }

    // scalar
    var scalarAnchor: String? {
        return string(from: event.data.scalar.anchor)
    }
    var scalarTag: String? {
        guard event.data.scalar.plain_implicit == 0,
            event.data.scalar.quoted_implicit == 0 else {
                return nil
        }
        return string(from: event.data.scalar.tag)
    }
    var scalarValue: String {
        // scalar may contain NULL characters
        let buffer = UnsafeBufferPointer(start: event.data.scalar.value,
                                         count: event.data.scalar.length)
        // libYAML convert scalar characters into UTF8 if input is other than YAML_UTF8_ENCODING
        return String(bytes: buffer, encoding: .utf8)!
    }

    // sequence
    var sequenceAnchor: String? {
        return string(from: event.data.sequence_start.anchor)
    }
    var sequenceTag: String? {
        return event.data.sequence_start.implicit != 0
            ? nil : string(from: event.data.sequence_start.tag)
    }

    // mapping
    var mappingAnchor: String? {
        return string(from: event.data.scalar.anchor)
    }
    var mappingTag: String? {
        return event.data.mapping_start.implicit != 0
            ? nil : string(from: event.data.sequence_start.tag)
    }
}

fileprivate func string(from pointer: UnsafePointer<UInt8>!) -> String? {
    return String.decodeCString(pointer, as: UTF8.self, repairingInvalidCodeUnits: true)?.result
}
