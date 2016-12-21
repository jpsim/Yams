//
//  Tag.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

#if SWIFT_PACKAGE
    import CYaml
#endif
import Foundation

public class Tag {
    public struct Name: RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    init(_ string: String?, _ resolver: Resolver = .default) {
        guard let string = string, !string.isEmpty && string != "!" else {
            state = .implicit
            self.resolver = resolver
            return
        }
        state = .resolved(Name(rawValue: string))
        self.resolver = nil
    }

    var knownTag: Name? {
        if case let .resolved(name) = state {
            return name
        }
        return nil
    }

    func resolved(with node: Node) -> Tag {
        if case .implicit = state, let tag = resolver?.resolveTag(of: node) {
            state = .resolved(tag)
        }
        return self
    }

    static var implicit: Tag {
        return Tag(nil, .default)
    }

    // fileprivate
    fileprivate var state: State
    fileprivate let resolver: Resolver?

    fileprivate enum State {
        case implicit
        case resolved(Name)
    }
}

extension Tag: Hashable {
    public var hashValue: Int {
        switch state {
        case .implicit: return 1
        case let .resolved(tag): return tag.hashValue
        }
    }

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        switch (lhs.state, rhs.state) {
        case let (.resolved(lhs), .resolved(rhs)): return lhs == rhs
        case (.implicit, _): fallthrough
        case (_, .implicit): fatalError("Never happen this!")
        default: return false
        }
    }
}

extension Tag.Name: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(unicodeScalarLiteral value: String) {
        self.rawValue = value
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.rawValue = value
    }
}

extension Tag.Name: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }

    public static func == (lhs: Tag.Name, rhs: Tag.Name) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

// http://www.yaml.org/spec/1.2/spec.html#Schema
extension Tag.Name {
    // Failsafe Schema
    public static let str: Tag.Name = "tag:yaml.org,2002:str"
    public static let seq: Tag.Name  = "tag:yaml.org,2002:seq"
    public static let map: Tag.Name  = "tag:yaml.org,2002:map"
    // JSON Schema
    public static let bool: Tag.Name  = "tag:yaml.org,2002:bool"
    public static let float: Tag.Name  =  "tag:yaml.org,2002:float"
    public static let null: Tag.Name  = "tag:yaml.org,2002:null"
    public static let int: Tag.Name  = "tag:yaml.org,2002:int"
    // http://yaml.org/type/index.html
    public static let binary: Tag.Name  = "tag:yaml.org,2002:binary"
    public static let merge: Tag.Name  = "tag:yaml.org,2002:merge"
    public static let omap: Tag.Name  = "tag:yaml.org,2002:omap"
    public static let pairs: Tag.Name  = "tag:yaml.org,2002:pairs"
    public static let set: Tag.Name  = "tag:yaml.org,2002:set"
    public static let timestamp: Tag.Name  = "tag:yaml.org,2002:timestamp"
    public static let value: Tag.Name  = "tag:yaml.org,2002:value"
//    public static let yaml: Tag.Name  = "tag:yaml.org,2002:yaml"
}
