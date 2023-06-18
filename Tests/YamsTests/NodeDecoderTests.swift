//
//  NodeDecoderTests.swift
//  
//
//  Created by Rob Napier on 6/3/23.
//

import XCTest
import Yams

final class NodeDecoderTests: XCTestCase {
    func testMultiLevelPartialDecode() throws {
        let yaml = """
        ---
        topLevel:
          secondLevel:
            desired:
              name: My Name
              age: 123
        """

        struct Desired: Decodable {
            var name: String
            var age: Int
        }

        let node = try Yams.compose(yaml: yaml)!

        let desiredNode = try XCTUnwrap(node["topLevel"]?["secondLevel"]?["desired"])

        let desired = try YAMLDecoder().decode(Desired.self, from: desiredNode)

        XCTAssertEqual(desired.name, "My Name")
        XCTAssertEqual(desired.age, 123)
    }
}
