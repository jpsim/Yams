//
//  YamlTagProviding.swift
//
//
//  Created by Adora Lynch on 9/5/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

/// Types that conform to YamlTagProviding and Encodable can optionally dictate the name of
/// a yaml tag when they are encoded with YAMLEncoder
public protocol YamlTagProviding {
    var yamlTag: Tag? { get }
}

/// YamlTagCoding refines YamlTagProviding.
/// Types that conform to YamlTagCoding and Decodable can decode yaml tags
/// from source documents into `Tag` values for reference or modification in memory.
public protocol YamlTagCoding: YamlTagProviding {
    var yamlTag: Tag? { get set }
}

internal extension Node {
    static let tagKeyNode: Self = .scalar(.init(YamlTagFunctionNameProvider().getName()))
}

private final class YamlTagFunctionNameProvider: YamlTagProviding {

    fileprivate var functionName: StaticString?

    var yamlTag: Tag? {
        functionName = #function
        return nil
    }

    func getName() -> StaticString {
        _ = yamlTag
        return functionName!
    }

    func getName() -> String {
        String(describing: getName() as StaticString)
    }
}
