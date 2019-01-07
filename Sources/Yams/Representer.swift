//
//  Representer.swift
//  Yams
//
//  Created by Norio Nomura on 1/8/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

#if SWIFT_PACKAGE
import CYaml
import SwiftDtoa
#endif
#if os(Linux)
import CoreFoundation
#endif
import Foundation

public extension Node {
    /// Initialize a `Node` with a value of `NodeRepresentable`.
    ///
    /// - parameter representable: Value of `NodeRepresentable` to represent as a `Node`.
    ///
    /// - throws: `YamlError`.
    init<T: NodeRepresentable>(_ representable: T) throws {
        self = try representable.represented()
    }
}

// MARK: - NodeRepresentable
/// Type is representable as `Node`.
public protocol NodeRepresentable {
    /// This value's `Node` representation.
    func represented() throws -> Node
}

extension Node: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        return self
    }
}

extension Array: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let nodes = try map(represent)
        return Node(nodes, Tag(.seq))
    }
}

extension Dictionary: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
        return Node(pairs.sorted { $0.key < $1.key }, Tag(.map))
    }
}

private func represent(_ value: Any) throws -> Node {
    if let string = value as? String {
        return Node(string)
    } else if let representable = value as? NodeRepresentable {
        return try representable.represented()
    }
    throw YamlError.representer(problem: "Failed to represent \(value)")
}

// MARK: - ScalarRepresentable
/// Type is representable as `Node.scalar`.
public protocol ScalarRepresentable: NodeRepresentable {
    /// This value's `Node.scalar` representation.
    func represented() -> Node.Scalar
}

extension ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() throws -> Node {
        return .scalar(represented())
    }
}

extension Bool: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(self ? "true" : "false", Tag(.bool))
    }
}

extension Data: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(base64EncodedString(), Tag(.binary))
    }
}

extension Date: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(iso8601String, Tag(.timestamp))
    }

    private var iso8601String: String {
#if !_runtime(_ObjC) && !swift(>=5.0)
        // swift-corelibs-foundation has bug with nanosecond.
        // https://bugs.swift.org/browse/SR-3158
        return iso8601Formatter.string(from: self)
#else
        let calendar = Calendar(identifier: .gregorian)
        let nanosecond = calendar.component(.nanosecond, from: self)
        if nanosecond != 0 {
            return iso8601WithFractionalSecondFormatter.string(from: self)
                .trimmingCharacters(in: characterSetZero) + "Z"
        } else {
            return iso8601Formatter.string(from: self)
        }
#endif
    }

    private var iso8601StringWithFullNanosecond: String {
        let calendar = Calendar(identifier: .gregorian)
        let nanosecond = calendar.component(.nanosecond, from: self)
        if nanosecond != 0 {
            return iso8601WithoutZFormatter.string(from: self) +
                String(format: ".%09d", nanosecond).trimmingCharacters(in: characterSetZero) + "Z"
        } else {
            return iso8601Formatter.string(from: self)
        }
    }
}

private let characterSetZero = CharacterSet(charactersIn: "0")

private let iso8601Formatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

private let iso8601WithoutZFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

// DateFormatter truncates Fractional Second to 10^-4
private let iso8601WithFractionalSecondFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

extension FloatingPoint where Self: HasExponentialFormatter {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(exponentialFormattedString, Tag(.float))
    }
}

extension Double: ScalarRepresentable {}
extension Float: ScalarRepresentable {}
#if !swift(>=4.2)
// `Float80` requires Swift 4.2 or later
#else
extension Float80: ScalarRepresentable {}
#endif

extension BinaryInteger {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(String(describing: self), Tag(.int))
    }
}

extension Int: ScalarRepresentable {}
extension Int16: ScalarRepresentable {}
extension Int32: ScalarRepresentable {}
extension Int64: ScalarRepresentable {}
extension Int8: ScalarRepresentable {}
extension UInt: ScalarRepresentable {}
extension UInt16: ScalarRepresentable {}
extension UInt32: ScalarRepresentable {}
extension UInt64: ScalarRepresentable {}
extension UInt8: ScalarRepresentable {}

extension Optional: NodeRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() throws -> Node {
        switch self {
        case let .some(wrapped):
            return try represent(wrapped)
        case .none:
            return Node("null", Tag(.null))
        }
    }
}

extension Decimal: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(description)
    }
}

extension URL: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(absoluteString)
    }
}

extension String: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(self)
    }
}

