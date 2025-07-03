//
//  TestHelper.swift
//  Yams
//
//  Created by Norio Nomura on 12/22/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation
import XCTest

private let gregorianCalendar = Calendar(identifier: .gregorian)

func timestamp(_ timeZoneHour: Int = 0,
               _ year: Int? = nil,
               _ month: Int? = nil,
               _ day: Int? = nil,
               _ hour: Int? = nil,
               _ minute: Int? = nil,
               _ second: Int? = nil,
               _ fraction: Double? = nil ) -> Date {
    let timeZone = TimeZone(secondsFromGMT: timeZoneHour * 60 * 60)
    let dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone,
                                        year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second)
    guard let date = dateComponents.date else { fatalError("Tests shouldn't create timestamps for invalid dates") }
    return fraction.map(date.addingTimeInterval) ?? date
}

/// AssertEqual for Any
///
/// - parameter lhs: Any
/// - parameter rhs: Any
/// - parameter context: Closure generating String that used on generating assertion
/// - parameter file: file path string
/// - parameter line: line number
///
/// - returns: true if lhs is equal to rhs
@discardableResult
func YamsAssertEqual(_ lhs: Any?, _ rhs: Any?,
                     // swiftlint:disable:previous identifier_name
                     _ context: @autoclosure @escaping () -> String = "",
                     file: StaticString = #file, line: UInt = #line) -> Bool {
    // use inner function for capturing `file` and `line`
    // swiftlint:disable:next cyclomatic_complexity
    @discardableResult func equal(_ lhs: Any?, _ rhs: Any?,
                                  _ context: @autoclosure @escaping () -> String = "") -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs as [Any], rhs as [Any]):
            equal(lhs.count, rhs.count, joined("comparing count of \(dumped(lhs)) to \(dumped(rhs))", context()))
            for (index, (lhsElement, rhsElement)) in zip(lhs, rhs).enumerated() where !equal(
                lhsElement, rhsElement,
                joined("elements at \(index) from \(dumped(lhs)) and \(dumped(rhs))", context())) {
                    return false
            }
            return true
        case let (lhs as [String: Any], rhs as [String: Any]):
            let message1 = { "comparing count of \(dumped(lhs)) to \(dumped(rhs))" }
            equal(lhs.count, rhs.count, joined(message1(), context()))
            let keys = Set(lhs.keys).union(rhs.keys)
            for key in keys where !equal(
                lhs[key], rhs[key],
                joined("values for key(\"\(key)\") in \(dumped(lhs)) and \(dumped(rhs))", context())) {
                    return false
            }
            return true
        case let (lhs?, nil):
            let message = { "(\"\(type(of: lhs))(\(dumped(lhs)))\") is not equal to (\"nil\")" }
            XCTFail(joined(message(), context()), file: (file), line: line)
            return false
        case let (nil, rhs?):
            let message = { "(\"nil\") is not equal to (\"\(type(of: rhs))(\(dumped(rhs)))\")" }
            XCTFail(joined(message(), context()), file: (file), line: line)
            return false
        case let (lhs as Double, rhs as Double):
            if lhs.isNaN && rhs.isNaN { return true } // NaN is not equal to any value, including NaN
            XCTAssertEqual(lhs, rhs, context(), file: (file), line: line)
            return lhs == rhs
        case let (lhs as AnyHashable, rhs as AnyHashable):
            XCTAssertEqual(lhs, rhs, context(), file: (file), line: line)
            return lhs == rhs
        case let (lhs as (Any, Any), rhs as (Any, Any)):
            return equal(lhs.0, rhs.0) && equal(lhs.1, rhs.1)
        case let (lhs as Set<AnyHashable>, rhs as Set<AnyHashable>):
            return lhs == rhs
        default:
            let message = { "Can't compare \(type(of: lhs))(\(dumped(lhs))) to \(type(of: rhs))(\(dumped(rhs)))" }
            XCTFail(joined(message(), context()), file: (file), line: line)
            return false
        }
    }
    return equal(lhs, rhs, context())
}

func YamsAssertEqualType(_ actual: Any?, _ expected: Any?, path: [String] = []) {
    // swiftlint:disable:previous identifier_name
    let pathString = path.joined(separator: ".")

    guard let actual = actual else {
        XCTFail("Actual is nil at '\(pathString)'")
        return
    }
    guard let expected = expected else {
        XCTFail("Expected is nil at '\(pathString)'")
        return
    }

    let actualType = type(of: actual)
    let expectedType = type(of: expected)

    switch (actual, expected) {
    case let (aDict as [String: Any], eDict as [String: Any]):
        XCTAssertEqual(aDict.count, eDict.count, "Dictionary count mismatch at '\(pathString)'")
        for key in eDict.keys {
            guard let aValue = aDict[key], let eValue = eDict[key] else {
                XCTFail("Missing key '\(key)' at '\(pathString)'")
                continue
            }
            YamsAssertEqualType(aValue, eValue, path: path + [key])
        }

    case let (aArray as [Any], eArray as [Any]):
        XCTAssertEqual(aArray.count, eArray.count, "Array count mismatch at '\(pathString)'")
        for index in 0..<eArray.count {
            YamsAssertEqualType(aArray[index], eArray[index], path: path + ["[\(index)]"])
        }

    default:
        XCTAssertEqual(String(describing: actualType),
                       String(describing: expectedType),
                       "Type mismatch at '\(pathString)'")
    }
}

private func dumped<T>(_ value: T) -> String {
    var output = ""
    dump(value, to: &output)
    let outputs = output.components(separatedBy: .newlines)
    let firstLine = outputs.first ?? ""
    let count = outputs.count
    if count == 1 {
        // remove `- ` prefix if
        let index = firstLine.index(firstLine.startIndex, offsetBy: 2)
        return String(firstLine[index...])
    } else {
        return "[\n" + output + "]"
    }
}

private func joined(_ lhs: String, _ rhs: String) -> String {
    return lhs.isEmpty ? rhs : rhs.isEmpty ? lhs : lhs + " " + rhs
}
