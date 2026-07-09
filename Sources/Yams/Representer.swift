//
//  Representer.swift
//  Yams
//
//  Created by Norio Nomura on 1/8/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

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

#if canImport(ObjectiveC)
extension NSArray: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let nodes = try map(represent)
        return Node(nodes, Tag(.seq))
    }
}
#endif

extension Dictionary: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
        return Node(pairs.sorted { $0.key < $1.key }, Tag(.map))
    }
}

#if canImport(ObjectiveC)
extension NSDictionary: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
        return Node(pairs.sorted { $0.key < $1.key }, Tag(.map))
    }
}
#endif

private func represent(_ value: Any) throws -> Node {
    if let representable = value as? NodeRepresentable {
        return try representable.represented()
    }
    #if canImport(ObjectiveC)
    if (value as? NSDictionary)?.count == 0 {
        return .mapping(Node.Mapping([]))
    }
    #endif
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

extension YAMLNull: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init("null", Tag(.null))
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
        let (integral, millisecond) = timeIntervalSinceReferenceDate.separateFractionalSecond(withPrecision: 3)
        guard millisecond != 0 else { return formatted(iso8601FormatStyle) }

        let dateWithoutMillisecond = Date(timeIntervalSinceReferenceDate: integral)
        return dateWithoutMillisecond.formatted(iso8601WithoutZFormatStyle) +
            ("." + zeroPad(millisecond, width: 3)).trimmingTrailingCharacters("0") + "Z"
    }

    private var iso8601StringWithFullNanosecond: String {
        let (integral, nanosecond) = timeIntervalSinceReferenceDate.separateFractionalSecond(withPrecision: 9)
        guard nanosecond != 0 else { return formatted(iso8601FormatStyle) }

        let dateWithoutNanosecond = Date(timeIntervalSinceReferenceDate: integral)
        return dateWithoutNanosecond.formatted(iso8601WithoutZFormatStyle) +
            ("." + zeroPad(nanosecond, width: 9)).trimmingTrailingCharacters("0") + "Z"
    }
}

private extension TimeInterval {
    func separateFractionalSecond(withPrecision precision: Int) -> (integral: TimeInterval, fractional: Int) {
        var integral = 0.0
        let fractional = modf(self, &integral)

        let radix = pow(10.0, Double(precision))

        let rounded = Int((fractional * radix).rounded())
        let quotient = rounded / Int(radix)
        return quotient != 0 ?
            (integral + TimeInterval(quotient), rounded % Int(radix)) :
            (integral, rounded)
    }
}

private func zeroPad(_ value: Int, width: Int) -> String {
    var s = String(value)
    while s.count < width { s = "0" + s }
    return s
}

private extension String {
    func trimmingTrailingCharacters(_ character: Character) -> String {
        String(self[startIndex..<(lastIndex(where: { $0 != character }).map(index(after:)) ?? startIndex)])
    }
}

// "yyyy-MM-ddTHH:mm:ssZ"
private let iso8601FormatStyle = Date.ISO8601FormatStyle()

// "yyyy-MM-ddTHH:mm:ss" (no trailing Z, for manual fractional-second append)
private let iso8601WithoutZFormatStyle = Date.ISO8601FormatStyle().year().month().day().time(includingFractionalSeconds: false)

extension Double: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(formatYAMLFloat(self), Tag(.float))
    }
}

extension Float: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(formatYAMLFloat(self), Tag(.float))
    }
}

#if canImport(ObjectiveC)
extension NSNumber: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(formatYAMLFloat(self.doubleValue), Tag(.float))
    }
}
#endif

/// Format a floating-point value for YAML output using Swift's built-in Ryū algorithm
/// (shortest round-trip representation). Handles YAML special values (.inf, -.inf, .nan).
private func formatYAMLFloat<F: BinaryFloatingPoint & LosslessStringConvertible>(
    _ value: F
) -> String {
    if value.isNaN { return ".nan" }
    if value.isInfinite { 
        return switch(value.sign) {
            case .plus: ".inf"
            case .minus: "-.inf"
        }
    }
    return "\(value)"
}

// TODO: Support `Float80`
// extension Float80: ScalarRepresentable {}

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
        let scalar = Node.Scalar(self)
        return scalar.resolvedTag.name == .str ? scalar : .init(self, Tag(.str), .singleQuoted)
    }
}

#if canImport(ObjectiveC)
extension NSString: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
      let scalar = Node.Scalar(String(self))
        return scalar.resolvedTag.name == .str ? scalar : .init(String(self), Tag(.str), .singleQuoted)
    }
}
#endif

extension UUID: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        return .init(uuidString)
    }
}

// MARK: - ScalarRepresentableCustomizedForCodable

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
extension UUID: YAMLEncodable {}

extension Date: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node(iso8601StringWithFullNanosecond, Tag(.timestamp))
    }
}

extension Double: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node(formattedStringForCodable, Tag(.float))
    }
}

extension Float: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node(formattedStringForCodable, Tag(.float))
    }
}

private extension BinaryFloatingPoint where Self: LosslessStringConvertible {
    var formattedStringForCodable: String {
        formatYAMLFloat(self)
    }
}
