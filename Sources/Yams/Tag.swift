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

// http://www.yaml.org/spec/1.2/spec.html#Schema
public enum KnownTag: String {
    // Failsafe Schema
    case str = "tag:yaml.org,2002:str"
    case seq = "tag:yaml.org,2002:seq"
    case map = "tag:yaml.org,2002:map"
    // JSON Schema
    case bool = "tag:yaml.org,2002:bool"
    case float =  "tag:yaml.org,2002:float"
    case null = "tag:yaml.org,2002:null"
    case int = "tag:yaml.org,2002:int"
    // http://yaml.org/type/index.html
    case binary = "tag:yaml.org,2002:binary"
    case merge = "tag:yaml.org,2002:merge"
    case omap = "tag:yaml.org,2002:omap"
    case pairs = "tag:yaml.org,2002:pairs"
    case set = "tag:yaml.org,2002:set"
    case timestamp = "tag:yaml.org,2002:timestamp"
    case value = "tag:yaml.org,2002:value"
//    case yaml = "tag:yaml.org,2002:yaml"
}

fileprivate enum State {
    case implicit
    case known(KnownTag)
    case unknown(String)
}

public class Tag {
    fileprivate var state: State
    fileprivate let resolver: Resolver?

    init(_ string: String?, _ resolver: Resolver = .default) {
        guard let string = string, !string.isEmpty && string != "!" else {
            state = .implicit
            self.resolver = resolver
            return
        }
        if let knownTag = KnownTag(rawValue: string) {
            state = .known(knownTag)
            self.resolver = nil
        } else {
            state = .unknown(string)
            self.resolver = nil
        }
    }

    var knownTag: KnownTag? {
        if case let .known(tag) = state {
            return tag
        }
        return nil
    }

    func resolved(with node: Node) -> Tag {
        if case .implicit = state, let tag = resolver?.resolveTag(of: node) {
            state = .known(tag)
        }
        return self
    }

    static var implicit: Tag {
        return Tag(nil, .default)
    }
}

extension Tag: Hashable {
    public var hashValue: Int {
        switch state {
        case .implicit: return 1
        case let .known(tag): return tag.hashValue
        case let .unknown(string): return string.hashValue
        }
    }

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        switch (lhs.state, rhs.state) {
        case let (.known(lhs), .known(rhs)): return lhs == rhs
        case let (.unknown(lhs), .unknown(rhs)): return lhs == rhs
        case (.implicit, _): fallthrough
        case (_, .implicit): fatalError("Never happen this!")
        default: return false
        }
    }
}
