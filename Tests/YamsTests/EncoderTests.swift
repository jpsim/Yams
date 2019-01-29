//
//  EncoderTests.swift
//  Yams
//
//  Created by Norio Nomura on 5/2/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import Foundation
import XCTest
import Yams

// swiftlint:disable identifier_name line_length

/// Tests are copied from https://github.com/apple/swift/blob/master/test/stdlib/TestJSONEncoder.swift
class EncoderTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        _testRoundTrip(of: Switch.off, expectedYAML: "false\n")
        _testRoundTrip(of: Switch.on, expectedYAML: "true\n")
    }

    func testEncodingTopLevelSingleValueStruct() {
        _testRoundTrip(of: Timestamp(3141592653), expectedYAML: "3.141592653e+9\n")
    }

    func testEncodingTopLevelSingleValueClass() {
        _testRoundTrip(of: Counter(), expectedYAML: "0\n")
    }

    // MARK: - Encoding Top-Level Structured Types
    func testEncodingTopLevelStructuredStruct() {
        // Address is a struct type with multiple fields.
        let address = Address.testValue
        _testRoundTrip(of: address, expectedYAML: """
            street: 1 Infinite Loop
            city: Cupertino
            state: CA
            zipCode: 95014
            country: United States

            """)
    }

    func testEncodingTopLevelStructuredClass() {
        // Person is a class with multiple fields.
        let person = Person.testValue
        _testRoundTrip(of: person, expectedYAML: "name: Johnny Appleseed\nemail: appleseed@apple.com\n")
    }

    func testEncodingTopLevelStructuredSingleStruct() {
        // Numbers is a struct which encodes as an array through a single value container.
        let numbers = Numbers.testValue
        _testRoundTrip(of: numbers, expectedYAML: "- 4\n- 8\n- 15\n- 16\n- 23\n- 42\n")
    }

    func testEncodingTopLevelStructuredSingleClass() {
        // Mapping is a class which encodes as a dictionary through a single value container.
        let mapping = Mapping.testValue
    #if swift(>=4.0.3)
        // fixing https://bugs.swift.org/browse/SR-5206 changes result.
        _testRoundTrip(of: mapping, with: YAMLEncoder.Options(sortKeys: true), expectedYAML: """
            Apple: http://apple.com
            localhost: http://127.0.0.1

            """)
    #else
        _testRoundTrip(of: mapping, with: YAMLEncoder.Options(sortKeys: true), expectedYAML: """
            Apple:
              relative: http://apple.com
            localhost:
              relative: http://127.0.0.1

            """)
    #endif
    }

    func testEncodingTopLevelDeepStructuredType() {
        // Company is a type with fields which are Codable themselves.
        let company = Company.testValue
        _testRoundTrip(of: company, expectedYAML: """
            address:
              street: 1 Infinite Loop
              city: Cupertino
              state: CA
              zipCode: 95014
              country: United States
            employees:
            - id: 42
              name: Johnny Appleseed
              email: appleseed@apple.com

            """)
    }

    func testEncodingClassWhichSharesEncoderWithSuper() {
        // Employee is a type which shares its encoder & decoder with its superclass, Person.
        let employee = Employee.testValue
        _testRoundTrip(of: employee, expectedYAML: "id: 42\nname: Johnny Appleseed\nemail: appleseed@apple.com\n")
    }

    func testEncodingTopLevelNullableType() {
        // EnhancedBool is a type which encodes either as a Bool or as nil.
        _testRoundTrip(of: EnhancedBool.true, expectedYAML: "true\n")
        _testRoundTrip(of: EnhancedBool.false, expectedYAML: "false\n")
        _testRoundTrip(of: EnhancedBool.fileNotFound, expectedYAML: "null\n")
    }

    // MARK: - Date Strategy Tests
    func testEncodingDate() {
    #if !_runtime(_ObjC) && !swift(>=5.0)
        print("Decoding 'Date' has issue on Linux with nanoseconds. https://bugs.swift.org/browse/SR-6223")
        XCTAssertNotEqual(timestamp( 0, 2001, 12, 15, 02, 59, 43, 0.12345678).timeIntervalSinceReferenceDate,
                          30077983.12345678,
                          "https://bugs.swift.org/browse/SR-6223 seems to be fixed")
    #else
        _testRoundTrip(of: Date())
    #endif
    }

    func testEncodingDateMillisecondsSince1970() {
    #if !_runtime(_ObjC) && !swift(>=5.0)
        print("Decoding 'Date' has issue on Linux with nanoseconds. https://bugs.swift.org/browse/SR-6223")
        XCTAssertNotEqual(timestamp( 0, 2001, 12, 15, 02, 59, 43, 0.12345678).timeIntervalSinceReferenceDate,
                          30077983.12345678,
                          "https://bugs.swift.org/browse/SR-6223 seems to be fixed")
    #else
        _testRoundTrip(of: Date(timeIntervalSince1970: 1000.0), expectedYAML: "1970-01-01T00:16:40Z\n")
    #endif
    }

    // MARK: - Data Tests
    func testEncodingBase64Data() {
        _testRoundTrip(of: Data([0xDE, 0xAD, 0xBE, 0xEF]), expectedYAML: "3q2+7w==\n")
    }

    // MARK: - Encoder Features
    func testNestedContainerCodingPaths() {
        _testRoundTrip(of: NestedContainersTestType())
    }

    func testSuperEncoderCodingPaths() {
        _testRoundTrip(of: NestedContainersTestType(testSuperCoder: true))
    }

    func testInterceptDecimal() {
        let expectedYAML = "value: 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\n"

        // Want to make sure we write out a YAML number, not the keyed encoding here.
        // 1e127 is too big to fit natively in a Double, too, so want to make sure it's encoded as a Decimal.
        let decimal = Decimal(sign: .plus, exponent: 127, significand: Decimal(1))
        _testRoundTrip(of: TopLevelWrapper(decimal), expectedYAML: expectedYAML)

        // Optional Decimals should encode the same way.
    #if swift(>=4.0.3)
        // following test requires that https://bugs.swift.org/browse/SR-5206 is fixed.
        _testRoundTrip(of: OptionalTopLevelWrapper(decimal), expectedYAML: expectedYAML)
    #endif
    }

    func testInterceptURL() {
        // Want to make sure YAMLEncoder writes out single-value URLs, not the keyed encoding.
        let expectedYAML = "value: http://swift.org\n"
        let url = URL(string: "http://swift.org")!
        _testRoundTrip(of: TopLevelWrapper(url), expectedYAML: expectedYAML)

        // Optional URLs should encode the same way.
    #if swift(>=4.0.3)
        // following test requires that https://bugs.swift.org/browse/SR-5206 is fixed.
        _testRoundTrip(of: OptionalTopLevelWrapper(url), expectedYAML: expectedYAML)
    #endif
    }

    func testValuesInSingleValueContainer() throws {
        _testRoundTrip(of: true)
        _testRoundTrip(of: false)

        _testFixedWidthInteger(type: Int.self)
        _testFixedWidthInteger(type: Int8.self)
        _testFixedWidthInteger(type: Int16.self)
        _testFixedWidthInteger(type: Int32.self)
        _testFixedWidthInteger(type: Int64.self)
        _testFixedWidthInteger(type: UInt.self)
        _testFixedWidthInteger(type: UInt8.self)
        _testFixedWidthInteger(type: UInt16.self)
        _testFixedWidthInteger(type: UInt32.self)
        _testFixedWidthInteger(type: UInt64.self)

        _testFloatingPoint(type: Float.self)
        _testFloatingPoint(type: Double.self)

        // Can't YAML encode empty string as valid YAML Document?
//            _testRoundTrip(of: "")
        _testRoundTrip(of: URL(string: "https://apple.com")!)
    }

    private func _testFixedWidthInteger<T>(type: T.Type,
                                           file: StaticString = #file,
                                           line: UInt = #line) where T: FixedWidthInteger & Codable {
        _testRoundTrip(of: type.min, file: file, line: line)
        _testRoundTrip(of: type.max, file: file, line: line)
    }

    private func _testFloatingPoint<T>(type: T.Type,
                                       file: StaticString = #file,
                                       line: UInt = #line) where T: FloatingPoint & Codable {
        _testRoundTrip(of: type.leastNormalMagnitude, file: file, line: line)
        _testRoundTrip(of: type.greatestFiniteMagnitude, file: file, line: line)
        _testRoundTrip(of: type.infinity, file: file, line: line)
    }

    func testValuesInKeyedContainer() throws {
        _testRoundTrip(of: KeyedSynthesized(
            bool: true, int: .max, int8: .max, int16: .max, int32: .max, int64: .max,
            uint: .max, uint8: .max, uint16: .max, uint32: .max, uint64: .max,
            float: .greatestFiniteMagnitude, double: .greatestFiniteMagnitude, string: "", optionalString: nil,
            url: URL(string: "https://apple.com")!
        ))
    }

    func testValuesInUnkeyedContainer() throws {
        _testRoundTrip(of: Unkeyed(
            bool: true, int: .max, int8: .max, int16: .max, int32: .max, int64: .max,
            uint: .max, uint8: .max, uint16: .max, uint32: .max, uint64: .max,
            float: .greatestFiniteMagnitude, double: .greatestFiniteMagnitude, string: "", optionalString: nil,
            url: URL(string: "https://apple.com")!
        ))
    }

    func testDictionary() throws {
        // https://github.com/jpsim/Yams/issues/99
        let yaml = "'200': ok"
        let decodedYaml = try YAMLDecoder().decode([String: String].self, from: yaml)
        XCTAssertEqual(decodedYaml, ["200": "ok"])
    }

    func testNodeTypeMismatch() throws {
        // https://github.com/jpsim/Yams/pull/95
        struct Sample: Decodable {
            // Used for its decodable behavior, even though it's not referenced directly.
            // swiftlint:disable:next unused_private_declaration
            let values: [String]
        }

        let validYaml = """
            values:
            - hello
            """
        XCTAssertNoThrow(try YAMLDecoder().decode(Sample.self, from: validYaml))

        let invalidYamls = [
        // expecting scalar,
            // but mapping instead
            """
            values:
            - hello:
            """,
            // but sequence instead
            """
            values:
            - [hello1, hello2]
            """,
        // expecting mapping,
            // but scalar instead
            """
            hello
            """,
            // but sequence instead
            """
            - hello
            """,
        // expecting sequence,
            // but scalar instead
            """
            values: hello
            """,
            // but mapping instead
            """
            values:
              hello:
            """
        ]
        for invalidYaml in invalidYamls {
            XCTAssertThrowsError(try YAMLDecoder().decode(Sample.self, from: invalidYaml)) { error in
                if case DecodingError.typeMismatch = error {} else {
                    XCTFail("unexpected error: \(error)")
                }
            }
        }
    }

    func testDecodingConcreteTypeParameter() {
        let encoder = YAMLEncoder()
        guard let yaml = try? encoder.encode(Employee.testValue) else {
            expectUnreachable("Unable to encode Employee.")
            return
        }

        let decoder = YAMLDecoder()
        guard let decoded = try? decoder.decode(Employee.self as Person.Type, from: yaml) else {
            expectUnreachable("Failed to decode Employee as Person from YAML.")
            return
        }

        expectEqual(type(of: decoded), Employee.self, "Expected decoded value to be of type Employee; got \(type(of: decoded)) instead.")
    }

    func test_null_yml() throws {
        let s = """
              n1: ~
              n2: null
              n3: NULL
              n4: Null
              n5:
            """
        struct Test: Decodable {
            let n1: String?
            let n2: String?
            let n3: String?
            let n4: String?
            let n5: String?
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertNil(t.n1)
        XCTAssertNil(t.n2)
        XCTAssertNil(t.n3)
        XCTAssertNil(t.n4)
        XCTAssertNil(t.n5)
    }

    // MARK: - Helper Functions

    private func _testRoundTrip<T>(of value: T,
                                   with options: YAMLEncoder.Options = .init(),
                                   expectedYAML yamlString: String? = nil,
                                   file: StaticString = #file,
                                   line: UInt = #line) where T: Codable, T: Equatable {
        do {
            let encoder = YAMLEncoder()
            encoder.options = options
            let producedYAML = try encoder.encode(value)

            if let expectedYAML = yamlString {
                XCTAssertEqual(producedYAML, expectedYAML, "Produced YAML not identical to expected YAML.",
                               file: file, line: line)
            }

            let decoder = YAMLDecoder()
            let decoded = try decoder.decode(T.self, from: producedYAML)
            XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.",
                file: file, line: line)

        } catch let error as EncodingError {
            XCTFail("Failed to encode \(T.self) from YAML by error: \(error)", file: file, line: line)
        } catch let error as DecodingError {
            XCTFail("Failed to decode \(T.self) from YAML by error: \(error)", file: file, line: line)
        } catch {
            XCTFail("Rout trip test of \(T.self) failed with error: \(error)", file: file, line: line)
        }
    }
}

