//
//  Emitter.swift
//  Yams
//
//  Created by Norio Nomura on 12/28/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

#if SWIFT_PACKAGE
    import CYaml
#endif
import Foundation

public func serialize_all<S>(
    nodes: S,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: yaml_break_t = YAML_ANY_BREAK,
    encoding: yaml_encoding_t = YAML_ANY_ENCODING,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil) throws -> String
    where S: Sequence, S.Iterator.Element == Node {
        let emitter = Emitter(
            canonical: canonical,
            indent: indent,
            width: width,
            allowUnicode: allowUnicode,
            lineBreak: lineBreak,
            encoding: encoding,
            explicitStart: explicitStart,
            explicitEnd: explicitEnd,
            version: version)
        try emitter.open()
        try nodes.forEach(emitter.serialize)
        try emitter.close()
        return emitter.stream
}

public func serialize(
    node: Node,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: yaml_break_t = YAML_ANY_BREAK,
    encoding: yaml_encoding_t = YAML_ANY_ENCODING,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil) throws -> String {
        let emitter = Emitter(
            canonical: canonical,
            indent: indent,
            width: width,
            allowUnicode: allowUnicode,
            lineBreak: lineBreak,
            encoding: encoding,
            explicitStart: explicitStart,
            explicitEnd: explicitEnd,
            version: version)
        try emitter.open()
        try emitter.serialize(node: node)
        try emitter.close()
        return emitter.stream
}

public enum EmitterError: Swift.Error {
    case invalidState(String)
}

public final class Emitter {
    public var stream = ""

    let documentStartImplicit: Int32
    let documentEndImplicit: Int32
    let encoding: yaml_encoding_t
    let version: (major: Int, minor: Int)?

    public init(canonical: Bool = false,
                indent: Int = 0,
                width: Int = 0,
                allowUnicode: Bool = false,
                lineBreak: yaml_break_t = YAML_ANY_BREAK,
                encoding: yaml_encoding_t = YAML_ANY_ENCODING,
                explicitStart: Bool = false,
                explicitEnd: Bool = false,
                version: (major: Int, minor: Int)? = nil) {
        documentStartImplicit = explicitStart ? 0 : 1
        documentEndImplicit = explicitStart ? 0 : 1
        self.encoding = encoding
        self.version = version

        // configure emitter
        yaml_emitter_initialize(&emitter)

        yaml_emitter_set_output(&self.emitter, { pointer, buffer, size in
            let buffer = UnsafeBufferPointer(start: buffer, count: size)
            let encoding: String.Encoding
            #if USE_UTF16
                encoding = .utf16BigEndian
            #else
                encoding = .utf8
            #endif
            guard let string = String(bytes: buffer, encoding: encoding) else {
                return 0
            }
            let emitter = unsafeBitCast(pointer, to: Emitter.self)
            emitter.stream.write(string)
            return 1
        }, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))

