import Foundation
import XCTest
import Yams

class DoubleEncodingTests: XCTestCase {
    // private let cachedFormatStyle: NumberFormatter.Style

    override class func setUp() {
        // cachedFormatStyle = Emitter.Options.doubleFormatStyle
        Emitter.Options.doubleFormatStyle = .decimal
    }

    func testDecimalDoubleStyle() throws {
        // let cachedFormatStyle = Emitter.Options.doubleFormatStyle
        // defer {
        //     Emitter.Options.doubleFormatStyle = cachedFormatStyle
        // }

        // Emitter.Options.doubleFormatStyle = .decimal
        XCTAssertEqual(try Node(Double(6.85)), "6.85")
    }

    func testMinimumFractionDigits() throws {
        // let cachedFormatStyle = Emitter.Options.doubleFormatStyle
        // defer {
        //     Emitter.Options.doubleFormatStyle = cachedFormatStyle
        // }

        // Emitter.Options.doubleFormatStyle = .decimal
        XCTAssertEqual(try Node(Double(6.0)), "6.0")
    }
}

extension DoubleEncodingTests {
    static var allTests: [(String, (DoubleEncodingTests) -> () throws -> Void)] {
        return [
            ("testDecimalDoubleStyle", testDecimalDoubleStyle),
            ("testMinimumFractionDigits", testMinimumFractionDigits),
        ]
    }
}
