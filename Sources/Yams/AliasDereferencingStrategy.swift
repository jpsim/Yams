//
//  AliasDereferencingStrategy.swift
//  Yams
//
//  Created by Adora Lynch on 8/9/24.
//  Copyright (c) 2024 Yams. All rights reserved.
//

import Foundation

public protocol AliasDereferencingStrategy: AnyObject {
    
    subscript(_ key: Anchor) -> Any? { get set }
}

public class BasicAliasDereferencingStrategy: AliasDereferencingStrategy {
    public init() {}
    
    private var map: [Anchor: Any] = .init()
    
    public subscript(_ key: Anchor) -> Any? {
        get { map[key] }
        set { map[key] = newValue }
    }
}

extension CodingUserInfoKey {
    internal static let aliasDereferencingStrategy = Self(rawValue: "aliasDereferencingStrategy")!
}
