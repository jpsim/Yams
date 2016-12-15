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
    case mapping([Node:Node], Tag)
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
        if case let .mapping(dictionary, _) = self {
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
}

// MARK: Hashable
extension Node: Hashable {
    public var hashValue: Int {
        switch self {
        case let .scalar(value, tag):
            return tag == .implicit ? value.hashValue : (value + tag.description).hashValue
        case let .mapping(dictionary, _):
            return (dictionary.first?.key.hashValue) ?? 0
        case let .sequence(array, _):
            return array.first?.hashValue ?? 0
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
        var dictionary = [Node:Node](minimumCapacity: elements.count)
        elements.forEach {
            dictionary[$0] = $1
        }
        self = .mapping(dictionary, .implicit)
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