// MARK: - Helper Global Functions
public func expectEqual<T: Equatable>(
    _ expected: T, _ actual: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
    ) {
    XCTAssertEqual(expected, actual, message(), file: file, line: line)
}

public func expectEqual(
    _ expected: Any.Type, _ actual: Any.Type,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
    ) {
    XCTAssertTrue(expected == actual, message(), file: file, line: line)
}

public func expectUnreachable(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    XCTFail("this code should not be executed: \(message())", file: file, line: line)
}

func expectEqualPaths(
    _ lhs: [CodingKey],
    _ rhs: [CodingKey],
    _ prefix: String,
    file: StaticString = #file, line: UInt = #line) {
    if lhs.count != rhs.count {
        expectUnreachable("\(prefix) [CodingKey].count mismatch: \(lhs.count) != \(rhs.count)", file: file, line: line)
        return
    }

    for (key1, key2) in zip(lhs, rhs) {
        switch (key1.intValue, key2.intValue) {
        case (.none, .none): break
        case (.some(let i1), .none):
            expectUnreachable("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != nil", file: file, line: line)
            return
        case (.none, .some(let i2)):
            expectUnreachable("\(prefix) CodingKey.intValue mismatch: nil != \(type(of: key2))(\(i2))", file: file, line: line)
            return
        case (.some(let i1), .some(let i2)):
            guard i1 == i2 else {
                expectUnreachable("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != \(type(of: key2))(\(i2))", file: file, line: line)
                return
            }
        }

        expectEqual(key1.stringValue, key2.stringValue, "\(prefix) CodingKey.stringValue mismatch: \(type(of: key1))('\(key1.stringValue)') != \(type(of: key2))('\(key2.stringValue)')", file: file, line: line)
    }
}

