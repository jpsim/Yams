//
//  EncoderTests.swift
//  Yams
//
//  Created by Norio Nomura on 5/2/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import XCTest
import Yams

#if swift(>=4.0)

    /// Tests are copied from https://github.com/apple/swift/blob/master/test/stdlib/TestJSONEncoder.swift
    class EncoderTests: XCTestCase {
        // MARK: - Encoding Top-Level Empty Types
        func testEncodingTopLevelEmptyStruct() {
            let empty = EmptyStruct()
            _testRoundTrip(of: empty, expectedYAML: "{}\n")
        }

        func testEncodingTopLevelEmptyClass() {
            let empty = EmptyClass()
            _testRoundTrip(of: empty, expectedYAML: "{}\n")
        }

        // MARK: - Encoding Top-Level Single-Value Types
        func testEncodingTopLevelSingleValueEnum() {
            _testRoundTrip(of: Switch.off, expectedYAML: "false\n...\n")
            _testRoundTrip(of: Switch.on, expectedYAML: "true\n...\n")
        }

        func testEncodingTopLevelSingleValueStruct() {
            _testRoundTrip(of: Timestamp(3141592653), expectedYAML: "3.141592653e+9\n...\n")
        }

        func testEncodingTopLevelSingleValueClass() {
            _testRoundTrip(of: Counter())
        }

        // MARK: - Encoding Top-Level Structured Types
        func testEncodingTopLevelStructuredStruct() {
            // Address is a struct type with multiple fields.
            let address = Address.testValue
            _testRoundTrip(of: address)
        }

        func testEncodingTopLevelStructuredClass() {
            // Person is a class with multiple fields.
            let person = Person.testValue
            _testRoundTrip(of: person)
        }

        func testEncodingTopLevelDeepStructuredType() {
            // Company is a type with fields which are Codable themselves.
            let company = Company.testValue
            _testRoundTrip(of: company)
        }

        // MARK: - Date Strategy Tests
        func testEncodingDate() {
        #if os(Linux)
            print("'Date' does not conform to 'Codable' on Linux yet.")
        #else
            _testRoundTrip(of: TopLevelWrapper(Date()))
        #endif
        }

        func testEncodingDateMillisecondsSince1970() {
        #if os(Linux)
            print("'Date' does not conform to 'Codable' on Linux yet.")
        #else
            let seconds = 1000.0
            let expectedYAML = "- 1970-01-01T00:16:40Z\n"

            _testRoundTrip(of: TopLevelWrapper(Date(timeIntervalSince1970: seconds)),
                           expectedYAML: expectedYAML)
        #endif
        }

        // MARK: - Data Tests
        func testEncodingBase64Data() {
        #if os(Linux)
            print("'Data' does not conform to 'Codable' on Linux yet.")
        #else
            let data = Data(bytes: [0xDE, 0xAD, 0xBE, 0xEF])

            // We can't encode a top-level Data, so it'll be wrapped in an array.
            let expectedYAML = "- 3q2+7w==\n"
            _testRoundTrip(of: TopLevelWrapper(data), expectedYAML: expectedYAML)
        #endif
        }

        // MARK: - Helper Functions
        private func _testRoundTrip<T>(of value: T,
                                       expectedYAML yamlString: String? = nil) where T : Codable, T : Equatable {
            var payload: Data! = nil
            do {
                let encoder = YAMLEncoder()
                payload = try encoder.encode(value)
            } catch {
                XCTFail("Failed to encode \(T.self) to YAML.")
            }

            if let expectedYAML = yamlString {
                let producedYAML = String(data: payload, encoding: .utf8)! // swiftlint:disable:this force_unwrapping
                XCTAssertEqual(producedYAML, expectedYAML, "Produced YAML not identical to expected YAML.")
            }

            do {
                let decoder = YAMLDecoder()
                let decoded = try decoder.decode(T.self, from: payload)
                XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
            } catch {
                XCTFail("Failed to decode \(T.self) from YAML by error: \(error)")
            }
        }
    }

    // MARK: - Empty Types
    fileprivate struct EmptyStruct: Codable, Equatable {
        static func == (_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
            return true
        }
    }

    fileprivate class EmptyClass: Codable, Equatable {
        static func == (_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
            return true
        }
    }

    // MARK: - Single-Value Types
    /// A simple on-off switch type that encodes as a single Bool value.
    fileprivate enum Switch: Codable {
        case off
        case on // swiftlint:disable:this identifier_name

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            switch try container.decode(Bool.self) {
            case false: self = .off
            case true:  self = .on
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .off: try container.encode(false)
            case .on:  try container.encode(true)
            }
        }
    }

    /// A simple timestamp type that encodes as a single Double value.
    fileprivate struct Timestamp: Codable, Equatable {
        let value: Double

        init(_ value: Double) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Double.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.value)
        }

        static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
            return lhs.value == rhs.value
        }
    }

    /// A simple referential counter type that encodes as a single Int value.
    fileprivate final class Counter: Codable, Equatable {
        var count: Int = 0

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            count = try container.decode(Int.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.count)
        }

        static func == (lhs: Counter, rhs: Counter) -> Bool {
            return lhs.count == rhs.count
        }
    }

    // MARK: - Structured Types
    /// A simple address type that encodes as a dictionary of values.
    fileprivate struct Address: Codable, Equatable {
        let street: String
        let city: String
        let state: String
        let zipCode: Int
        let country: String

        init(street: String, city: String, state: String, zipCode: Int, country: String) {
            self.street = street
            self.city = city
            self.state = state
            self.zipCode = zipCode
            self.country = country
        }

        static func == (_ lhs: Address, _ rhs: Address) -> Bool {
            return lhs.street == rhs.street &&
                lhs.city == rhs.city &&
                lhs.state == rhs.state &&
                lhs.zipCode == rhs.zipCode &&
                lhs.country == rhs.country
        }

        static var testValue: Address {
            return Address(street: "1 Infinite Loop",
                           city: "Cupertino",
                           state: "CA",
                           zipCode: 95014,
                           country: "United States")
        }
    }

    /// A simple person class that encodes as a dictionary of values.
    fileprivate class Person: Codable, Equatable {
        let name: String
        let email: String

        init(name: String, email: String) {
            self.name = name
            self.email = email
        }

        static func == (_ lhs: Person, _ rhs: Person) -> Bool {
            return lhs.name == rhs.name && lhs.email == rhs.email
        }

        static var testValue: Person {
            return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
        }
    }

    /// A simple company struct which encodes as a dictionary of nested values.
    fileprivate struct Company: Codable, Equatable {
        let address: Address
        var employees: [Person]

        init(address: Address, employees: [Person]) {
            self.address = address
            self.employees = employees
        }

        static func == (_ lhs: Company, _ rhs: Company) -> Bool {
            return lhs.address == rhs.address && lhs.employees == rhs.employees
        }

        static var testValue: Company {
            return Company(address: Address.testValue, employees: [Person.testValue])
        }
    }

    // MARK: - Helper Types

    /// Wraps a type T so that it can be encoded at the top level of a payload.
    fileprivate struct TopLevelWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
        let value: T

        init(_ value: T) {
            self.value = value
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(value)
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            value = try container.decode(T.self)
            assert(container.isAtEnd)
        }

        static func == (_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
            return lhs.value == rhs.value
        }
    }

    extension EncoderTests {
        static var allTests: [(String, (EncoderTests) -> () throws -> Void)] {
            return [
                ("testEncodingTopLevelEmptyStruct", testEncodingTopLevelEmptyStruct),
                ("testEncodingTopLevelEmptyClass", testEncodingTopLevelEmptyClass),
                ("testEncodingTopLevelSingleValueEnum", testEncodingTopLevelSingleValueEnum),
                ("testEncodingTopLevelSingleValueStruct", testEncodingTopLevelSingleValueStruct),
                ("testEncodingTopLevelSingleValueClass", testEncodingTopLevelSingleValueClass),
                ("testEncodingTopLevelStructuredStruct", testEncodingTopLevelStructuredStruct),
                ("testEncodingTopLevelStructuredClass", testEncodingTopLevelStructuredClass),
                ("testEncodingTopLevelDeepStructuredType", testEncodingTopLevelDeepStructuredType),
                ("testEncodingDate", testEncodingDate),
                ("testEncodingDateMillisecondsSince1970", testEncodingDateMillisecondsSince1970),
                ("testEncodingBase64Data", testEncodingBase64Data)
            ]
        }
    }

#endif