        yaml_emitter_set_canonical(&emitter, canonical ? 1 : 0)
        yaml_emitter_set_indent(&emitter, Int32(indent))
        yaml_emitter_set_width(&emitter, Int32(width))
        yaml_emitter_set_unicode(&emitter, allowUnicode ? 1 : 0)
        yaml_emitter_set_break(&emitter, lineBreak)
        yaml_emitter_set_encoding(&emitter, encoding)
    }

    deinit {
        yaml_emitter_delete(&emitter)
    }

    public func open() throws {
        switch state {
        case .initialized:
            var event = yaml_event_t()
            yaml_stream_start_event_initialize(&event, encoding)
            try emit(&event)
            state = .opened
        case .opened:
            throw EmitterError.invalidState("serializer is already opened")
        case .closed:
            throw EmitterError.invalidState("serializer is closed")
        }
    }

    public func close() throws {
        switch state {
        case .initialized:
            throw EmitterError.invalidState("serializer is not opened")
        case .opened:
            var event = yaml_event_t()
            yaml_stream_end_event_initialize(&event)
            try emit(&event)
            state = .closed
        case .closed:
            break // do nothing
        }
    }

    public func serialize(node: Node) throws {
        switch state {
        case .initialized:
            throw EmitterError.invalidState("serializer is not opened")
        case .opened:
            break
        case .closed:
            throw EmitterError.invalidState("serializer is closed")
        }
        var event = yaml_event_t()
        var versionDirective: UnsafeMutablePointer<yaml_version_directive_t>?
        var versionDirectiveValue = yaml_version_directive_t()
        if let (major, minor) = version {
            versionDirectiveValue.major = Int32(major)
            versionDirectiveValue.minor = Int32(minor)
            versionDirective = UnsafeMutablePointer(&versionDirectiveValue)
        }
        // TODO: Support tags
        yaml_document_start_event_initialize(&event, versionDirective, nil, nil, documentStartImplicit)
        try emit(&event)
        try serializeNode(node)
        yaml_document_end_event_initialize(&event, documentEndImplicit)
        try emit(&event)
    }

    // private
    fileprivate var emitter = yaml_emitter_t()

    fileprivate enum State { case initialized, opened, closed }
    fileprivate var state: State = .initialized
}

// MARK: implementation details
extension Emitter {
    fileprivate func emit(_ event: UnsafeMutablePointer<yaml_event_t>) throws {
        guard yaml_emitter_emit(&emitter, event) == 1 else {
            throw YamlError(from: emitter)
        }
    }

    fileprivate func serializeNode(_ node: Node) throws {
        switch node {
        case .scalar: try serializeScalarNode(node)
        case .sequence: try serializeSequenceNode(node)
        case .mapping: try serializeMappingNode(node)
        }
    }

    private func serializeScalarNode(_ node: Node) throws {
        assert(node.isScalar) // swiftlint:disable:next force_unwrapping
        var value = node.scalar!.utf8CString, tag = node.tag.name!.rawValue.utf8CString
        let implicit: Int32 = node.tag.name == .str ? 1 : 0
        var event = yaml_event_t()
        _ = value.withUnsafeMutableBytes { value in
            tag.withUnsafeMutableBytes { tag in
                yaml_scalar_event_initialize(
                    &event,
                    nil,
                    tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    value.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32(value.count - 1),
                    0,
                    implicit,
                    YAML_ANY_SCALAR_STYLE)
            }
        }
        try emit(&event)
    }

    private func serializeSequenceNode(_ node: Node) throws {
        assert(node.isSequence) // swiftlint:disable:next force_unwrapping
        var sequence = node.sequence!, tag = node.tag.name!.rawValue.utf8CString
        let implicit: Int32 = node.tag.name == .seq ? 1 : 0
        let sequence_style = YAML_BLOCK_SEQUENCE_STYLE
        var event = yaml_event_t()
        _ = tag.withUnsafeMutableBytes { tag in
            yaml_sequence_start_event_initialize(
                &event,
                nil,
                tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                implicit,
                sequence_style)
        }
        try emit(&event)
        try sequence.forEach(self.serializeNode)
        yaml_sequence_end_event_initialize(&event)
        try emit(&event)
    }

    private func serializeMappingNode(_ node: Node) throws {
        assert(node.isMapping) // swiftlint:disable:next force_unwrapping
        var pairs = node.pairs!, tag = node.tag.name!.rawValue.utf8CString
        let implicit: Int32 = node.tag.name == Tag.Name.map ? 1 : 0
        let mapping_style = YAML_BLOCK_MAPPING_STYLE
        var event = yaml_event_t()
        _ = tag.withUnsafeMutableBytes { tag in
            yaml_mapping_start_event_initialize(
                &event,
                nil,
                tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                implicit,
                mapping_style)
        }
        try emit(&event)
        try pairs.forEach { pair in
            try self.serializeNode(pair.key)
            try self.serializeNode(pair.value)
        }
        yaml_mapping_end_event_initialize(&event)
        try emit(&event)
    }
}