// MARK: - Empty Types
private struct EmptyStruct: Codable, Equatable {
    static func == (_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
        return true
    }
}

private class EmptyClass: Codable, Equatable {
    static func == (_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
        return true
    }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
private enum Switch: Codable {
    case off
    case on

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
private struct Timestamp: Codable, Equatable {
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
private final class Counter: Codable, Equatable {
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
        return lhs === rhs || lhs.count == rhs.count
    }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
private struct Address: Codable, Equatable {
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
private class Person: Codable, Equatable {
    let name: String
    let email: String
    let website: URL?

    init(name: String, email: String, website: URL? = nil) {
        self.name = name
        self.email = email
        self.website = website
    }

#if !swift(>=4.1.50)
    private enum CodingKeys: String, CodingKey {
        case name
        case email
        case website
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        website = try container.decodeIfPresent(URL.self, forKey: .website)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(website, forKey: .website)
    }
#endif

    func isEqual(_ other: Person) -> Bool {
        return self.name == other.name &&
            self.email == other.email &&
            self.website == other.website
    }

    static func == (_ lhs: Person, _ rhs: Person) -> Bool {
        return lhs.isEqual(rhs)
    }

    class var testValue: Person {
        return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
    }
}

/// A class which shares its encoder and decoder with its superclass.
private class Employee: Person {
    let id: Int

