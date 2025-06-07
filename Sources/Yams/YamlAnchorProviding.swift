//
//  YamlAnchorProviding.swift
//  Yams
//
//  Created by Adora Lynch on 8/15/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

/// Types that conform to YamlAnchorProviding and Encodable can optionally dictate the name of
/// a yaml anchor when they are encoded with YAMLEncoder
public protocol YamlAnchorProviding {
    /// the Anchor to encode with this node or nil
    var yamlAnchor: Anchor? { get }
}

/// YamlAnchorCoding refines YamlAnchorProviding.
/// Types that conform to YamlAnchorCoding and Decodable can decode yaml anchors
/// from source documents into `Anchor` values for reference or modification in memory.
public protocol YamlAnchorCoding: YamlAnchorProviding {
    /// the Anchor coded with this node or nil if none is present
    var yamlAnchor: Anchor? { get set }
}

internal extension Node {
    static var anchorKeyNode: Self { .scalar(.init("yamlAnchor")) }
}
