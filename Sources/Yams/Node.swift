//
//  Node.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public enum Node {
    case scalar(String, Tag, Scalar.Style)
    case mapping([Pair<Node>], Tag, Mapping.Style)
    case sequence([Node], Tag, Sequence.Style)
}

extension Node {
    public init(_ string: String, _ tag: Tag.Name = .implicit, _ style: Scalar.Style = .any) {
        self = .scalar(string, Tag(tag), style)
    }
}

extension Node {
    public struct Scalar {
        public var string: String
        public var tag: Tag
        public var style: Style

        public enum Style: UInt32 { // swiftlint:disable:this nesting
            /// Let the emitter choose the style.
            case any = 0
            /// The plain scalar style.
            case plain

            /// The single-quoted scalar style.
            case singleQuoted
            /// The double-quoted scalar style.
            case doubleQuoted

            /// The literal scalar style.
            case literal
            /// The folded scalar style.
            case folded
        }
    }

    public var scalar: Scalar? {
        get {
            if case let .scalar(string, tag, style) = self {
                return Scalar(string: string, tag: tag, style: style)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = .scalar(newValue.string, newValue.tag, newValue.style)
            }
        }
    }

    public struct Mapping {
        public var pairs: [Pair<Node>]
        public var tag: Tag
        public var style: Style

        public enum Style: UInt32 { // swiftlint:disable:this nesting
            /// Let the emitter choose the style.
            case any
            /// The block mapping style.
            case block
            /// The flow mapping style.
            case flow
        }
    }

    public var mapping: Mapping? {
        get {
            if case let .mapping(pairs, tag, style) = self {
                return Mapping(pairs: pairs, tag: tag, style: style)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = .mapping(newValue.pairs, newValue.tag, newValue.style)
            }
        }
    }

    public struct Sequence {
        public var nodes: [Node]
        public var tag: Tag
        public var style: Style

        public enum Style: UInt32 { // swiftlint:disable:this nesting
            /// Let the emitter choose the style.
            case any
            /// The block sequence style.
            case block
            /// The flow sequence style.
            case flow
        }
    }

    public var sequence: Sequence? {
        get {
            if case let .sequence(nodes, tag, style) = self {
                return Sequence(nodes: nodes, tag: tag, style: style)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = .sequence(newValue.nodes, newValue.tag, newValue.style)
            }
        }
    }

}

public struct Pair<Value: Comparable & Equatable>: Comparable, Equatable {
    let key: Value
    let value: Value

    init(_ key: Value, _ value: Value) {
        self.key = key
        self.value = value
    }

    public static func == (lhs: Pair, rhs: Pair) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }

    public static func < (lhs: Pair<Value>, rhs: Pair<Value>) -> Bool {
        return lhs.key < rhs.key
    }
}

extension Node {
    /// Accessing this property causes the tag to be resolved by tag.resolver.
    public var tag: Tag {
        switch self {
        case let .scalar(_, tag, _): return tag.resolved(with: self)
        case let .mapping(_, tag, _): return tag.resolved(with: self)
        case let .sequence(_, tag, _): return tag.resolved(with: self)
        }
    }

    // MARK: typed accessor properties
    public var any: Any {
        return tag.constructor.any(from: self)
    }

    public var string: String? {
        return String.construct(from: self)
    }

    public var bool: Bool? {
        return Bool.construct(from: self)
    }

    public var float: Double? {
        return Double.construct(from: self)
    }

    public var null: NSNull? {
        return NSNull.construct(from: self)
    }

    public var int: Int? {
        return Int.construct(from: self)
    }

    public var binary: Data? {
        return Data.construct(from: self)
    }

    public var timestamp: Date? {
        return Date.construct(from: self)
    }

    // MARK: Typed accessor methods

    /// - Returns: Array of `Node`
    public func array() -> [Node] {
        guard let nodes = sequence?.nodes else {
            return []
        }
        return nodes
    }

    /// Typed Array using cast: e.g. `array() as [String]`
    ///
    /// - Returns: Array of `Type`
    public func array<Type: ScalarConstructible>() -> [Type] {
        guard let nodes = sequence?.nodes else {
            return []
        }
        return nodes.flatMap(Type.construct)
    }

    /// Typed Array using type parameter: e.g. `array(of: String.self)`
    ///
    /// - Parameter type: Type conforms to ScalarConstructible
    /// - Returns: Array of `Type`
    public func array<Type: ScalarConstructible>(of type: Type.Type) -> [Type] {
        guard let nodes = sequence?.nodes else {
            return []
        }
        return nodes.flatMap(Type.construct)
    }

    public subscript(node: Node) -> Node? {
        switch self {
        case .scalar: return nil
        case let .mapping(pairs, _, _):
            return pairs.reversed().first(where: { $0.key == node })?.value
        case let .sequence(nodes, _, _):
            guard let index = node.int, 0 <= index, index < nodes.count else { return nil }
            return nodes[index]
        }
    }
}

// MARK: Hashable
extension Node: Hashable {
    public var hashValue: Int {
        switch self {
        case let .scalar(value, _, _):
            return value.hashValue
        case let .mapping(pairs, _, _):
            return pairs.count
        case let .sequence(array, _, _):
            return array.count
        }
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhsValue, lhsTag, _), .scalar(rhsValue, rhsTag, _)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        case let (.mapping(lhsValue, lhsTag, _), .mapping(rhsValue, rhsTag, _)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        case let (.sequence(lhsValue, lhsTag, _), .sequence(rhsValue, rhsTag, _)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        default:
            return false
        }
    }
}

extension Node: Comparable {
    public static func <(lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhsValue, _, _), .scalar(rhsValue, _, _)):
            return lhsValue < rhsValue
        case let (.mapping(lhsValue, _, _), .mapping(rhsValue, _, _)):
            return lhsValue < rhsValue
        case let (.sequence(lhsValue, _, _), .sequence(rhsValue, _, _)):
            return lhsValue < rhsValue
        default:
            return false
        }
    }
}

extension Array where Element: Comparable {
    static func < (lhs: Array, rhs: Array) -> Bool {
        for (lhs, rhs) in zip(lhs, rhs) {
            if lhs < rhs {
                return true
            } else if lhs > rhs {
                return false
            }
        }
        return lhs.count < rhs.count
    }
}

// MARK: - ExpressibleBy*Literal
extension Node: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Node...) {
        self = .sequence(elements, .implicit, .any)
    }
}

extension Node: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Node, Node)...) {
        self = .mapping(elements.map(Pair.init), .implicit, .any)
    }
}

extension Node: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .scalar(String(value), Tag(.float), .any)
    }
}

extension Node: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .scalar(String(value), Tag(.int), .any)
    }
}

extension Node: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .scalar(value, .implicit, .any)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .scalar(value, .implicit, .any)
    }

    public init(unicodeScalarLiteral value: String) {
        self = .scalar(value, .implicit, .any)
    }
}

extension Node {
    // MARK: Internal convenience accessors
    var isScalar: Bool {
        if case .scalar = self {
            return true
        }
        return false
    }

    var isMapping: Bool {
        if case .mapping = self {
            return true
        }
        return false
    }

    var isSequence: Bool {
        if case .sequence = self {
            return true
        }
        return false
    }
}
