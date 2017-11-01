//
//  ResolverTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
import Yams

class ResolverTests: XCTestCase {

    func testBasic() {
        let resolver = Resolver.basic
        XCTAssertEqual(resolver.resolveTag(of: "null"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "Null"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "NULL"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "~"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ""), .str)

        XCTAssertEqual(resolver.resolveTag(of: "true"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "True"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "TRUE"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "false"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "False"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "FALSE"), .str)

        XCTAssertEqual(resolver.resolveTag(of: "0"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "+1"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "0o7"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "0x3A"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-19"), .str)

        XCTAssertEqual(resolver.resolveTag(of: "0."), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-0.0"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".5"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "+12e03"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-2E+05"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".Inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".INF"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "+.inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "+.Inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "+.INF"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-.inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-.Inf"), .str)
        XCTAssertEqual(resolver.resolveTag(of: "-.INF"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".nan"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".NaN"), .str)
        XCTAssertEqual(resolver.resolveTag(of: ".NAN"), .str)
    }

    func testDefault() {
        let resolver = Resolver.default

        XCTAssertEqual(resolver.resolveTag(of: "null"), .null)
        XCTAssertEqual(resolver.resolveTag(of: "Null"), .null)
        XCTAssertEqual(resolver.resolveTag(of: "NULL"), .null)
        XCTAssertEqual(resolver.resolveTag(of: "~"), .null)
        XCTAssertEqual(resolver.resolveTag(of: ""), .null)

        XCTAssertEqual(resolver.resolveTag(of: "true"), .bool)
        XCTAssertEqual(resolver.resolveTag(of: "True"), .bool)
        XCTAssertEqual(resolver.resolveTag(of: "TRUE"), .bool)
        XCTAssertEqual(resolver.resolveTag(of: "false"), .bool)
        XCTAssertEqual(resolver.resolveTag(of: "False"), .bool)
        XCTAssertEqual(resolver.resolveTag(of: "FALSE"), .bool)

        XCTAssertEqual(resolver.resolveTag(of: "0"), .int)
        XCTAssertEqual(resolver.resolveTag(of: "+1"), .int)
        XCTAssertEqual(resolver.resolveTag(of: "0o7"), .int)
        XCTAssertEqual(resolver.resolveTag(of: "0x3A"), .int)
        XCTAssertEqual(resolver.resolveTag(of: "-19"), .int)

        XCTAssertEqual(resolver.resolveTag(of: "0."), .float)
        XCTAssertEqual(resolver.resolveTag(of: "-0.0"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".5"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "+12e03"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "-2E+05"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".Inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".INF"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "+.inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "+.Inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "+.INF"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "-.inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "-.Inf"), .float)
        XCTAssertEqual(resolver.resolveTag(of: "-.INF"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".nan"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".NaN"), .float)
        XCTAssertEqual(resolver.resolveTag(of: ".NAN"), .float)
    }

    func testCustomize() throws {
        // appending rule
        XCTAssertEqual(Resolver.basic.rules.count, 0)
        let basicAppendingBool = Resolver.basic.appending(.bool)
        XCTAssertEqual(basicAppendingBool.rules.count, 1)
        XCTAssertEqual(basicAppendingBool.resolveTag(of: "true"), .bool)

        // replacing rule with pattern string
        XCTAssertEqual(Resolver.default.resolveTag(of: "はい"), .str)
        let resolverRecognizingJapaneseYesNo = try Resolver.default.replacing(.bool, with: "(はい|いいえ)")
        XCTAssertEqual(resolverRecognizingJapaneseYesNo.resolveTag(of: "はい"), .bool)

        // replacing rule with Rule
        let ruleForOuiNon = try Resolver.Rule(.bool, "(Oui|Non)")
        XCTAssertEqual(resolverRecognizingJapaneseYesNo.replacing(ruleForOuiNon).resolveTag(of: "Oui"), .bool)

        // removing
        XCTAssertEqual(Resolver.default.rules.count, 7)
        let defaultRemovingBool = Resolver.default.removing(.bool)
        XCTAssertEqual(defaultRemovingBool.rules.count, 6)
        XCTAssertEqual(defaultRemovingBool.resolveTag(of: "true"), .str)

        // custom tag and rule
        let xml: Tag.Name = "XML"
        let defaultAppendingXML = try Resolver.default.appending(xml, "<[^>]*>")
        XCTAssertEqual(defaultAppendingXML.resolveTag(of: "<XML>"), xml)

        // Use customized Resolver on Yams.load()
        let bool = try Yams.load(yaml: "true")
        XCTAssertTrue(bool is Bool)
        XCTAssertFalse(bool is String)
        let string = try Yams.load(yaml: "true", Resolver.default.removing(.bool))
        XCTAssertFalse(string is Bool)
        XCTAssertTrue(string is String)
    }
}

extension ResolverTests {
    static var allTests: [(String, (ResolverTests) -> () throws -> Void)] {
        return [
            ("testBasic", testBasic),
            ("testDefault", testDefault),
            ("testCustomize", testCustomize)
        ]
    }
}
