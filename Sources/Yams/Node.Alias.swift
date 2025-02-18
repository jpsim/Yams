//
//  Node.Alias.swift
//  Yams
//
//  Created by Adora Lynch on 8/19/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

// MARK: Node+Alias

extension Node {
    /// Scalar node.
    public struct Alias {
        /// The anchor for this alias.
        public var anchor: Anchor
        /// This node's tag (its type).
        public var tag: Tag
        /// The location for this node.
        public var mark: Mark?

        /// Create a `Node.Alias` using the specified parameters.
        ///
        /// - parameter tag:    This scalar's `Tag`.
        /// - parameter mark:   This scalar's `Mark`.
        public init(_ anchor: Anchor, _ tag: Tag = .implicit, _ mark: Mark? = nil) {
            self.anchor = anchor
            self.tag = tag
            self.mark = mark
        }
    }
}

extension Node.Alias: Comparable {
    /// :nodoc:
    public static func < (lhs: Node.Alias, rhs: Node.Alias) -> Bool {
        lhs.anchor.rawValue < rhs.anchor.rawValue
    }
}

extension Node.Alias: Equatable {
    /// :nodoc:
    public static func == (lhs: Node.Alias, rhs: Node.Alias) -> Bool {
        lhs.anchor == rhs.anchor
    }
}

extension Node.Alias: Hashable {
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(anchor)
    }
}

extension Node.Alias: TagResolvable {
    static let defaultTagName = Tag.Name.implicit
}
