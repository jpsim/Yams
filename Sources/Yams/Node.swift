//
//  Node.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public enum Node {
    case scalar(Scalar)
    case mapping([Pair<Node>], Tag, Mapping.Style)
    case sequence([Node], Tag, Sequence.Style)
}

extension Node {
    public init(_ string: String, _ tag: Tag.Name = .implicit, _ style: Scalar.Style = .any) {
        self = .scalar(.init(string, Tag(tag), style))
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

        public init(_ string: String, _ tag: Tag = .implicit, _ style: Style = .any) {
            self.string = string
            self.tag = tag
            self.style = style
        }
    }

    public var scalar: Scalar? {
        get {
            if case let .scalar(scalar) = self {
                return scalar
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = .scalar(newValue)
            }
        }
    }

    public struct Mapping {
        internal var pairs: [Pair<Node>]
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
        internal var nodes: [Node]
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
        case let .scalar(scalar): return scalar.tag.resolved(with: self)
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
        get {
            switch self {
            case .scalar: return nil
            case let .mapping(pairs, _, _):
                return pairs.reversed().first(where: { $0.key == node })?.value
            case let .sequence(nodes, _, _):
                guard let index = node.int, 0 <= index, index < nodes.count else { return nil }
                return nodes[index]
            }
        }
        set {
            guard let newValue = newValue else { return }
            switch self {
            case .scalar: return
            case .mapping(var pairs, let tag, let style):
                if let index = pairs.index(where: { $0.key == node }) {
                    pairs[index] = Pair(pairs[index].key, newValue)
                    self = .mapping(pairs, tag, style)
                }
            case .sequence(var nodes, let tag, let style):
                guard let index = node.int, 0 <= index, index < nodes.count else { return}
                nodes[index] = newValue
                self = .sequence(nodes, tag, style)
            }
        }
    }

    public subscript(representable: NodeRepresentable) -> Node? {
        get {
            guard let node = try? representable.represented() else { return nil }
            return self[node]
        }
        set {
            guard let node = try? representable.represented() else { return }
            self[node] = newValue
        }
    }

    public subscript(string: String) -> Node? {
        get {
            return self[Node(string)]
        }
        set {
            self[Node(string)] = newValue
        }
    }
}

// MARK: Hashable
extension Node: Hashable {
    public var hashValue: Int {
        switch self {
        case let .scalar(scalar):
            return scalar.string.hashValue
        case let .mapping(pairs, _, _):
            return pairs.count
        case let .sequence(array, _, _):
            return array.count
        }
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhsValue), .scalar(rhsValue)):
            return lhsValue.string == rhsValue.string &&
                lhsValue.tag.resolved(with: lhs) == rhsValue.tag.resolved(with: rhs)
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
    public static func < (lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhs), .scalar(rhs)):
            return lhs.string < rhs.string
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
        self = .scalar(.init(String(value), Tag(.float)))
    }
}

extension Node: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .scalar(.init(String(value), Tag(.int)))
    }
}

extension Node: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .scalar(.init(value))
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .scalar(.init(value))
    }

    public init(unicodeScalarLiteral value: String) {
        self = .scalar(.init(value))
    }
}

// MARK: - Node.Mapping

extension Node.Mapping: Equatable {
    public static func == (lhs: Node.Mapping, rhs: Node.Mapping) -> Bool {
        return lhs.pairs == rhs.pairs
    }
}

extension Node.Mapping: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Node, Node)...) {
        self.init(pairs: elements.map(Pair.init), tag: .implicit, style: .any)
    }
}

extension Node.Mapping: MutableCollection {
    public typealias Element = (key: Node, value: Node)

    // Sequence
    public func makeIterator() -> Array<Element>.Iterator {
        let iterator = pairs.map({ (key: $0.key, value: $0.value) }).makeIterator()
        return iterator
    }

    // Collection
    public typealias Index = Array<Element>.Index

    public var startIndex: Int {
        return pairs.startIndex
    }

    public var endIndex: Int {
        return pairs.endIndex
    }

    public func index(after index: Int) -> Int {
        return pairs.index(after:index)
    }

    public subscript(index: Int) -> Element {
        get {
            return (key: pairs[index].key, value: pairs[index].value)
        }
        // MutableCollection
        set {
            pairs[index] = Pair(newValue.key, newValue.value)
        }
    }
}

extension Node.Mapping {
    public var keys: LazyMapCollection<Node.Mapping, Node> {
        return lazy.map { $0.key }
    }

    public var values: LazyMapCollection<Node.Mapping, Node> {
        return lazy.map { $0.value }
    }

    public subscript(string: String) -> Node? {
        get {
            return self[Node(string)]
        }
        set {
            self[Node(string)] = newValue
        }
    }

    public subscript(node: Node) -> Node? {
        get {
            let v = pairs.reversed().first(where: { $0.key == node })
            return v?.value
        }
        set {
            if let newValue = newValue {
                if let index = pairs.reversed().index(where: { $0.key == node }) {
                    let actualIndex = pairs.index(before: index.base)
                    pairs[actualIndex] = Pair(pairs[actualIndex].key, newValue)
                } else {
                    pairs.append(Pair(node, newValue))
                }
            } else {
                if let index = pairs.reversed().index(where: { $0.key == node }) {
                    let actualIndex = pairs.index(before: index.base)
                    pairs.remove(at: actualIndex)
                }
            }
        }
    }
}

// MARK: - Node.Sequence

extension Node.Sequence: Equatable {
    public static func == (lhs: Node.Sequence, rhs: Node.Sequence) -> Bool {
        return lhs.nodes == rhs.nodes
    }
}

extension Node.Sequence: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Node...) {
        self.init(nodes: elements, tag: .implicit, style: .any)
    }
}

extension Node.Sequence: MutableCollection {
    // Sequence
    public func makeIterator() -> Array<Node>.Iterator {
        return nodes.makeIterator()
    }

    // Collection
    public typealias Index = Array<Node>.Index

    public var startIndex: Index {
        return nodes.startIndex
    }

    public var endIndex: Index {
        return nodes.endIndex
    }

    public func index(after index: Index) -> Index {
        return nodes.index(after: index)
    }

    public subscript(index: Index) -> Node {
        get {
            return nodes[index]
        }
        // MutableCollection
        set {
            nodes[index] = newValue
        }
    }

    public subscript(bounds: Range<Index>) -> Array<Node>.SubSequence {
        get {
            return nodes[bounds]
        }
        // MutableCollection
        set {
            nodes[bounds] = newValue
        }
    }

    public var indices: Array<Node>.Indices {
        return nodes.indices
    }
}

extension Node.Sequence: RandomAccessCollection {
    // BidirectionalCollection
    public func index(before index: Index) -> Index {
        return nodes.index(before: index)
    }

    // RandomAccessCollection
    public func index(_ index: Index, offsetBy num: Int) -> Index {
        return nodes.index(index, offsetBy: num)
    }

    public func distance(from start: Index, to end: Int) -> Index {
        return nodes.distance(from: start, to: end)
    }
}

extension Node.Sequence: RangeReplaceableCollection {
    public init() {
        self.init(nodes: [], tag: .implicit, style: .any)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
        where C : Collection, C.Iterator.Element == Node {
            nodes.replaceSubrange(subrange, with: newElements)
    }
}

// MARK: - internal

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

// swiftlint:disable:this file_length
