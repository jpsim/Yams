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

    public static func ==(lhs: Pair, rhs: Pair) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}

extension Node {
    // MARK: typed access properties
    public var array: [Node]? {
        if case let .sequence(array, _) = self {
            return array
        }
        return nil
    }

    public var dictionary: [Node:Node]? {
        if case let .mapping(pairs, _) = self {
            var dictionary = [Node:Node](minimumCapacity: pairs.count)
            pairs.forEach {
                dictionary[$0.key] = $0.value
            }
            return dictionary
        }
        return nil
    }

    public var string: String? {
        if case let .scalar(string, _) = self {
            return string
        }
        return nil
    }
    
    public var tag: Tag {
        switch self {
        case let .scalar(_, tag): return tag
        case let .mapping(_, tag): return tag
        case let .sequence(_, tag): return tag
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

    public static func ==(lhs: Node, rhs: Node) -> Bool {
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
        self = .scalar(String(value), .implicit)
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
