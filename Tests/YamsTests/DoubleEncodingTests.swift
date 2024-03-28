import Foundation
import XCTest
import Yams

class DoubleEncodingTests: XCTestCase {
    override class func setUp() {
        Emitter.Options.doubleFormatStyle = .decimal
    }

    func testDecimalDoubleStyle() throws {
        XCTAssertEqual(try Node(Double(6.85)), "6.85")
    }

    func testMinimumFractionDigits() throws {
        XCTAssertEqual(try Node(Double(6.0)), "6.0")
    }

    func testDecimalDoubleStyleBox() throws {
        print(try Double(6.85).box(), "6.85")
    }

    func testMinimumFractionDigitsBox() throws {
        print(try Double(6.0).box(), "6.0")
    }
}

extension DoubleEncodingTests {
    static var allTests: [(String, (DoubleEncodingTests) -> () throws -> Void)] {
        return [
            ("testDecimalDoubleStyle", testDecimalDoubleStyle),
            ("testMinimumFractionDigits", testMinimumFractionDigits),
            ("testDecimalDoubleStyleBox", testDecimalDoubleStyleBox),
            ("testMinimumFractionDigitsBox", testMinimumFractionDigitsBox)
        ]
    }
}