    init(name: String, email: String, website: URL? = nil, id: Int) {
        self.id = id
        super.init(name: name, email: email, website: website)
    }

    enum CodingKeys: String, CodingKey {
        case id
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try super.encode(to: encoder)
    }

    override func isEqual(_ other: Person) -> Bool {
        if let employee = other as? Employee {
            guard self.id == employee.id else { return false }
        }

        return super.isEqual(other)
    }

    override class var testValue: Employee {
        return Employee(name: "Johnny Appleseed", email: "appleseed@apple.com", id: 42)
    }
}

/// A simple company struct which encodes as a dictionary of nested values.
private struct Company: Codable, Equatable {
    let address: Address
    var employees: [Employee]

    init(address: Address, employees: [Employee]) {
        self.address = address
        self.employees = employees
    }

    static func == (_ lhs: Company, _ rhs: Company) -> Bool {
        return lhs.address == rhs.address && lhs.employees == rhs.employees
    }

    static var testValue: Company {
        return Company(address: Address.testValue, employees: [Employee.testValue])
    }
}

/// An enum type which decodes from Bool?.
private enum EnhancedBool: Codable {
    case `true`
    case `false`
    case fileNotFound

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .fileNotFound
        } else {
            let value = try container.decode(Bool.self)
            self = value ? .true : .false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .true: try container.encode(true)
        case .false: try container.encode(false)
        case .fileNotFound: try container.encodeNil()
        }
    }
}

/// A type which encodes as an array directly through a single value container.
struct Numbers: Codable, Equatable {
    let values = [4, 8, 15, 16, 23, 42]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValues = try container.decode([Int].self)
        guard decodedValues == values else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The Numbers are wrong!"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func == (_ lhs: Numbers, _ rhs: Numbers) -> Bool {
        return lhs.values == rhs.values
    }

