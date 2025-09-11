## 6.0.2

##### Breaking

* None.

##### Enhancements

* `YAMLDecoder` can decode `DecodableWithConfiguration` objects.
  [Vitalii Budnik](https://github.com/nekrich)

##### Bug Fixes

* Fix bug where anchors were not properly set in decoded types in some circumstances.
  [Adora Lynch](https://github.com/lynchsft)

## 6.0.1

##### Breaking

* None.

##### Enhancements

* Add support for rules_swift 3.0.  
  [Luis Padron](https://github.com/luispadron)

##### Bug Fixes

* None.

## 6.0.0

##### Breaking

* YamlError.duplicatedKeysInMapping changed the types of its associated values
  to conform to Sendable.
  [Adora Lynch](https://github.com/lynchsft)

##### Enhancements

* Yams conforms to Swift 6 language mode with full concurrency checking
  [Adora Lynch](https://github.com/lynchsft)

##### Bug Fixes

* None.

## 5.3.1

##### Breaking

* None.

## 5.4.0

##### Breaking

* Abandon support for Swift 5.7 on Windows
  [Adora Lynch](https://github.com/lynchsft)
  
##### Enhancements

* Yams is able to coalesce references to objects decoded with YAML anchors.
  [Adora Lynch](https://github.com/lynchsft)
* Don't decode explicit strings as bools, regardless of content
  [Honza Dvorsky](https://github.com/czechboy0)
* Use `internal import` when possible
  [Matt Pennig](https://github.com/pennig)
* Validate swift 6.1 compatibility with CI jobs
  [Adora Lynch](https://github.com/lynchsft)

##### Bug Fixes

* Meta-keys used for Anchor and Tag parsing are not exposed to allKeys property
  [Adora Lynch](https://github.com/lynchsft)
  [#442](https://github.com/jpsim/Yams/issues/442)

## 5.3.1

##### Breaking

* None.

##### Enhancements

* Add Android Support
  [Marc Prud'hommeaux](https://github.com/marcprux)
  [#437](https://github.com/jpsim/Yams/pull/437)
  
##### Bug Fixes

* Resolves an issue where Yams would sometimes produce an invalid Anchor/alias
  pair when encoding single-value types.

## 5.3.0

##### Breaking

* None.

##### Enhancements

* Yams is able to encode and decode Anchors via YamlAnchorProviding, and
  YamlAnchorCoding. 
  [Adora Lynch](https://github.com/lynchsft)
  [#125](https://github.com/jpsim/Yams/issues/125)

* Yams is able to encode and decode Tags via YamlTagProviding
  and YamlTagCoding.
  [Adora Lynch](https://github.com/lynchsft) 
  [#265](https://github.com/jpsim/Yams/issues/265)
  
* Yams is able to detect redundant structs and automatically
  alias them during encoding via RedundancyAliasingStrategy
  [Adora Lynch](https://github.com/lynchsft)

##### Bug Fixes

* None.

## 5.2.0
  
##### Breaking

* Swift 5.7 or later is now required to build Yams.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Removes dependency on libc and the platform-specific pow function.  
  [Bradley Mackey](https://github.com/bradleymackey)
  [#429](https://github.com/jpsim/Yams/issues/429)
  
##### Bug Fixes

* Yams will now correctly error when it tries to decode a mapping with duplicate keys.  
  [Tejas Sharma](https://github.com/tejassharma96)
  [#415](https://github.com/jpsim/Yams/issues/415)

## 5.1.3

##### Breaking

* None.

##### Enhancements

* Add support for visionOS.  
  [ruralharry](http://github.com/ruralharry)

* Add support for Android.  
  [finagolfin](http://github.com/finagolfin)

* Add support for Bazel's `rules_swift` 2.x versions.  
  [Luis Padron](https://github.com/luispadron)

##### Bug Fixes

* Fix CI workflows.  
  [Tony Arnold](https://github.com/tonyarnold)

## 5.1.2

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix support for Bazel 7.x.  
  [JP Simard](https://github.com/jpsim)

## 5.1.1

##### Breaking

* None.

##### Enhancements

* Allow specifying a `newLineScalarStyle` for encoding string scalars with
  newlines when using `YAMLEncoder`.  
  [Tejas Sharma](https://github.com/tejassharma96)
  [#405](https://github.com/jpsim/Yams/issues/405)

* Improve support for Bazel 7.x.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* None.

## 5.1.0

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Change how empty strings are decoded into nullable properties.
  `key: ""` previously decoded into
  `struct Value: Codable { let key: String? }` as `Value(key: nil)`
  whereas after this change it decodes as `Value(key: "")`.
  This could be a breaking change if you were relying on the previous
  semantics.  
  [Liam Nichols](https://github.com/liamnichols)
  [#301](https://github.com/jpsim/Yams/issues/301)

* Fix parsing of unquoted URLs into Strings.  
  [Honza Dvorsky](https://github.com/czechboy0)
  [#337](https://github.com/jpsim/Yams/issues/337)

## 5.0.6

##### Breaking

* None.

##### Enhancements

* Allow decoding from an existing Node.  
  [Rob Napier](https://github.com/rnapier)

##### Bug Fixes

* Empty dictionaries can be now represented, regardless of its key or element
  type information.  
  [JP Simard](https://github.com/jpsim)
  [#393](https://github.com/jpsim/Yams/issues/393)

## 5.0.5

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix using Yams from bazel without bzlmod.  
  [Keith Smiley](https://github.com/keith)

## 5.0.4

##### Breaking

* None.

##### Enhancements

* Statically link `CYaml` when building with SwiftPM.  
  [Saleem Abdulrasool](https://github.com/compnerd)

##### Bug Fixes

* None.

## 5.0.3

##### Breaking

* None.

##### Enhancements

* Added support for bzlmod.  
  [Keith Smiley](https://github.com/keith)

##### Bug Fixes

* None.

## 5.0.1

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Build CYaml as PIC (Position Independent Code) when building with
  CMake.  
  [Yuta Saito](https://github.com/kateinoigakukun)

## 5.0.0

##### Breaking

* Swift 5.4 or later is now required to build Yams.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Adding `sequenceStyle` and `mappingStyle` to `Emitter.Options`
  [Terence Grant](https://github.com/tatewake)

##### Bug Fixes

* None.

## 4.0.6

##### Breaking

* None.

##### Enhancements

* Update Bazel config to allow targets to be directly consumed.  
  [Maxwell Elliott](https://github.com/maxwellE)

* Fix some Bazel integration issues
  [Keith Smiley](https://github.com/keith)

##### Bug Fixes

* Fix build error when integrating Yams using CocoaPods.  
  [JP Simard](https://github.com/jpsim)

## 4.0.5

##### Breaking

* None.

##### Enhancements

* Adds the ability to build Yams for Linux and MacOS via Bazel.  
  [Maxwell Elliott](https://github.com/maxwellE)

* Updated libYAML. See changes here:
  https://github.com/yaml/libyaml/compare/53f5b86...acd6f6f  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* None.  

## 4.0.4

##### Breaking

* None.

##### Enhancements

* Expose the underlying `Node`'s `Mark` on `Decoder`.  
  [Brentley Jones](https://github.com/brentleyjones)

##### Bug Fixes

* Fix mark for sequences and mappings.  
  [Brentley Jones](https://github.com/brentleyjones)

## 4.0.3

##### Breaking

* None.

##### Enhancements

* Update Xcode project from Swift 4.2 to 5.0.  
  [Brennan Stehling](https://github.com/brennanMKE)

* Enable `CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER`.  
  [Brennan Stehling](https://github.com/brennanMKE)

##### Bug Fixes

* None.

## 4.0.2

##### Breaking

* None.

##### Enhancements

* Add support for Apple Silicon in `SwiftSupport.cmake`.  
  [Max Desiatov](https://github.com/MaxDesiatov)

##### Bug Fixes

* None.

## 4.0.1

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* String scalars containing numbers are no longer decoded as numbers.  
  [Matt Polzin](https://github.com/mattpolzin)
  [#263](https://github.com/jpsim/Yams/issues/263)

* Fix compilation errors when compiling using Swift For TensorFlow or
  Windows.  
  [Saleem Abdulrasool](https://github.com/compnerd)

## 4.0.0

##### Breaking

* Swift 5.1 or later is now required to build Yams.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* `YAMLDecoder` now conforms to the `TopLevelDecoder` protocol when
  Apple's Combine framework is available.  
  [JP Simard](https://github.com/jpsim)
  [#261](https://github.com/jpsim/Yams/issues/261)

* Add `YAMLDecoder.decode(...)` overload tha takes a YAML string encoded
  as `Data` using UTF8 or UTF16.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Fix CMake installation issues.  
  [Saleem Abdulrasool](https://github.com/compnerd)

## 3.0.1

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix CMake support.  
  [JP Simard](https://github.com/jpsim)

## 3.0.0

##### Breaking

* Swift 4.1 or later is now required to build Yams.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* Accurately represent `Date`s with nanosecond components in Swift 4.x.  
  [Norio Nomura](https://github.com/norio-nomura)

* Change to apply single quoted style to YAML representation of `String`, if 
  that contents will be resolved to other than `.str` by default `Resolver`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#197](https://github.com/jpsim/Yams/issues/197)

* Support `UUID` scalars.  
  [Ondrej Rafaj](https://github.com/rafiki270)

* Get Yams building for Windows.  
  [Saleem Abdulrasool](https://github.com/compnerd)

* Add support for CMake based builds.  
  [Saleem Abdulrasool](https://github.com/compnerd)

* Merge anchors in `YAMLDecoder` by default.  
  [Brentley Jones](https://github.com/brentleyjones)
  [#238](https://github.com/jpsim/Yams/issues/238)

##### Bug Fixes

* Fix `Yams.dump` when object contains a keyed null value.  
  [JP Simard](https://github.com/jpsim)
  [#232](https://github.com/jpsim/Yams/issues/232)

* Fix a bug where `YAMLEncoder` would delay `Date`s by 1 second when encoding
  values with a `nanosecond` component greater than 999499997.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#192](https://github.com/jpsim/Yams/issues/192)

* Fix dangling pointer warning with Swift 5.2.  
  [JP Simard](https://github.com/jpsim)

## 2.0.0

##### Breaking

* Change `byteOffset` to `offset` in `YamlError.reader`.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* Add `encoding` option to `Parser` as `Parser.Encoding` type to specify
  which encoding to pass to libYAML. Along with that change, add `encoding`
  options to `load()`, `load_all()`, `compose()`, `compose_all()` and 
  `YAMLDecoder`. The default encoding will be determined at run time based on
  the String type's native encoding.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* None.

## 1.0.2

##### Breaking

* None.

##### Enhancements

* Update LibYAML sources to latest versions as of January 6 2018.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Fix some test failures with the latest Swift 5 snapshot on Apple platforms.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#143](https://github.com/jpsim/Yams/issues/143)

* Preserve nanoseconds in dates when using swift-corelibs-foundation with
  Swift 5.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#146](https://github.com/jpsim/Yams/pull/146)

* Fix null/~/NULL/Null were parsed as strings, not nil by `YAMLDecoder`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#157](https://github.com/jpsim/Yams/issues/157)

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
