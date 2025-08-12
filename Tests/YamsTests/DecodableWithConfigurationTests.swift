//
//  TopLevelDecoderTests.swift
//  Yams
//
//  Created by JP Simard on 2020-07-05.
//  Copyright (c) 2020 Yams. All rights reserved.
//

import XCTest
@testable import Yams

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
class DecodableWithConfigurationTests: XCTestCase {
    struct Container: DecodableWithConfiguration, Equatable {
        /// Decoding configuration provider.
        enum DecodingConfigurationProvider: DecodingConfigurationProviding {
            static let decodingConfiguration: DecodingConfiguration = .init(fileManager: .default)
        }

        /// Decoding configuration.
        struct DecodingConfiguration: @unchecked Sendable {
            let fileManager: FileManager
        }

        struct DecodableObject: Decodable, Equatable {
            var name: String
        }

        var decodableObject: DecodableObject?
        var fileManager: FileManager

        enum CodingKeys: String, CodingKey {
            case decodableObject
        }

        init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            decodableObject = try container.decodeIfPresent(DecodableObject.self, forKey: .decodableObject)
            fileManager = configuration.fileManager
        }
    }

    func testDecodeWithConfiguration() throws {
        let yaml = """
        decodableObject:
          name: item1
        """

        let yamlData = try XCTUnwrap(yaml.data(using: Parser.Encoding.default.swiftStringEncoding))
        let decodingConfiguration = Container.DecodingConfiguration(fileManager: .init())

        let container: Container
        do {
            container = try YAMLDecoder().decode(from: yamlData, configuration: decodingConfiguration)
        } catch {
            XCTFail("Unexpected decoding error: \(error)")
            return
        }

        XCTAssertEqual(container.fileManager, decodingConfiguration.fileManager)
        XCTAssertNotEqual(container.fileManager, FileManager.default)
        XCTAssertEqual(container.decodableObject, .init(name: "item1"), "correctly decodes the decodable object")
    }

    func testDecodeWithConfigurationProvider() throws {
        let yaml = """
        decodableObject:
          name: item1
        """

        let yamlData = try XCTUnwrap(yaml.data(using: Parser.Encoding.default.swiftStringEncoding))

        let container: Container
        do {
            container = try YAMLDecoder().decode(
                from: yamlData,
                configuration: Container.DecodingConfigurationProvider.self
            )
        } catch {
            XCTFail("Unexpected decoding error: \(error)")
            return
        }

        XCTAssertEqual(container.fileManager, FileManager.default)
        XCTAssertNotEqual(container.fileManager, .init())
        XCTAssertEqual(container.decodableObject, .init(name: "item1"), "correctly decodes the decodable object")
    }
}
