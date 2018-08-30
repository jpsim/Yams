## 1.0.1

##### Breaking

* None.

##### Enhancements

* Improve support for compiling with Swift 4.2 or later.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* Fix issues with unset `DYLIB_COMPATIBILITY_VERSION` and
  `DYLIB_CURRENT_VERSION`. Now both values are set to `1`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#131](https://github.com/jpsim/Yams/issues/131)

## 1.0.0

##### Breaking

* Rename `ScalarRepresentableCustomizedForCodable` to `YAMLEncodable`.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* API documentation now available at [jpsim.com/Yams](https://jpsim.com/Yams).  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* None.

## 0.7.0

##### Breaking

* Drop support for building with `-swift-version 3`.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* None.

##### Bug Fixes

* Always parse quoted values as strings.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#116](https://github.com/jpsim/Yams/issues/116)

## 0.6.0

##### Breaking

* Some APIs have changed related to `ScalarConstructible`.
  * Change parameter type of `ScalarConstructible.construct(from:)` from `Node`
    to `Node.Scalar`
  * Change `Constructor`:
    * Split `Map` into `ScalarMap`, `MappingMap` and `SequenceMap`
    * Split `defaultMap` into `defaultScalarMap`, `defaultMappingMap` and
      `defaultSequenceMap`
    * Change `init(_:)` to `init(_:_:_:)`

  [Norio Nomura](https://github.com/norio-nomura)
  [#105](https://github.com/jpsim/Yams/issues/105)

##### Enhancements

* Improve test of "tag:yaml.org,2002:value".  
  [Norio Nomura](https://github.com/norio-nomura)
  [#97](https://github.com/jpsim/Yams/issues/97)

##### Bug Fixes

* `subscript(string:)` fails to lookup value if `Node` has non default `Resolver`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#100](https://github.com/jpsim/Yams/issues/100)

* Removed asserts in Constructor that were stopping the YAMLDecoder from returning correct errors.  
  [David Hart](https://github.com/hartbit)
  [#94](https://github.com/jpsim/Yams/pull/94)

## 0.5.0

##### Breaking

* Swift 3.2 or later is now required to build Yams.  
  [Norio Nomura](https://github.com/norio-nomura)
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* None.

##### Bug Fixes

* None.

## 0.4.1

## 0.4.0

## 0.3.7

## 0.3.6

## 0.3.5

## 0.3.4

## 0.3.3

## 0.3.2

## 0.3.1

## 0.3.0

## 0.2.0

## 0.1.5

## 0.1.4

## 0.1.3

## 0.1.2

## 0.1.1

## 0.1.0
