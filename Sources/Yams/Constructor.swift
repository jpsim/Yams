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
        var dictionary = [AnyHashable: Any](minimumCapacity: pairs.count)
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
        switch string.lowercased() {
        case "true", "yes", "on":
            return true
        case "false", "no", "off":
            return false
        default:
            return string
        }
    }

    public func float(from node: Node) -> Any {
        guard var string = node.string else { fatalError("Never happen this") }
        switch string {
        case ".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF":
            return Double.infinity
        case "-.inf", "-.Inf", "-.INF":
            return -Double.infinity
        case ".nan", ".NaN", ".NAN":
            return Double.nan
        default:
            string = string.replacingOccurrences(of: "_", with: "")
            if string.contains(":") {
                var sign: Double = 1
                if string.hasPrefix("-") {
                    sign = -1
                    string = string.substring(from: string.index(after: string.startIndex))
                } else if string.hasPrefix("+") {
                    string = string.substring(from: string.index(after: string.startIndex))
                }
                let digits = string.components(separatedBy: ":").flatMap(Double.init).reversed()
                var base = 1.0
                var value = 0.0
                digits.forEach {
                    value += $0 * base
                    base *= 60
                }
                return sign * value
            }
            return Double(string) ?? string
        }
    }

    public func null(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        switch string {
        case "", "~", "null", "Null", "NULL":
            return NSNull()
        default:
            return string
        }
    }

    public func int(from node: Node) -> Any {
        guard var string = node.string else { fatalError("Never happen this") }
        string = string.replacingOccurrences(of: "_", with: "")
        if string == "0" {
            return 0
        }
        if string.hasPrefix("0x") {
            let hexadecimal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(hexadecimal, radix: 16) ?? string
        }
        if string.hasPrefix("0b") {
            let octal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(octal, radix: 2) ?? string
        }
        if string.hasPrefix("0o") {
            let octal = string.substring(from: string.index(string.startIndex, offsetBy: 2))
            return Int(octal, radix: 8) ?? string
        }
        if string.hasPrefix("0") {
            let octal = string.substring(from: string.index(after: string.startIndex))
            return Int(octal, radix: 8) ?? string
        }
        if string.contains(":") {
            var sign = 1
            if string.hasPrefix("-") {
                sign = -1
                string = string.substring(from: string.index(after: string.startIndex))
            } else if string.hasPrefix("+") {
                string = string.substring(from: string.index(after: string.startIndex))
            }
            let digits = string.components(separatedBy: ":").flatMap({ Int($0) }).reversed()
            var base = 1
            var value = 0
            digits.forEach {
                value += $0 * base
                base *= 60
            }
            return sign * value
        }
        return Int(string) ?? string
    }

    public func binary(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }
        let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters)
        return data ?? string
    }

    public func omap(from node: Node) -> Any {
        // Note: we do not check for duplicate keys.
        guard let array = node.array else { fatalError("Never happen this") }
        return array.flatMap { subnode -> (Any, Any)? in
            // TODO: Should rais error if subnode is not mapping or pairs.count != 1
            guard let pairs = subnode.pairs, let pair = pairs.first else { return nil }
            return (any(from: pair.key), any(from: pair.value))
        }
    }

    public func pairs(from node: Node) -> Any {
        // Note: the same code as `omap(from:)`.
        guard let array = node.array else { fatalError("Never happen this") }
        return array.flatMap { subnode -> (Any, Any)? in
            // TODO: Should rais error if subnode is not mapping or pairs.count != 1
            guard let pairs = subnode.pairs, let pair = pairs.first else { return nil }
            return (any(from: pair.key), any(from: pair.value))
        }
    }

    public func set(from node: Node) -> Any {
        guard let pairs = node.pairs else { fatalError("Never happen this") }
        // TODO: YAML supports Hashable elements other than str.
        return Set(pairs.map({ str(from: $0.key) as AnyHashable }))
    }

    public func timestamp(from node: Node) -> Any {
        guard let string = node.string else { fatalError("Never happen this") }

        let range = NSRange(location: 0, length: string.utf16.count)
        guard let result = timestampPattern.firstMatch(in: string, options: [], range: range),
           result.range.location != NSNotFound else {
            return string
        }
        #if os(Linux)
            let components = (1..<result.numberOfRanges).map(result.range(at:)).map(string.substring)
        #else
            let components = (1..<result.numberOfRanges).map(result.rangeAt).map(string.substring)
        #endif

        var datecomponents = DateComponents()
        datecomponents.calendar = Calendar(identifier: .gregorian)
        datecomponents.year = components[0].flatMap { Int($0) }
        datecomponents.month = components[1].flatMap { Int($0) }
        datecomponents.day = components[2].flatMap { Int($0) }
        datecomponents.hour = components[3].flatMap { Int($0) }
        datecomponents.minute = components[4].flatMap { Int($0) }
        datecomponents.second = components[5].flatMap { Int($0) }
        datecomponents.nanosecond = components[6].flatMap {
            let length = $0.characters.count
            let nanosecond: Int?
            if length < 9 {
                nanosecond = Int($0 + String(repeating: "0", count: 9 - length))
            } else {
                nanosecond = Int($0.substring(to: $0.index($0.startIndex, offsetBy: 9)))
            }
            return nanosecond
        }
        datecomponents.timeZone = {
            var seconds = 0
            if let hourInSecond = components[9].flatMap({ Int($0) }).map({ $0 * 60 * 60 }) {
                seconds += hourInSecond
            }
            if let minuteInSecond = components[10].flatMap({ Int($0) }).map({ $0 * 60 }) {
                seconds += minuteInSecond
            }
            if components[8] == "-" { // sign
                seconds *= -1
            }
            return TimeZone(secondsFromGMT: seconds)
        }()
        // Using `DateComponents.date` causes crash on Linux
        return NSCalendar(identifier: .gregorian)?.date(from: datecomponents) ?? string
    }
}

fileprivate let timestampPattern: NSRegularExpression = pattern([
    "^([0-9][0-9][0-9][0-9])",          // year
    "-([0-9][0-9]?)",                   // month
    "-([0-9][0-9]?)",                   // day
    "(?:(?:[Tt]|[ \\t]+)",
    "([0-9][0-9]?)",                    // hour
    ":([0-9][0-9])",                    // minute
    ":([0-9][0-9])",                    // second
    "(?:\\.([0-9]*))?",                 // fraction
    "(?:[ \\t]*(Z|([-+])([0-9][0-9]?)", // tz_sign, tz_hour
    "(?::([0-9][0-9]))?))?)?$"          // tz_minute
    ].joined()
)

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
        .omap: Constructor.omap,
        .pairs: Constructor.pairs,
        .set: Constructor.set,
        .timestamp: Constructor.timestamp
        // .value is supported in `Constructor.str` and `Constructor.map`.
        ])
}

fileprivate let ISO8601Formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZ"
    return dateFormatter
}()

fileprivate extension String {
    func substring(with range: NSRange) -> String? {
        guard range.location != NSNotFound else { return nil }
        let utf16lowerBound = utf16.index(utf16.startIndex, offsetBy: range.location)
        let utf16upperBound = utf16.index(utf16lowerBound, offsetBy: range.length)
        guard let lowerBound = utf16lowerBound.samePosition(in: self),
            let upperBound = utf16upperBound.samePosition(in: self) else {
                fatalError("Never happen this")
        }
        return substring(with: lowerBound..<upperBound)
    }
}
