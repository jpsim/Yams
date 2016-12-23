//
//  ParserTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/15/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

class ParserTests: XCTestCase { // swiftlint:disable:this type_body_length

    // MARK: - samples in http://www.yaml.org/spec/1.2/spec.html
    func testSpecExample2_1_SequenceOfScalars() throws {
        let example = [
            "- Mark McGwire",
            "- Sammy Sosa",
            "- Ken Griffey"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            "Mark McGwire",
            "Sammy Sosa",
            "Ken Griffey"
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_2_MappingScalarsToScalars() throws {
        let example = [
            "hr:  65    # Home runs",
            "avg: 0.278 # Batting average",
            "rbi: 147   # Runs Batted In"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "hr": 65,
            "avg": 0.278,
            "rbi": 147
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_3_MappingScalarsToSequences() throws {
        let example = [
            "american:",
            "  - Boston Red Sox",
            "  - Detroit Tigers",
            "  - New York Yankees",
            "national:",
            "  - New York Mets",
            "  - Chicago Cubs",
            "  - Atlanta Braves"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "american": [
                "Boston Red Sox",
                "Detroit Tigers",
                "New York Yankees"
            ],
            "national": [
                "New York Mets",
                "Chicago Cubs",
                "Atlanta Braves"
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_4_SequenceOfMappings() throws {
        let example = [
            "-",
            "  name: Mark McGwire",
            "  hr:   65",
            "  avg:  0.278",
            "-",
            "  name: Sammy Sosa",
            "  hr:   63",
            "  avg:  0.288"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [Any] = [
            [
                "name": "Mark McGwire",
                "hr":   65,
                "avg":  0.278
            ],
            [
                "name": "Sammy Sosa",
                "hr":   63,
                "avg":  0.288
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_5_SequenceOfSequences() throws {
        let example = [
            "- [name        , hr, avg  ]",
            "- [Mark McGwire, 65, 0.278]",
            "- [Sammy Sosa  , 63, 0.288]"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [Any] = [
            ["name", "hr", "avg"],
            ["Mark McGwire", 65, 0.278],
            ["Sammy Sosa", 63, 0.288]
            ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_6_MappingOfMappings() throws {
        let example = [
            "Mark McGwire: {hr: 65, avg: 0.278}",
            "Sammy Sosa: {",
            "    hr: 63,",
            "    avg: 0.288",
            "  }"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            "Mark McGwire": ["hr": 65, "avg": 0.278],
            "Sammy Sosa": [
                "hr": 63,
                "avg": 0.288
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_7_TwoDocumentsInAStream() throws {
        let example = [
            "# Ranking of 1998 home runs",
            "---",
            "- Mark McGwire",
            "- Sammy Sosa",
            "- Ken Griffey",
            "",
            "# Team ranking",
            "---",
            "- Chicago Cubs",
            "- St Louis Cardinals"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [Any] = [
            "Mark McGwire",
            "Sammy Sosa",
            "Ken Griffey"
            ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_8_PlayByPlayFeedFromAGame() throws {
        let example = [
            "---",
            "time: 20:03:20",
            "player: Sammy Sosa",
            "action: strike (miss)",
            "...",
            "---",
            "time: 20:03:47",
            "player: Sammy Sosa",
            "action: grand slam",
            "..."
            ].joined(separator: "\n")
        let objects = Array(try Yams.load_all(yaml: example))
        let expected: [[String:Any]] = [
            [
                "time": 72200,
                "player": "Sammy Sosa",
                "action": "strike (miss)"
            ], [
                "time": 72227,
                "player": "Sammy Sosa",
                "action": "grand slam"
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_9_SingleDocumentWithTwoComments() throws {
        let example = [
            "---",
            "hr: # 1998 hr ranking",
            "  - Mark McGwire",
            "  - Sammy Sosa",
            "rbi:",
            "  # 1998 rbi ranking",
            "  - Sammy Sosa",
            "  - Ken Griffey"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "hr": [
                "Mark McGwire",
                "Sammy Sosa"
            ],
            "rbi": [
                "Sammy Sosa",
                "Ken Griffey"
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_10_NodeForSammySosaAppearsTwiceInThisDocument() throws {
        let example = [
            "---",
            "hr:",
            "  - Mark McGwire",
            "  # Following node labeled SS",
            "  - &SS Sammy Sosa",
            "rbi:",
            "  - *SS # Subsequent occurrence",
            "  - Ken Griffey"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "hr": [
                "Mark McGwire",
                "Sammy Sosa"
            ],
            "rbi": [
                "Sammy Sosa",
                "Ken Griffey"
            ]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_11_MappingBetweenSequences() throws {
        /* TODO: YAML supports keys other than string on mapping
        let example = [
            "? - Detroit Tigers",
            "  - Chicago cubs",
            ":",
            "  - 2001-07-23",
            "",
            "? [ New York Yankees,",
            "    Atlanta Braves ]",
            ": [ 2001-07-02, 2001-08-12,",
            "    2001-08-14 ]",
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            ["Detroit Tigers", "Chicago cubs"]: [
                "2001-07-23"
            ],
            ["New York Yankees", "Atlanta Braves"]: [
                "2001-07-02", "2001-08-12",
                "2001-08-14"
            ]
        ]
        YamsAssertEqual(objects, expected)
        */
    }

    func testSpecExample2_12_CompactNestedMapping() throws {
        let example = [
            "---",
            "# Products purchased",
            "- item    : Super Hoop",
            "  quantity: 1",
            "- item    : Basketball",
            "  quantity: 4",
            "- item    : Big Shoes",
            "  quantity: 1"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [Any] = [
            ["item"    : "Super Hoop",
             "quantity": 1],
            ["item"   : "Basketball",
             "quantity": 4],
            ["item"    : "Big Shoes",
             "quantity": 1]
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_13_Inliterals_NewlinesArePreserved() throws {
        let example = [
            "# ASCII Art",
            "--- |",
            "  \\//||\\/||",
            "  // ||  ||__"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            "\\//||\\/||",
            "// ||  ||__"
            ].joined(separator: "\n")
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_14_InTheFoldedScalars_NewlinesBecomeSpaces() throws {
        let example = [
            "--- >",
            "  Mark McGwire's",
            "  year was crippled",
            "  by a knee injury."
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            "Mark McGwire's",
            "year was crippled",
            "by a knee injury."
            ].joined(separator: " ")
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_15_InTheFoldedScalars_NewlinesBecomeSpaces() throws {
        let example = [
            ">",
            " Sammy Sosa completed another",
            " fine season with great stats.",
            "",
            "   63 Home Runs",
            "   0.288 Batting Average",
            "",
            " What a year!"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected = [
            "Sammy Sosa completed another fine season with great stats.",
            "",
            "  63 Home Runs",
            "  0.288 Batting Average",
            "",
            "What a year!"
            ].joined(separator: "\n")
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_16_IndentationDeterminesScope() throws {
        let example = [
            "name: Mark McGwire",
            "accomplishment: >",
            "  Mark set a major league",
            "  home run record in 1998.",
            "stats: |",
            "  65 Home Runs",
            "  0.278 Batting Average"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "name": "Mark McGwire",
            "accomplishment": "Mark set a major league home run record in 1998.\n",
            "stats":
                "65 Home Runs\n" +
            "0.278 Batting Average"
            ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_17_QuotedScalars() throws {
        let example = [
            "unicode: \"Sosa did fine.\\u263A\"",
            "control: \"\\b1998\\t1999\\t2000\\n\"",
            "hex esc: \"\\x0d\\x0a is \\r\\n\"",
            "",
            "single: '\"Howdy!\" he cried.'",
            "quoted: ' # Not a ''comment''.'",
            "tie-fighter: '|\\-*-/|'"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "unicode": "Sosa did fine.\u{263A}",
            "control": "\u{8}1998\t1999\t2000\n",
            "hex esc": "\u{0d}\u{0a} is \r\n",
            "single": "\"Howdy!\" he cried.",
            "quoted": " # Not a 'comment'.",
            "tie-fighter": "|\\-*-/|"
            ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_18_MultiLineFlowScalars() throws {
        let example = [
            "plain:",
            "  This unquoted scalar",
            "  spans many lines.",
            "",
            "quoted: \"So does this",
            "  quoted scalar.\n\"",
            ""
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "plain": "This unquoted scalar spans many lines.",
            "quoted": "So does this quoted scalar. "
            ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_19_Integers() throws {
        let example = [
            "canonical: 12345",
            "decimal: +12345",
            "octal: 0o14",
            "hexadecimal: 0xC"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "canonical": 12345,
            "decimal": 12345,
            "octal": 0o14,
            "hexadecimal": 0xC
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_20_FloatingPoint() throws {
        let example = [
            "canonical: 1.23015e+3",
            "exponential: 12.3015e+02",
            "fixed: 1230.15",
            "negative infinity: -.inf",
            "not a number: .NaN"
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "canonical": 1.23015e+3,
            "exponential": 12.3015e+02,
            "fixed": 1230.15,
            "negative infinity": -1 * Double.infinity,
            "not a number": Double.nan
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_23_VariousExplicitTags() throws {
        let example = [
            "---",
            "not-date: !!str 2002-04-28",
            "",
            "picture: !!binary |",
            " R0lGODlhDAAMAIQAAP//9/X",
            " 17unp5WZmZgAAAOfn515eXv",
            " Pz7Y6OjuDg4J+fn5OTk6enp",
            " 56enmleECcgggoBADs=",
            "",
            "application specific tag: !something |",
            " The semantics of the tag",
            " above may be different for",
            " different documents.",
            ""
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let expected: [String:Any] = [
            "not-date": "2002-04-28",
            "picture": Data(base64Encoded: [
                "R0lGODlhDAAMAIQAAP//9/X",
                "17unp5WZmZgAAAOfn515eXv",
                "Pz7Y6OjuDg4J+fn5OTk6enp",
                "56enmleECcgggoBADs="
                ].joined())!,
            "application specific tag": "The semantics of the tag\nabove may be different for\ndifferent documents.\n"
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_27_Invoice() throws { // swiftlint:disable:this function_body_length
        let example = [
            "--- !<tag:clarkevans.com,2002:invoice>", // TODO: local tag parsing
            "invoice: 34843",
            "date   : 2001-01-23",
            "bill-to: &id001",
            "    given  : Chris",
            "    family : Dumars",
            "    address:",
            "        lines: |",
            "            458 Walkman Dr.",
            "            Suite #292",
            "        city    : Royal Oak",
            "        state   : MI",
            "        postal  : 48046",
            "ship-to: *id001",
            "product:",
            "    - sku         : BL394D",
            "      quantity    : 4",
            "      description : Basketball",
            "      price       : 450.00",
            "    - sku         : BL4438H",
            "      quantity    : 1",
            "      description : Super Hoop",
            "      price       : 2392.00",
            "tax  : 251.42",
            "total: 4443.52",
            "comments:",
            "    Late afternoon is best.",
            "    Backup contact is Nancy",
            "    Billsmer @ 338-4338."
            ].joined(separator: "\n")
        let objects = try Yams.load(yaml: example)
        let billTo: [String:Any] = [
            "given" : "Chris",
            "family" : "Dumars",
            "address" : [
                "lines" : "458 Walkman Dr.\nSuite #292\n",
                "city" : "Royal Oak",
                "state" : "MI",
                "postal" : 48046
            ]
        ]
        let expected: [String:Any] = [
            "invoice" : 34843,
            "date" : timestamp(0, 2001, 1, 23),
            "bill-to" : billTo,
            "ship-to" : billTo,
            "product" : [
                [
                    "sku" : "BL394D",
                    "quantity" : 4,
                    "description" : "Basketball",
                    "price" : 450.0
                ],
                [
                    "sku" : "BL4438H",
                    "quantity" : 1,
                    "description" : "Super Hoop",
                    "price" : 2392.0
                ]
            ],
            "tax" : 251.42,
            "total" : 4443.52,
            "comments" : "Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338."
        ]
        YamsAssertEqual(objects, expected)
    }

    func testSpecExample2_28_LogFile() throws { // swiftlint:disable:this function_body_length
        let example = [
            "---",
            "Time: 2001-11-23 15:01:42 -5",
            "User: ed",
            "Warning:",
            "  This is an error message",
            "  for the log file",
            "---",
            "Time: 2001-11-23 15:02:31 -5",
            "User: ed",
            "Warning:",
            "  A slightly different error",
            "  message.",
            "---",
            "Date: 2001-11-23 15:03:17 -5",
            "User: ed",
            "Fatal:",
            "  Unknown variable \"bar\"",
            "Stack:",
            "  - file: TopClass.py",
            "    line: 23",
            "    code: |",
            "      x = MoreObject(\"345\\n\")",
            "  - file: MoreClass.py",
            "    line: 58",
            "    code: |-",
            "      foo = bar",
            ""
            ].joined(separator: "\n")
        let objects = Array(try Yams.load_all(yaml: example))
        let expected: [Any] = [
            [
                "Time": timestamp(-5, 2001, 11, 23, 15, 1, 42),
                "User": "ed",
                "Warning": "This is an error message for the log file"
            ],
            [
                "Time": timestamp(-5, 2001, 11, 23, 15, 2, 31),
                "User": "ed",
                "Warning": "A slightly different error message."
            ],
            [
                "Date": timestamp(-5, 2001, 11, 23, 15, 3, 17),
                "User": "ed",
                "Fatal": "Unknown variable \"bar\"",
                "Stack": [
                    [
                        "file": "TopClass.py",
                        "line": 23,
                        "code": "x = MoreObject(\"345\\n\")\n"
                    ],
                    [
                        "file": "MoreClass.py",
                        "line": 58,
                        "code": "foo = bar"
                    ]
                ]
            ]
        ]
        YamsAssertEqual(objects, expected)
    }
}

extension ParserTests {
    static var allTests: [(String, (ParserTests) -> () throws -> Void)] {
        return [
            ("testSpecExample2_1_SequenceOfScalars", testSpecExample2_1_SequenceOfScalars),
            ("testSpecExample2_2_MappingScalarsToScalars", testSpecExample2_2_MappingScalarsToScalars),
            ("testSpecExample2_3_MappingScalarsToSequences", testSpecExample2_3_MappingScalarsToSequences),
            ("testSpecExample2_4_SequenceOfMappings", testSpecExample2_4_SequenceOfMappings),
            ("testSpecExample2_5_SequenceOfSequences", testSpecExample2_5_SequenceOfSequences),
            ("testSpecExample2_6_MappingOfMappings", testSpecExample2_6_MappingOfMappings),
            ("testSpecExample2_7_TwoDocumentsInAStream", testSpecExample2_7_TwoDocumentsInAStream),
            ("testSpecExample2_8_PlayByPlayFeedFromAGame", testSpecExample2_8_PlayByPlayFeedFromAGame),
            ("testSpecExample2_9_SingleDocumentWithTwoComments", testSpecExample2_9_SingleDocumentWithTwoComments),
            ("testSpecExample2_10_NodeForSammySosaAppearsTwiceInThisDocument",
             testSpecExample2_10_NodeForSammySosaAppearsTwiceInThisDocument),
            ("testSpecExample2_11_MappingBetweenSequences", testSpecExample2_11_MappingBetweenSequences),
            ("testSpecExample2_12_CompactNestedMapping", testSpecExample2_12_CompactNestedMapping),
            ("testSpecExample2_13_Inliterals_NewlinesArePreserved",
             testSpecExample2_13_Inliterals_NewlinesArePreserved),
            ("testSpecExample2_14_InTheFoldedScalars_NewlinesBecomeSpaces",
             testSpecExample2_14_InTheFoldedScalars_NewlinesBecomeSpaces),
            ("testSpecExample2_15_InTheFoldedScalars_NewlinesBecomeSpaces",
             testSpecExample2_15_InTheFoldedScalars_NewlinesBecomeSpaces),
            ("testSpecExample2_16_IndentationDeterminesScope", testSpecExample2_16_IndentationDeterminesScope),
            ("testSpecExample2_17_QuotedScalars", testSpecExample2_17_QuotedScalars),
            ("testSpecExample2_18_MultiLineFlowScalars", testSpecExample2_18_MultiLineFlowScalars),
            ("testSpecExample2_19_Integers", testSpecExample2_19_Integers),
            ("testSpecExample2_20_FloatingPoint", testSpecExample2_20_FloatingPoint),
            ("testSpecExample2_23_VariousExplicitTags", testSpecExample2_23_VariousExplicitTags),
            ("testSpecExample2_27_Invoice", testSpecExample2_27_Invoice),
            ("testSpecExample2_28_LogFile", testSpecExample2_28_LogFile)
        ]
    }
} // swiftlint:disable:this file_length
