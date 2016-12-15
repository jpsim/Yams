//
//  Resolver.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public protocol ResolverProtocol {
    init(resolve scalar: Node)
    var toAny: Any { get }
    var isNull: Bool { get }
    var toBool: Bool? { get }
    var toInt: Int? { get }
    var toFloat: Double? { get }
}

public struct Resolver {
    /// Failsafe Schema <http://www.yaml.org/spec/1.2/spec.html#id2802346>
    public struct Failsafe {
        fileprivate let node: Node
    }
    /// JSON Schema <http://www.yaml.org/spec/1.2/spec.html#id2803231>
    public struct JSON {
        fileprivate let node: Node
    }
    /// Core Schema <http://www.yaml.org/spec/1.2/spec.html#id2804923>
    public struct Core {
        fileprivate let node: Node
    }
    /// Core+ Schema <http://yaml.org/type/index.html>
//    public struct CorePlus {
//        fileprivate let node: Node
//    }
}

extension Resolver.Failsafe: ResolverProtocol {
    public init(resolve scalar: Node) {
        node = scalar
    }

    public var toAny: Any { return node.string ?? NSNull() }
    public var isNull: Bool { return false }
    public var toBool: Bool? { return nil }
    public var toInt: Int? { return nil }
    public var toFloat: Double? { return nil }
}

extension Resolver.JSON: ResolverProtocol {
    public init(resolve scalar: Node) {
        node = scalar
    }

    public var toAny: Any {
        if isNull { return NSNull() }
        return toBool ?? toInt ?? toFloat ?? node.string ?? NSNull()
    }

    public var isNull: Bool {
        guard node.tag.may(be: .null) else { return false }
        return node.string == "null"
    }

    public var toBool: Bool? {
        guard node.tag.may(be: .bool), let string = node.string else { return nil }
        switch string {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }

    public var toInt: Int? {
        guard node.tag.may(be: .int), let string = node.string else { return nil }
        if string.hasPrefix("+") {
            return nil
        }
        return Int(string)
    }

    public var toFloat: Double? {
        guard node.tag.may(be: .float), let string = node.string else { return nil }
        switch string {
        case ".inf": return .infinity
        case "-.inf": return -.infinity
        case ".nan": return .nan
        default: return Double(string)
        }
    }
}

extension Resolver.Core: ResolverProtocol {
    public init(resolve scalar: Node) {
        node = scalar
    }

    public var toAny: Any {
        if isNull { return NSNull() }
        return toBool ?? toInt ?? toFloat ?? node.string ?? NSNull()
    }

    public var isNull: Bool {
        guard node.tag.may(be: .null), let string = node.string else { return false }
        switch string {
        case "~", "null", "Null", "NULL":
            return true
        default:
            return false
        }
    }

    public var toBool: Bool? {
        guard node.tag.may(be: .bool), let string = node.string else { return nil }
        switch string {
        case "true", "True", "TRUE":
            return true
        case "false", "False", "FALSE":
            return false
        default:
            return nil
        }
    }

    public var toInt: Int? {
        guard node.tag.may(be: .int), let string = node.string else { return nil }
        if string.hasPrefix("0x") {
            let hexadecimal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(hexadecimal, radix: 16)
        }
        if string.hasPrefix("0o") {
            let octal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(octal, radix: 8)
        }
        return Int(string)
    }

    public var toFloat: Double? {
        guard node.tag.may(be: .float), let string = node.string else { return nil }
        switch string {
        case ".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF":
            return .infinity
        case "-.inf", "-.Inf", "-.INF":
            return -.infinity
        case ".nan", ".NaN", ".NAN":
            return .nan
        default:
            return Double(string)
        }
    }
}

#if os(Linux)
    typealias NSRegularExpression = RegularExpression
#endif

extension NSRegularExpression {
    fileprivate func matches(in string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        if let match = firstMatch(in: string, options: [], range: range) {
            return match.range.location != NSNotFound
        }
        return false
    }
}

