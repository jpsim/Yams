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
    case mapping([(Node,Node)], Tag)
    case sequence([Node], Tag)
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
                dictionary[$0.0] = $0.1
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
        case let .scalar(value, tag):
            return tag == .implicit ? value.hashValue : (value + tag.description).hashValue
        case let .mapping(pairs, _):
            return pairs.count
        case let .sequence(array, _):
            return array.count
        }
    }

    public static func ==(lhs: Node, rhs: Node) -> Bool {
        switch (lhs, rhs) {
        case let (.scalar(lhsValue, lhsTag), .scalar(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag == rhsTag
        case let (.mapping(lhsValue, lhsTag), .mapping(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag == rhsTag
        case let (.sequence(lhsValue, lhsTag), .sequence(rhsValue, rhsTag)):
            return lhsValue == rhsValue && lhsTag == rhsTag
        default:
            return false
        }
    }
}

// MARK
extension Node: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Node...) {
        self = .sequence(elements, .implicit)
    }
}

// MARK: ExpressibleByDictionaryLiteral
extension Node: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Node, Node)...) {
        self = .mapping(elements, .implicit)
    }
}

extension Node: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .scalar(String(value), .implicit)
    }
}

// MARK: ExpressibleByStringLiteral
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

// Define `==` between arrays of tuples, because tuple can not be Equatable
fileprivate func ==<A: Equatable, B: Equatable>(lhs: [(A, B)], rhs: [(A, B)]) -> Bool {
    let lhsCount = lhs.count
    if lhsCount != rhs.count {
        return false
    }

    // Test referential equality.
    if lhsCount == 0 /* || lhs._buffer.identity == rhs._buffer.identity */ {
        return true
    }

    for idx in 0..<lhsCount {
        if lhs[idx] != rhs[idx] {
            return false
        }
    }

    return true
}
