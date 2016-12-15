//
//  ResolverTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import XCTest
@testable import Yams

class ResolverTests: XCTestCase {

    func testFailsafe() {
        typealias TestResolver = Resolver.Failsafe
        XCTAssertEqual(TestResolver(resolve: "null").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "Null").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "NULL").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "~").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "").isNull, false)

        XCTAssertEqual(TestResolver(resolve: "true").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "True").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "TRUE").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "false").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "False").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "FALSE").toBool, nil)

        XCTAssertEqual(TestResolver(resolve: "0").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "+1").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "0o7").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "0x3A").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "-19").toInt, nil)

        XCTAssertEqual(TestResolver(resolve: "0.").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-0.0").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".5").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+12e03").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-2E+05").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-.inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-.Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-.INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".nan").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".NaN").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".NAN").toFloat, nil)
    }

    func testJSON() {
        typealias TestResolver = Resolver.JSON
        XCTAssertEqual(TestResolver(resolve: "null").isNull, true)
        XCTAssertEqual(TestResolver(resolve: "Null").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "NULL").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "~").isNull, false)
        XCTAssertEqual(TestResolver(resolve: "").isNull, false)

        XCTAssertEqual(TestResolver(resolve: "true").toBool, true)
        XCTAssertEqual(TestResolver(resolve: "True").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "TRUE").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "false").toBool, false)
        XCTAssertEqual(TestResolver(resolve: "False").toBool, nil)
        XCTAssertEqual(TestResolver(resolve: "FALSE").toBool, nil)

        XCTAssertEqual(TestResolver(resolve: "0").toInt, 0)
        XCTAssertEqual(TestResolver(resolve: "+1").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "0o7").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "0x3A").toInt, nil)
        XCTAssertEqual(TestResolver(resolve: "-19").toInt, -19)

        XCTAssertEqual(TestResolver(resolve: "0.").toFloat, 0.0)
        XCTAssertEqual(TestResolver(resolve: "-0.0").toFloat, -0.0)
        XCTAssertEqual(TestResolver(resolve: ".5").toFloat, 0.5)
        XCTAssertEqual(TestResolver(resolve: "+12e03").toFloat, +12e03)
        XCTAssertEqual(TestResolver(resolve: "-2E+05").toFloat, -2E+05)
        XCTAssertEqual(TestResolver(resolve: ".inf").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: ".Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "+.INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-.inf").toFloat, -.infinity)
        XCTAssertEqual(TestResolver(resolve: "-.Inf").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: "-.INF").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".nan").toFloat?.isNaN, true)
        XCTAssertEqual(TestResolver(resolve: ".NaN").toFloat, nil)
        XCTAssertEqual(TestResolver(resolve: ".NAN").toFloat, nil)
    }

    func testCore() {
        typealias TestResolver = Resolver.Core

        XCTAssertEqual(TestResolver(resolve: "null").isNull, true)
        XCTAssertEqual(TestResolver(resolve: "Null").isNull, true)
        XCTAssertEqual(TestResolver(resolve: "NULL").isNull, true)
        XCTAssertEqual(TestResolver(resolve: "~").isNull, true)
        XCTAssertEqual(TestResolver(resolve: "").isNull, false)

        XCTAssertEqual(TestResolver(resolve: "true").toBool, true)
        XCTAssertEqual(TestResolver(resolve: "True").toBool, true)
        XCTAssertEqual(TestResolver(resolve: "TRUE").toBool, true)
        XCTAssertEqual(TestResolver(resolve: "false").toBool, false)
        XCTAssertEqual(TestResolver(resolve: "False").toBool, false)
        XCTAssertEqual(TestResolver(resolve: "FALSE").toBool, false)

        XCTAssertEqual(TestResolver(resolve: "0").toInt, 0)
        XCTAssertEqual(TestResolver(resolve: "+1").toInt, 1)
        XCTAssertEqual(TestResolver(resolve: "0o7").toInt, 0o7)
        XCTAssertEqual(TestResolver(resolve: "0x3A").toInt, 0x3A)
        XCTAssertEqual(TestResolver(resolve: "-19").toInt, -19)

        XCTAssertEqual(TestResolver(resolve: "0.").toFloat, 0.0)
        XCTAssertEqual(TestResolver(resolve: "-0.0").toFloat, -0.0)
        XCTAssertEqual(TestResolver(resolve: ".5").toFloat, 0.5)
        XCTAssertEqual(TestResolver(resolve: "+12e03").toFloat, +12e03)
        XCTAssertEqual(TestResolver(resolve: "-2E+05").toFloat, -2E+05)
        XCTAssertEqual(TestResolver(resolve: ".inf").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: ".Inf").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: ".INF").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: "+.inf").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: "+.Inf").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: "+.INF").toFloat, .infinity)
        XCTAssertEqual(TestResolver(resolve: "-.inf").toFloat, -.infinity)
        XCTAssertEqual(TestResolver(resolve: "-.Inf").toFloat, -.infinity)
        XCTAssertEqual(TestResolver(resolve: "-.INF").toFloat, -.infinity)
        XCTAssertEqual(TestResolver(resolve: ".nan").toFloat?.isNaN, true)
        XCTAssertEqual(TestResolver(resolve: ".NaN").toFloat?.isNaN, true)
        XCTAssertEqual(TestResolver(resolve: ".NAN").toFloat?.isNaN, true)
    }
}

extension ResolverTests {
    static var allTests: [(String, (ResolverTests) -> () throws -> Void)] {
        return [
            ("testFailsafe", testFailsafe),
            ("testJSON", testJSON),
            ("testCore", testCore),
        ]
    }
}
