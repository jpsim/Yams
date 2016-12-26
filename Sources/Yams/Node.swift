//
//  Node.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public enum Node {
    case scalar(String, Tag)
    case mapping([Pair<Node>], Tag)
    case sequence([Node], Tag)
}

public struct Pair<Value: Equatable>: Equatable {
    let key: Value
    let value: Value

    init(_ key: Value, _ value: Value) {
        self.key = key
        self.value = value
    }

    public static func == (lhs: Pair, rhs: Pair) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}

extension Node {
    public var tag: Tag {
        switch self {
        case let .scalar(_, tag): return tag.resolved(with: self)
        case let .mapping(_, tag): return tag.resolved(with: self)
        case let .sequence(_, tag): return tag.resolved(with: self)
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

    public subscript(node: Node) -> Node? {
        switch self {
        case .scalar: return nil
        case let .mapping(pairs, _):
            return pairs.reversed().first(where: { $0.key == node })?.value
        case let .sequence(sequence, _):
            guard let index = node.int, 0 <= index, index < sequence.count else { return nil }
            return sequence[index]
        }
    }
}

// MARK: Hashable
extension Node: Hashable {
    public var hashValue: Int {
        switch self {
        case let .scalar(value, _):
            return value.hashValue
        case let .mapping(pairs, _):
            return pairs.count
        case let .sequence(array, _):
            return array.count
        }
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhsValue, lhsTag), .scalar(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        case let (.mapping(lhsValue, lhsTag), .mapping(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        case let (.sequence(lhsValue, lhsTag), .sequence(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag.resolved(with: lhs) == rhsTag.resolved(with: rhs)
        default:
            return false
        }
    }
}

// MARK: - ExpressibleBy*Literal
extension Node: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Node...) {
        self = .sequence(elements, .implicit)
    }
}

extension Node: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Node, Node)...) {
        self = .mapping(elements.map(Pair.init), .implicit)
    }
}

extension Node: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .scalar(String(value), Tag(.float, .default, .default))
    }
}

extension Node: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .scalar(String(value), Tag(.int, .default, .default))
    }
}

extension Node: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .scalar(value, .implicit)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .scalar(value, .implicit)
    }

    public init(unicodeScalarLiteral value: String) {
        self = .scalar(value, .implicit)
    }
}

extension Node {
    // MARK: Internal convenient accessor
    var sequence: [Node]? {
        if case let .sequence(sequence, _) = self {
            return sequence
        }
        return nil
    }

    var pairs: [Pair<Node>]? {
        if case let .mapping(pairs, _) = self {
            return pairs
        }
        return nil
    }

    var scalar: String? {
        if case let .scalar(scalar, _) = self {
            return scalar
        }
        return nil
    }

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
