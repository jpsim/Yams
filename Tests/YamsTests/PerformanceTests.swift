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

    func loadYAML() throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: filename))
        return String(data: data, encoding: .utf8)!
    }

    func parseSourceKittenIssue289UsingLoad(yaml: String, encoding: Parser.Encoding) {
        let spmName = "SourceKittenFramework"
        do {
            guard let object = try Yams.load(yaml: yaml, .default, .default, encoding) as? [String: Any],
                let commands = (object["commands"] as? [String: [String: Any]])?.values,
                let moduleCommand = commands.first(where: { ($0["module-name"] as? String ?? "") == spmName }),
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

    func testUsingLoadWithUTF16() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingLoad(yaml: yaml, encoding: .utf16)
        }
    }

    func testUsingLoadWithUTF8() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingLoad(yaml: yaml, encoding: .utf8)
        }
    }

    func parseSourceKittenIssue289UsingCompose(yaml: String, encoding: Parser.Encoding) {
        let spmName = "SourceKittenFramework"
        do {
            guard let node = try Yams.compose(yaml: yaml, .default, .default, encoding),
                let commands = node["commands"]?.mapping?.values,
                let moduleCommand = commands.first(where: { $0["module-name"]?.string == spmName }),
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

    func testUsingComposeWithUTF16() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingCompose(yaml: yaml, encoding: .utf16)
        }
    }

    func testUsingComposeWithUTF8() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingCompose(yaml: yaml, encoding: .utf8)
        }
    }

    func parseSourceKittenIssue289UsingSwiftDecodable(yaml: String, encoding: Parser.Encoding) {
        let spmName = "SourceKittenFramework"
        do {
            guard let manifest: Manifest = try YAMLDecoder(encoding: encoding).decode(from: yaml),
                let command = manifest.commands.values.first(where: { $0.moduleName == spmName }),
                let imports = command.importPaths,
                let otherArguments = command.otherArguments,
                let sources = command.sources else {
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

    func testUsingSwiftDecodableWithUTF16() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingSwiftDecodable(yaml: yaml, encoding: .utf16)
        }
    }

    func testUsingSwiftDecodableWithUTF8() throws {
        let yaml = try loadYAML()
        self.measure {
            parseSourceKittenIssue289UsingSwiftDecodable(yaml: yaml, encoding: .utf8)
        }
    }
}

extension PerformanceTests {
    static var allTests: [(String, (PerformanceTests) -> () throws -> Void)] {
        return [
            ("testUsingLoadWithUTF16", testUsingLoadWithUTF16),
            ("testUsingLoadWithUTF8", testUsingLoadWithUTF8),
            ("testUsingComposeWithUTF16", testUsingComposeWithUTF16),
            ("testUsingComposeWithUTF8", testUsingComposeWithUTF8),
            ("testUsingSwiftDecodableWithUTF16", testUsingSwiftDecodableWithUTF16),
            ("testUsingSwiftDecodableWithUTF8", testUsingSwiftDecodableWithUTF8)
        ]
    }
}

// Models for parsing Build File of llbuild
struct Manifest: Decodable {
    let commands: [String: Command]
}

struct Command: Decodable {
    let moduleName: String?
    let importPaths: [String]?
    let otherArguments: [String]?
    let sources: [String]?
    enum CodingKeys: String, CodingKey {
        case moduleName = "module-name"
        case importPaths = "import-paths"
        case otherArguments = "other-args"
        case sources
    }
}
