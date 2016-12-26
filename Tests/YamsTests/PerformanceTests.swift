//
//  PerformanceTests.swift
//  Yams
//
//  Created by Norio Nomura on 12/24/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

let fixturesDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent().path + "/Fixtures/"

class PerformanceTests: XCTestCase {
    let filename = fixturesDirectory + "SourceKitten#289/debug.yaml"
    let expectedImports = ["/SourceKitten/.build/debug"]
    let expectedOtherArguments = [
        "-j8", "-D", "SWIFT_PACKAGE", "-Onone", "-g", "-enable-testing",
        "-Xcc", "-fmodule-map-file=/SourceKitten/Packages/Clang_C-1.0.1/module.modulemap",
        "-Xcc", "-fmodule-map-file=/SourceKitten/Packages/SourceKit-1.0.1/module.modulemap",
        "-module-cache-path", "/SourceKitten/.build/debug/ModuleCache"
    ]
    let expectedSources = [
        "/SourceKitten/Source/SourceKittenFramework/Clang+SourceKitten.swift",
        "/SourceKitten/Source/SourceKittenFramework/ClangTranslationUnit.swift",
        "/SourceKitten/Source/SourceKittenFramework/CodeCompletionItem.swift",
        "/SourceKitten/Source/SourceKittenFramework/Dictionary+Merge.swift",
        "/SourceKitten/Source/SourceKittenFramework/Documentation.swift",
        "/SourceKitten/Source/SourceKittenFramework/File.swift",
        "/SourceKitten/Source/SourceKittenFramework/JSONOutput.swift",
        "/SourceKitten/Source/SourceKittenFramework/Language.swift",
        "/SourceKitten/Source/SourceKittenFramework/library_wrapper.swift",
        "/SourceKitten/Source/SourceKittenFramework/library_wrapper_CXString.swift",
        "/SourceKitten/Source/SourceKittenFramework/library_wrapper_Documentation.swift",
        "/SourceKitten/Source/SourceKittenFramework/library_wrapper_Index.swift",
        "/SourceKitten/Source/SourceKittenFramework/library_wrapper_sourcekitd.swift",
        "/SourceKitten/Source/SourceKittenFramework/LinuxCompatibility.swift",
        "/SourceKitten/Source/SourceKittenFramework/Module.swift",
        "/SourceKitten/Source/SourceKittenFramework/ObjCDeclarationKind.swift",
        "/SourceKitten/Source/SourceKittenFramework/OffsetMap.swift",
        "/SourceKitten/Source/SourceKittenFramework/Parameter.swift",
        "/SourceKitten/Source/SourceKittenFramework/Request.swift",
        "/SourceKitten/Source/SourceKittenFramework/SourceDeclaration.swift",
        "/SourceKitten/Source/SourceKittenFramework/SourceLocation.swift",
        "/SourceKitten/Source/SourceKittenFramework/StatementKind.swift",
        "/SourceKitten/Source/SourceKittenFramework/String+SourceKitten.swift",
        "/SourceKitten/Source/SourceKittenFramework/Structure.swift",
        "/SourceKitten/Source/SourceKittenFramework/SwiftDeclarationKind.swift",
        "/SourceKitten/Source/SourceKittenFramework/SwiftDocKey.swift",
        "/SourceKitten/Source/SourceKittenFramework/SwiftDocs.swift",
        "/SourceKitten/Source/SourceKittenFramework/SwiftLangSyntax.swift",
        "/SourceKitten/Source/SourceKittenFramework/SyntaxKind.swift",
        "/SourceKitten/Source/SourceKittenFramework/SyntaxMap.swift",
        "/SourceKitten/Source/SourceKittenFramework/SyntaxToken.swift",
        "/SourceKitten/Source/SourceKittenFramework/Text.swift",
        "/SourceKitten/Source/SourceKittenFramework/Xcode.swift"
    ]

    func testSourceKittenIssue289UsingLoad() {
        guard let yamlString = try? String(contentsOfFile: filename, encoding: .utf8) else {
            XCTFail("Can't load \(filename)")
            return
        }
        self.measure {
            do {
                guard let yaml = try Yams.load(yaml: yamlString) as? [String:Any],
                    let commands = yaml["commands"] as? [String:Any],
                    let moduleCommand = commands["<SourceKittenFramework.module>"] as? [String:Any],
                    let imports = moduleCommand["import-paths"] as? [String],
                    let otherArguments = moduleCommand["other-args"] as? [String],
                    let sources = moduleCommand["sources"] as? [String] else {
                    XCTFail("Invalid result form Yams.load()")
                    return
                }
                XCTAssertEqual(imports, self.expectedImports)
                XCTAssertEqual(otherArguments, self.expectedOtherArguments)
                XCTAssertEqual(sources, self.expectedSources)
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    func testSourceKittenIssue289UsingCompose() {
        guard let yamlString = try? String(contentsOfFile: filename, encoding: .utf8) else {
            XCTFail("Can't load \(filename)")
            return
        }
        self.measure {
            do {
                guard let yaml = try Yams.compose(yaml: yamlString),
                    let moduleCommand = yaml["commands"]?["<SourceKittenFramework.module>"],
                    let imports = moduleCommand["import-paths"]?.array(of: String.self),
                    let otherArguments = moduleCommand["other-args"]?.array(of: String.self),
                    let sources = moduleCommand["sources"]?.array(of: String.self) else {
                        XCTFail("Invalid result form Yams.load()")
                        return
                }
                XCTAssertEqual(imports, self.expectedImports)
                XCTAssertEqual(otherArguments, self.expectedOtherArguments)
                XCTAssertEqual(sources, self.expectedSources)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}

extension PerformanceTests {
    static var allTests: [(String, (PerformanceTests) -> () throws -> Void)] {
        return [
            ("testSourceKittenIssue289Load", testSourceKittenIssue289UsingLoad),
            ("testSourceKittenIssue289Compose", testSourceKittenIssue289UsingCompose)
        ]
    }
}
