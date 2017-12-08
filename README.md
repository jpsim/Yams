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

### `Codable`
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

### `[String: Any]`, `[Any]` or `Any`
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
let sequenceYAML = try Yams.dump(object: array)
sequenceYAML == """
- 1
- 2
- 3

"""
let loadedArray: [Int]? = try Yams.load(yaml: sequenceYAML) as? [Int]

// Any
let string = "string"
let scalarYAML = try Yams.dump(object: string)
scalarYAML == """
string

"""
let loadedString: String? = try Yams.load(yaml: scalarYAML) as? String
```

### `Yams.Node`
```swift
let map: Yams.Node = [
    "array": [
        1, 2, 3
    ]
]
let yaml = try Yams.serialize(node: map)
yaml == """
array:
- 1
- 2
- 3

"""
let node = try Yams.compose(yaml: yaml)
map == node
```

## License

Both Yams and libYAML are MIT licensed.
