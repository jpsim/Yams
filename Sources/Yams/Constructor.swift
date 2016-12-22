//
//  Constructor.swift
//  Yams
//
//  Created by Norio Nomura on 12/21/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public final class Constructor {
    public typealias Method = (Constructor) -> (Node) -> Any
    let tagMethodMap: [Tag.Name:Method]

    public init(_ map: [Tag.Name:Method]) {
        tagMethodMap = map
    }

    public func any(from node: Node) -> Any {
        if let tagName = node.tag.name, let method = tagMethodMap[tagName] {
            return method(self)(node)
        }
        switch node {
        case .scalar:
            return str(from: node)
        case .mapping:
            return map(from: node)
        case .sequence:
            return seq(from: node)
        }
    }

    func flatten_mapping(_ node: Node) -> Node {
        guard var pairs = node.pairs else { fatalError("Never happen this") }
        var merge = [Pair<Node>]()
        var index = pairs.startIndex
        while index < pairs.count {
            let pair = pairs[index]
            if pair.key.tag.name == .merge {
                pairs.remove(at: index)
                switch pair.value {
                case .mapping:
                    let flattened_node = flatten_mapping(pair.value)
                    if let pairs = flattened_node.pairs {
                        merge.append(contentsOf: pairs)
                    }
                case let .sequence(array, _):
                    let submerge = array
                        .filter { $0.isMapping } // TODO: Should raise error on other than mapping
                        .flatMap { flatten_mapping($0).pairs }
                        .reversed()
                    submerge.forEach {
                        merge.append(contentsOf: $0)
                    }
                default:
                    break // TODO: Should raise error on other than mapping or sequence
                }
            } else if pair.key.tag.name == .value {
                pair.key.tag.name = .str
                index += 1
            } else {
                index += 1
            }
        }
        return .mapping(merge + pairs, node.tag)
    }

    public func map(from node: Node) -> [AnyHashable:Any] {
        guard let pairs = flatten_mapping(node).pairs else { fatalError("Never happen this") }
        var dictionary = [AnyHashable:Any](minimumCapacity: pairs.count)
        pairs.forEach {
            // TODO: YAML supports keys other than str.
            dictionary[str(from: $0.key)] = any(from: $0.value)
        }
        return dictionary
    }

    public func str(from node: Node) -> String {
        if case let .mapping(pairs, _) = node {
            for pair in pairs where pair.key.tag.name == .value {
                return str(from: pair.value)
            }
        }
        guard let string = node.string else { fatalError("Never happen this") }
        return string
    }

    public func seq(from node: Node) -> [Any] {
        guard let array = node.array else { fatalError("Never happen this") }
        return array.map { any(from: $0) }
    }

    public func bool(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        switch string {
        case "true", "True", "TRUE":
            return true
        case "false", "False", "FALSE":
            return false
        default:
            return string
        }
    }

    public func float(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        switch string {
        case ".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF":
            return Double.infinity
        case "-.inf", "-.Inf", "-.INF":
            return -Double.infinity
        case ".nan", ".NaN", ".NAN":
            return Double.nan
        default:
            return Double(string) ?? string
        }
    }

    public func null(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        switch string {
        case "~", "null", "Null", "NULL":
            return NSNull()
        default:
            return string
        }
    }

    public func int(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        if string.hasPrefix("0x") {
            let hexadecimal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(hexadecimal, radix: 16) ?? string
        }
        if string.hasPrefix("0o") {
            let octal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(octal, radix: 8) ?? string
        }
        if string.hasPrefix("0b") {
            let octal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(octal, radix: 2) ?? string
        }
        return Int(string) ?? string
    }

    public func binary(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters)
        return data ?? string
    }

    public func timestamp(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        return ISO8601Formatter.date(from: string) ?? string
    }
}

extension Constructor {
    public static let `default` = Constructor([
        // Failsafe Schema
        .str: Constructor.str,
        .seq: Constructor.seq,
        .map: Constructor.map,
        // JSON Schema
        .bool: Constructor.bool,
        .float: Constructor.float,
        .null: Constructor.null,
        .int: Constructor.int,
        // http://yaml.org/type/index.html
        .binary: Constructor.binary,
        // .merge is supported in `Constructor.map`.
//        .omap: Constructor.omap,
//        .pairs: Constructor.pairs,
//        .set: Constructor.set,
        .timestamp: Constructor.timestamp
        // .value is supported in `Constructor.str` and `Constructor.map`.
        ])
}

fileprivate let ISO8601Formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    return dateFormatter
}()
