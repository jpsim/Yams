# Yams

![Yams](yams.jpg)

A sweet and swifty [Yaml](http://yaml.org/) parser built on
[libYAML](http://pyyaml.org/wiki/LibYAML).

![Test Status](https://travis-ci.org/jpsim/Yams.svg?branch=master)

## Installation

Building Yams on macOS requires Xcode 8.x/9.x or a Swift 3.x/4.x toolchain with
the Swift Package Manager.

Building Yams on Linux requires a Swift 3.x/4.x compiler and Swift Package
Manager to be installed.

### Swift Package Manager

Add `.Package(url: "https://github.com/jpsim/Yams.git", majorVersion: 0)` to
your `Package.swift` file's `dependencies`.

### CocoaPods

Add `pod 'Yams'` to your `Podfile`.

### Carthage

Add `github "jpsim/Yams"` to your `Cartfile`.

## License

Both Yams and libYAML are MIT licensed.
