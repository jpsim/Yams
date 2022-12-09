//
//  Representer.swift
//  Yams
//
//  Created by Norio Nomura on 1/8/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS)
import Darwin
private let cpow: (_: Double, _: Double) -> Double = Darwin.pow
#elseif os(Windows)
import ucrt
private let cpow: (_: Double, _: Double) -> Double = ucrt.pow
#else
import CoreFoundation
import Glibc
private let cpow: (_: Double, _: Double) -> Double = Glibc.pow
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

extension Dictionary: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
        return Node(pairs.sorted { $0.key < $1.key }, Tag(.map))
    }
}

private func represent(_ value: Any) throws -> Node {
    if let representable = value as? NodeRepresentable {
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

extension Double: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        if #available(macOS 13.0, *) {
            return .init(doubleFormatter.string(for: self).replacing("+-", with: "-"), Tag(.float))
        } else {
            fatalError("Unimplemented")
        }
    }
}

extension Float: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        if #available(macOS 13.0, *) {
            return .init(floatFormatter.string(for: self).replacing("+-", with: "-"), Tag(.float))
        } else {
            fatalError("Unimplemented")
        }
    }
}

private let doubleFormatter = YamsNumberFormatter()
private let floatFormatter = YamsNumberFormatter()

private struct YamsNumberFormatter {
    func string(for number: some FloatingPoint) -> String {
        "\(number)"
    }
}

// TODO: Support `Float80`
//extension Float80: ScalarRepresentable {}

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

extension String: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() -> Node.Scalar {
        let scalar = Node.Scalar(self)
        return scalar.resolvedTag.name == .str ? scalar : .init(self, Tag(.str), .singleQuoted)
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
extension String: YAMLEncodable {}

extension Double: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node("\(self)", Tag(.float))
    }
}

extension Float: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box() -> Node {
        return Node("\(self)", Tag(.float))
    }
}