    static var testValue: Numbers {
        return Numbers()
    }
}

/// A type which encodes as a dictionary directly through a single value container.
private final class Mapping: Codable, Equatable {
    let values: [String: URL]

    init(values: [String: URL]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String: URL].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func == (_ lhs: Mapping, _ rhs: Mapping) -> Bool {
        return lhs === rhs || lhs.values == rhs.values
    }

    static var testValue: Mapping {
        return Mapping(values: ["Apple": URL(string: "http://apple.com")!,
                                "localhost": URL(string: "http://127.0.0.1")!])
    }
}

struct NestedContainersTestType: Codable, Equatable {
    let testSuperCoder: Bool

    static func == (lhs: NestedContainersTestType, rhs: NestedContainersTestType) -> Bool {
        return lhs.testSuperCoder == rhs.testSuperCoder
    }

    init(testSuperCoder: Bool = false) {
        self.testSuperCoder = testSuperCoder
    }

    enum TopLevelCodingKeys: Int, CodingKey {
        case testSuperCoder
        case a
        case b
        case c
    }

    enum IntermediateCodingKeys: Int, CodingKey {
        case one
        case two
    }

    // swiftlint:disable line_length
    func encode(to encoder: Encoder) throws {
        var topLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
        try topLevelContainer.encode(testSuperCoder, forKey: .testSuperCoder)

        if self.testSuperCoder {
            expectEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "New first-level keyed container has non-empty codingPath.")

            let superEncoder = topLevelContainer.superEncoder(forKey: .a)
            expectEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(superEncoder.codingPath, [TopLevelCodingKeys.a], "New superEncoder had unexpected codingPath.")
            _testNestedContainers(in: superEncoder, baseCodingPath: [TopLevelCodingKeys.a])
        } else {
            _testNestedContainers(in: encoder, baseCodingPath: [])
        }
    }

    func _testNestedContainers(in encoder: Encoder, baseCodingPath: [CodingKey]) {
        expectEqualPaths(encoder.codingPath, baseCodingPath, "New encoder has non-empty codingPath.")

        // codingPath should not change upon fetching a non-nested container.
        var firstLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
        expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
        expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "New first-level keyed container has non-empty codingPath.")

        // Nested Keyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .a)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "New second-level keyed container had unexpected codingPath.")

            // Inserting a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .one)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.one], "New third-level keyed container had unexpected codingPath.")

            // Inserting an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer(forKey: .two)
            expectEqualPaths(encoder.codingPath, baseCodingPath + [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath + [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.two], "New third-level unkeyed container had unexpected codingPath.")
        }

        // Nested Unkeyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedUnkeyedContainer(forKey: .b)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "New second-level keyed container had unexpected codingPath.")

            // Appending a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 0)], "New third-level keyed container had unexpected codingPath.")

