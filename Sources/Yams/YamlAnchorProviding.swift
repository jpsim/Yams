//
//  YamlAnchorProviding.swift
//  Yams
//
//  Created by Adora Lynch on 8/15/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import Foundation

/// Types that conform to YamlAnchorProviding and Encodable can optionally dictate the name of
/// a yaml anchor when they are encoded with YAMLEncoder
public protocol YamlAnchorProviding {
    var yamlAnchor: Anchor? { get }
}

/// YamlAnchorCoding refines YamlAnchorProviding.
/// Types that conform to YamlAnchorCoding and Decodable can decode yaml anchors
/// from source documents into `Anchor` values for reference or modification in memory.
public protocol YamlAnchorCoding: YamlAnchorProviding {
    var yamlAnchor: Anchor? { get set }
}

internal extension Node {
    static let anchorKeyNode: Self = .scalar(.init(YamlAnchorFunctionNameProvider().getName()))
}

private final class YamlAnchorFunctionNameProvider: YamlAnchorProviding {
    
    fileprivate var functionName: StaticString?
    
    var yamlAnchor: Anchor? {
        functionName = #function
        return nil
    }
    
    func getName() -> StaticString {
        _ = yamlAnchor
        return functionName!
    }
    
    func getName() -> String {
        String(describing: getName() as StaticString)
    }
}
