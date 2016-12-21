//
//  Resolver.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

public final class Resolver {
    let tagPatternPairs: [(KnownTag, NSRegularExpression)]
    init(_ tagPatternPairs: [(KnownTag, String)] = []) {
        self.tagPatternPairs = tagPatternPairs.map {
            ($0, try! NSRegularExpression(pattern: $1, options: .allowCommentsAndWhitespace))
        }
    }

    public func resolveTag(of node: Node) -> KnownTag? {
        switch node {
        case let .scalar(string, tag):
            return tag.knownTag ?? resolveTag(from: string) ?? .str
        case let .mapping(_, tag):
            return tag.knownTag ?? .map
        case let .sequence(_, tag):
            return tag.knownTag ?? .seq
        }
    }

    public func resolveTag(from string: String) -> KnownTag? {
        for (tag, regexp) in tagPatternPairs where regexp.matches(in: string) {
            return tag
        }
        return nil

    }
}

extension Resolver {
    public static let basic = Resolver()
    public static let `default` = Resolver([
        (.bool, [
            "^(?:yes|Yes|YES|no|No|NO",
            "|true|True|TRUE|false|False|FALSE",
            "|on|On|ON|off|Off|OFF)$",
            ].joined()),
        (.int, [
            "^(?:[-+]?0b[0-1_]+",
            "|[-+]?0o?[0-7_]+",
            "|[-+]?(?:0|[1-9][0-9_]*)",
            "|[-+]?0x[0-9a-fA-F_]+",
            "|[-+]?[1-9][0-9_]*(?::[0-5]?[0-9])+)$",
            ].joined()),
        (.float, [
            "^(?:[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?",
            "|[-+]?\\.(?:inf|Inf|INF)",
            "|\\.(?:nan|NaN|NAN))$",
            ].joined()),
        (.merge, "^(?:<<)$"),
        (.null, [
            "^(?: ~",
            "|null|Null|NULL",
            "| )$",
            ].joined()),
        (.timestamp, [
            "^(?:[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]",
            "|[0-9][0-9][0-9][0-9] -[0-9][0-9]? -[0-9][0-9]?",
            "(?:[Tt]|[ \\t]+)[0-9][0-9]?",
            ":[0-9][0-9] :[0-9][0-9] (?:\\.[0-9]*)?",
            "(?:[ \\t]*(?:Z|[-+][0-9][0-9]?(?::[0-9][0-9])?))?)$",
            ].joined()),
        (.value, "^(?:=)$"),
    ])
}

#if os(Linux)
    typealias NSRegularExpression = RegularExpression
#endif

func pattern(_ string: String) -> NSRegularExpression {
    return try! .init(pattern: string, options: .allowCommentsAndWhitespace)
}

extension NSRegularExpression {
    fileprivate func matches(in string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        if let match = firstMatch(in: string, options: [], range: range) {
            return match.range.location != NSNotFound
        }
        return false
    }
}