            // Appending an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer()
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 1)], "New third-level unkeyed container had unexpected codingPath.")
        }
    }

    init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: TopLevelCodingKeys.self)
        testSuperCoder = try topLevelContainer.decode(Bool.self, forKey: .testSuperCoder)
        if self.testSuperCoder {
            expectEqualPaths(decoder.codingPath, [], "Top-level Decoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "New first-level keyed container has non-empty codingPath.")

            let superDecoder = try topLevelContainer.superDecoder(forKey: .a)
            expectEqualPaths(decoder.codingPath, [], "Top-level Decoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(superDecoder.codingPath, [TopLevelCodingKeys.a], "New superDecoder had unexpected codingPath.")
            try _testNestedContainers(in: superDecoder, baseCodingPath: [TopLevelCodingKeys.a])
        } else {
            try _testNestedContainers(in: decoder, baseCodingPath: [])
        }
    }

    func _testNestedContainers(in decoder: Decoder, baseCodingPath: [CodingKey]) throws {
        expectEqualPaths(decoder.codingPath, baseCodingPath, "New decoder has non-empty codingPath.")

        // codingPath should not change upon fetching a non-nested container.
        let firstLevelContainer = try decoder.container(keyedBy: TopLevelCodingKeys.self)
        expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
        expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "New first-level keyed container has non-empty codingPath.")

        // Nested Keyed Container
        do {
            // Nested container for key should have a new key pushed on.
            let secondLevelContainer = try firstLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .a)
            expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "New second-level keyed container had unexpected codingPath.")

            // Inserting a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = try secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .one)
            expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.one], "New third-level keyed container had unexpected codingPath.")

            // Inserting an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = try secondLevelContainer.nestedUnkeyedContainer(forKey: .two)
            expectEqualPaths(decoder.codingPath, baseCodingPath + [], "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath + [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.two], "New third-level unkeyed container had unexpected codingPath.")
        }

        // Nested Unkeyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = try firstLevelContainer.nestedUnkeyedContainer(forKey: .b)
            expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "New second-level keyed container had unexpected codingPath.")

            // Appending a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = try secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self)
            expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 0)], "New third-level keyed container had unexpected codingPath.")

            // Appending an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = try secondLevelContainer.nestedUnkeyedContainer()
            expectEqualPaths(decoder.codingPath, baseCodingPath, "Top-level Decoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 1)], "New third-level unkeyed container had unexpected codingPath.")
        }
    }
}

// MARK: - Helper Types

/// A key type which can take on any string or integer value.
/// This needs to mirror _YAMLKey.
private struct _TestKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
}

