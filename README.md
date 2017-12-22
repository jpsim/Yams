# Yams

![Yams](yams.jpg)

A sweet and swifty [Yaml](http://yaml.org/) parser built on
[libYAML](http://pyyaml.org/wiki/LibYAML).

[![CircleCI](https://circleci.com/gh/jpsim/Yams.svg?style=svg)](https://circleci.com/gh/jpsim/Yams)

## Installation

Building Yams on macOS requires Xcode 9.x or a Swift 3.2/4.x toolchain with
the Swift Package Manager.

Building Yams on Linux requires a Swift 4.x compiler and Swift Package Manager
to be installed.

### Swift Package Manager

Add `.package(url: "https://github.com/jpsim/Yams.git", from: "0.5.0")` to your
`Package.swift` file's `dependencies`.

### CocoaPods

Add `pod 'Yams'` to your `Podfile`.

### Carthage

Add `github "jpsim/Yams"` to your `Cartfile`.

## Usage

Each of input / output YAML APIs can be classified into three, depending on the model types to be handled.

### Model types:
- `Codable` types
  - Serialization method introduced in Swift 4. It will be easy to have compatibility with serialization other than YAML.
  - The amount of computation will be kept equivalent to `Yams.Node`.
- Swift Standard Library types
  - The type of Swift Standard Library is inferred from the contents of `Yams.Node` by matching regular expression.
  - The type inference of all objects is done at YAML input time, so the amount of calculation is the largest.
  - It may be easier to use in such a way as to handle objects created from `JSONSerialization`.
- `Yams.Node`  
  - Yams' native model representing [Nodes of YAML](http://www.yaml.org/spec/1.2/spec.html#id2764044) which provides all functions such as detection and customization of YAML format.
  - Depending on how it is used, the amount of computation can be minimized.

### Examples by Model Types
#### `Codable` types
- `YAMLEncoder.encode(_:)` Produces a YAML `String` from an instance of type conforming `Encodable`.
- `YAMLDecoder.decode(_:from:)`: Decodes an instance of type conforming `Decodable` from YAML.
```swift
import Foundation
import Yams

struct S: Codable {
    var p: String
}

let s: S = S(p: "test")
let encodedYAML: String = try YAMLEncoder().encode(s)
encodedYAML == """
p: test

"""
let decoded: S = try YAMLDecoder().decode(S.self, from: encodedYAML)
```

#### Swift Standard Library types
- `Yams.load(yaml:)`: Produces an instance of Swift Standard Library types as `Any` from YAML `String`. Since Yams infer the type of each object by matching the regular expression to the contents of all instances, it is the slowest method on reading YAML.
- `Yams.dump(object:)`: Produces a YAML `String` from an instance of Swift Standard Library types.
```swift
// [String: Any]
let dictionary: [String: Any] = ["key": "value"]
let mapYAML: String = try Yams.dump(object: dictionary)
mapYAML == """
key: value

"""
let loadedDictionary: [String: Any]? = try Yams.load(yaml: mapYAML) as? [String: Any]

// [Any]
let array: [Int] = [1, 2, 3]
let sequenceYAML: String = try Yams.dump(object: array)
sequenceYAML == """
- 1
- 2
- 3

"""
let loadedArray: [Int]? = try Yams.load(yaml: sequenceYAML) as? [Int]

// Any
let string = "string"
let scalarYAML: String = try Yams.dump(object: string)
scalarYAML == """
string

"""
let loadedString: String? = try Yams.load(yaml: scalarYAML) as? String
```

#### `Yams.Node`
- `Yams.compose(yaml:)`: Produces an instance of `Node` from YAML `String`.
- `Yams.serialize(node:)`: Produces a YAML `String` from an instance of `Node`.
```swift
var map: Yams.Node = [
    "array": [
        1, 2, 3
    ]
]
map.mapping?.style = .flow
map["array"]?.sequence?.style = .flow
let yaml = try Yams.serialize(node: map)
yaml == """
{array: [1, 2, 3]}

"""
let node = try Yams.compose(yaml: yaml)
map == node
```

## License

Both Yams and libYAML are MIT licensed.