/// MARK: - ScalarRepresentableCustomizedForCodable

/// Types conforming to this protocol can be encoded by `YamlEncoder`.
public protocol YAMLEncodable: Encodable {
    /// Returns this value wrapped in a `Node`.
    func box() -> Node
}

extension YAMLEncodable where Self: ScalarRepresentable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return .scalar(represented())
    }
}

extension Bool: YAMLEncodable {}
extension Data: YAMLEncodable {}
extension Decimal: YAMLEncodable {}
extension Int: YAMLEncodable {}
extension Int8: YAMLEncodable {}
extension Int16: YAMLEncodable {}
extension Int32: YAMLEncodable {}
extension Int64: YAMLEncodable {}
extension UInt: YAMLEncodable {}
extension UInt8: YAMLEncodable {}
extension UInt16: YAMLEncodable {}
extension UInt32: YAMLEncodable {}
extension UInt64: YAMLEncodable {}
extension URL: YAMLEncodable {}
extension String: YAMLEncodable {}

extension Date: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node(iso8601StringWithFullNanosecond, Tag(.timestamp))
    }
}

extension Double: YAMLEncodable {}
extension Float: YAMLEncodable {}
// `Float80` can not conform to `YAMLEncodable` since that does not conform to `Codable`.
// https://bugs.swift.org/browse/SR-9607
//extension Float80: YAMLEncodable {}

public protocol HasExponentialFormatter: FloatingPoint {
    func decompose() -> (digits: ArraySlice<Int8>, decimalExponent: Int32)
}

extension HasExponentialFormatter {
    var exponentialFormattedString: String {
        if !isFinite {
            if isInfinite {
                switch sign {
                case .minus:
                    return "-.inf"
                case .plus:
                    return ".inf"
                }
            } else {
                return ".nan"
            }
        }
        let (digits, decimalExponent) = decompose()
        var buffer = ContiguousArray<Int8>(repeating: 0, count: 32)
        let length = buffer.withUnsafeMutableBufferPointer { dest in
            digits.withUnsafeBufferPointer { digits in
                swift_format_exponential(dest.baseAddress, dest.count, sign == .minus, digits.baseAddress, numericCast(digits.count), decimalExponent)
            }
        }
        return buffer.prefix(length).withUnsafeBytes { String(bytes: $0, encoding: .utf8)! }
    }
}

extension Double: HasExponentialFormatter {
    public func decompose() -> (digits: ArraySlice<Int8>, decimalExponent: Int32) {
        var decimalExponent = Int32(0)
        var buffer = ContiguousArray<Int8>(repeating: 0, count: numericCast(DBL_DECIMAL_DIG))
        let digitCount = buffer.withUnsafeMutableBufferPointer {
            swift_decompose_double(self, $0.baseAddress, $0.count, &decimalExponent)
        }
        return (buffer.prefix(numericCast(digitCount)), decimalExponent)
    }
}

extension Float: HasExponentialFormatter {
    public func decompose() -> (digits: ArraySlice<Int8>, decimalExponent: Int32) {
        var decimalExponent = Int32(0)
        var buffer = ContiguousArray<Int8>(repeating: 0, count: numericCast(FLT_DECIMAL_DIG))
        let digitCount = buffer.withUnsafeMutableBufferPointer {
            swift_decompose_float(self, $0.baseAddress, $0.count, &decimalExponent)
        }
        return (buffer.prefix(numericCast(digitCount)), decimalExponent)
    }
}

#if !swift(>=4.2)
// `swift_decompose_float80` exists on Swift 4.2 or later
#else
extension Float80: HasExponentialFormatter {
    public func decompose() -> (digits: ArraySlice<Int8>, decimalExponent: Int32) {
        var decimalExponent = Int32(0)
        var buffer = ContiguousArray<Int8>(repeating: 0, count: numericCast(LDBL_DECIMAL_DIG))
        let digitCount = buffer.withUnsafeMutableBufferPointer {
            swift_decompose_float80(self, $0.baseAddress, $0.count, &decimalExponent)
        }
        return (buffer.prefix(numericCast(digitCount)), decimalExponent)
    }
}
#endif

@available(*, unavailable, renamed: "YAMLEncodable")
typealias ScalarRepresentableCustomizedForCodable = YAMLEncodable

extension YAMLEncodable {
    @available(*, unavailable, renamed: "box()")
    func representedForCodable() -> Node { fatalError("unreachable") }
}