/// Wraps a type T so that it can be encoded at the top level of a payload.
private struct TopLevelWrapper<T> : Codable, Equatable where T: Codable, T: Equatable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    static func == (_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

/// Wraps a type T (as T?) so that it can be encoded at the top level of a payload.
private struct OptionalTopLevelWrapper<T> : Codable, Equatable where T: Codable, T: Equatable {
    let value: T?

    init(_ value: T) {
        self.value = value
    }

    // Provide an implementation of Codable to encode(forKey:) instead of encodeIfPresent(forKey:).
    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(T?.self, forKey: .value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }

    static func == (_ lhs: OptionalTopLevelWrapper<T>, _ rhs: OptionalTopLevelWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

/// Coder supported types in KeyedContainer
struct KeyedSynthesized: Codable, Equatable {
    static func == (lhs: KeyedSynthesized, rhs: KeyedSynthesized) -> Bool {
        return lhs.bool == rhs.bool &&
            lhs.int == rhs.int && lhs.int8 == rhs.int8 &&  lhs.int16 == rhs.int16 &&
            lhs.int32 == rhs.int32 && lhs.int64 == rhs.int64 &&
            lhs.uint == rhs.uint && lhs.uint8 == rhs.uint8 &&  lhs.uint16 == rhs.uint16 &&
            lhs.uint32 == rhs.uint32 && lhs.uint64 == rhs.uint64 &&
            lhs.float == rhs.float && lhs.double == rhs.double &&
            lhs.string == rhs.string && lhs.optionalString == rhs.optionalString &&
            lhs.url == rhs.url
    }

    var bool: Bool = true
    let int: Int
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uint: UInt
    let uint8: UInt8
    let uint16: UInt16
    let uint32: UInt32
    let uint64: UInt64
    let float: Float
    let double: Double
    let string: String
    let optionalString: String?
    let url: URL
}

/// Coder supported types in UnkeyedContainer
struct Unkeyed: Codable, Equatable {
    static func == (lhs: Unkeyed, rhs: Unkeyed) -> Bool {
        return lhs.bool == rhs.bool &&
            lhs.int == rhs.int && lhs.int8 == rhs.int8 &&  lhs.int16 == rhs.int16 &&
            lhs.int32 == rhs.int32 && lhs.int64 == rhs.int64 &&
            lhs.uint == rhs.uint && lhs.uint8 == rhs.uint8 &&  lhs.uint16 == rhs.uint16 &&
            lhs.uint32 == rhs.uint32 && lhs.uint64 == rhs.uint64 &&
            lhs.float == rhs.float && lhs.double == rhs.double &&
            lhs.string == rhs.string && lhs.optionalString == rhs.optionalString &&
            lhs.url == rhs.url
    }

    let bool: Bool
    let int: Int
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uint: UInt
    let uint8: UInt8
    let uint16: UInt16
    let uint32: UInt32
    let uint64: UInt64
    let float: Float
    let double: Double
    let string: String
    let optionalString: String?
    let url: URL

    init(
        bool: Bool, int: Int, int8: Int8, int16: Int16, int32: Int32, int64: Int64,
        uint: UInt, uint8: UInt8, uint16: UInt16, uint32: UInt32, uint64: UInt64,
        float: Float, double: Double, string: String, optionalString: String?, url: URL) {
        self.bool = bool
        self.int = int
        self.int8 = int8
        self.int16 = int16
        self.int32 = int32
        self.int64 = int64
        self.uint = uint
        self.uint8 = uint8
        self.uint16 = uint16
        self.uint32 = uint32
        self.uint64 = uint64
        self.float = float
        self.double = double
        self.string = string
        self.optionalString = optionalString
        self.url = url
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        bool = try container.decode(Bool.self)
        int = try container.decode(Int.self)
        int8 = try container.decode(Int8.self)
        int16 = try container.decode(Int16.self)
        int32 = try container.decode(Int32.self)
        int64 = try container.decode(Int64.self)
        uint = try container.decode(UInt.self)
        uint8 = try container.decode(UInt8.self)
        uint16 = try container.decode(UInt16.self)
        uint32 = try container.decode(UInt32.self)
        uint64 = try container.decode(UInt64.self)
        float = try container.decode(Float.self)
        double = try container.decode(Double.self)
        string = try container.decode(String.self)
        optionalString = try container.decode(String?.self)
        url = try container.decode(URL.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(bool)
        try container.encode(int)
        try container.encode(int8)
        try container.encode(int16)
        try container.encode(int32)
        try container.encode(int64)
        try container.encode(uint)
        try container.encode(uint8)
        try container.encode(uint16)
        try container.encode(uint32)
        try container.encode(uint64)
        try container.encode(float)
        try container.encode(double)
        try container.encode(string)
        try container.encode(optionalString)
        try container.encode(url)
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
            ("testEncodingTopLevelStructuredSingleStruct", testEncodingTopLevelStructuredSingleStruct),
            ("testEncodingTopLevelStructuredSingleClass", testEncodingTopLevelStructuredSingleClass),
            ("testEncodingTopLevelDeepStructuredType", testEncodingTopLevelDeepStructuredType),
            ("testEncodingClassWhichSharesEncoderWithSuper", testEncodingClassWhichSharesEncoderWithSuper),
            ("testEncodingTopLevelNullableType", testEncodingTopLevelNullableType),
            ("testEncodingDate", testEncodingDate),
            ("testEncodingDateMillisecondsSince1970", testEncodingDateMillisecondsSince1970),
            ("testEncodingBase64Data", testEncodingBase64Data),
            ("testNestedContainerCodingPaths", testNestedContainerCodingPaths),
            ("testSuperEncoderCodingPaths", testSuperEncoderCodingPaths),
            ("testInterceptDecimal", testInterceptDecimal),
            ("testInterceptURL", testInterceptURL),
            ("testValuesInSingleValueContainer", testValuesInSingleValueContainer),
            ("testValuesInKeyedContainer", testValuesInKeyedContainer),
            ("testValuesInUnkeyedContainer", testValuesInUnkeyedContainer),
            ("testDictionary", testDictionary),
            ("testNodeTypeMismatch", testNodeTypeMismatch),
            ("testDecodingConcreteTypeParameter", testDecodingConcreteTypeParameter),
            ("test_null_yml", test_null_yml)
        ]
    }
}

// swiftlint:disable:this file_length
