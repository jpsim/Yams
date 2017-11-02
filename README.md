# Yams

![Yams](yams.jpg)

A sweet and swifty [Yaml](http://yaml.org/) parser built on
[libYAML](http://pyyaml.org/wiki/LibYAML).

![Test Status](https://travis-ci.org/jpsim/Yams.svg?branch=master)

## Installation

Building Yams on macOS requires Xcode 9.x or a Swift 3.2/4.x toolchain with
the Swift Package Manager.

Building Yams on Linux requires a Swift 4.x compiler and Swift Package Manager
to be installed.

### Swift Package Manager

Add `.package(url: "https://github.com/jpsim/Yams.git", from: "0.4.1")` to your
`Package.swift` file's `dependencies`.

### CocoaPods

Add `pod 'Yams'` to your `Podfile`.

### Carthage

Add `github "jpsim/Yams"` to your `Cartfile`.

## License

Both Yams and libYAML are MIT licensed.
