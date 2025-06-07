//
//  YamlTagProviding.swift
//  Yams
//
//  Created by Adora Lynch on 9/5/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

/// Types that conform to YamlTagProviding and Encodable can optionally dictate the name of
/// a yaml tag when they are encoded with YAMLEncoder
public protocol YamlTagProviding {
    /// the Tag to encode with this node or nil
    var yamlTag: Tag? { get }
}

/// YamlTagCoding refines YamlTagProviding.
/// Types that conform to YamlTagCoding and Decodable can decode yaml tags
/// from source documents into `Tag` values for reference or modification in memory.
public protocol YamlTagCoding: YamlTagProviding {
    /// the Tag coded with this node or nil if none is present
    var yamlTag: Tag? { get set }
}

internal extension Node {
    static var tagKeyNode: Self { .scalar(.init("yamlTag")) }
}
