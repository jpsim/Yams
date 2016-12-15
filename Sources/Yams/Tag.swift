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
public enum Tag {
    case implicit
    // Failsafe Schema
    case map
    case seq
    case str
    // JSON Schema
    case null
    case bool
    case int
    case float
    // unknown
    case local(String)
}

extension Tag {
    public init(_ string: String? = nil) {
        guard let string = string else {
            self = .implicit
            return
        }
        switch string {
        case "!": self = .implicit
        case YAML_MAP_TAG: self = .map
        case YAML_SEQ_TAG: self = .seq
        case YAML_STR_TAG: self = .str
        case YAML_NULL_TAG: self = .null
        case YAML_BOOL_TAG: self = .bool
        case YAML_INT_TAG: self = .int
        case YAML_FLOAT_TAG: self = .float
        default: self = .local(string)
        }
    }

    public var localTag: String? {
        if case let .local(string) = self {
            return string
        }
        return nil
    }

    public func may(be tag: Tag) -> Bool {
        switch self {
        case .implicit: return true
        case tag: return true
        default: return false
        }
    }
}

extension Tag: CustomStringConvertible {
    public var description: String {
        switch self {
        case .implicit: return "!"
        case .map: return YAML_MAP_TAG
        case .seq: return YAML_SEQ_TAG
        case .str: return YAML_STR_TAG
        case .null: return YAML_NULL_TAG
        case .bool: return YAML_BOOL_TAG
        case .int: return YAML_INT_TAG
        case .float: return YAML_FLOAT_TAG
        case let .local(string): return string
        }
    }
}

extension Tag: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }

    public static func ==(lhs: Tag, rhs: Tag) -> Bool {
        switch (lhs, rhs) {
        case (.implicit, .implicit): return true
        case (.map, .map): return true
        case (.seq, .seq): return true
        case (.str, .str): return true
        case (.null, .null): return true
        case (.bool, .bool): return true
        case (.int, .int): return true
        case (.float, .float): return true
        case let (.local(lhs), .local(rhs)): return lhs == rhs
        default: return false
        }
    }
}
