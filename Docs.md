# Yams Documentation

For installation instructions, see [README.md](README.md).

API documentation available at [jpsim.com/Yams](https://jpsim.com/Yams).

## Usage

### Consume YAML

Here's a simple example parsing a YAML array of strings:

```swift
import Yams

let yamlString = """
  - a
  - b
  - c
  """
do {
  let yamlNode = try Yams.load(yaml: yamlString)
  if let yamlArray = yamlNode as? [String] {
    print(yamlArray)
  }
} catch {
  print("handle error: \(error)")
}

// Prints:
// ["a", "b", "c"]
```

### Emit YAML

Here's a simple example emitting YAML string from a Swift `Array<String>`:

```swift
import Yams

do {
  let yamlString = try Yams.serialize(node: ["a", "b", "c"])
  print(yamlString)
} catch {
  print("handle error: \(error)")
}

// Prints:
// - a
// - b
// - c
```

You can even customize the style:

```swift
import Yams

var node: Node = ["a", "b", "c"]
node.sequence?.style = .flow

do {
  let yamlString = try Yams.serialize(node: node)
  print(yamlString)
} catch {
  print("handle error: \(error)")
}

// Prints:
// [a, b, c]
```

### Customize Parsing

For example, say you only want the literals `true` and `false` to represent booleans, unlike the
YAML spec compliant boolean which also includes `on`/`off` and many others.

You can customize Yams' Constructor map:

```swift
import Yams

extension Constructor {
  public static func withBoolAsTrueFalse() -> Constructor {
    var map = defaultMap
    map[.bool] = Bool.constructUsingOnlyTrueAndFalse
    return Constructor(map)
  }
}

private extension Bool {
  static func constructUsingOnlyTrueAndFalse(from node: Node) -> Bool? {
    assert(node.isScalar)
    switch node.scalar!.string.lowercased() {
    case "true":
      return true
    case "false":
      return false
    default:
      return nil
    }
  }
}

private extension Node {
  var isScalar: Bool {
    if case .scalar = self {
      return true
    }
    return false
  }
}

// Usage:

let yamlString = """
  - true
  - on
  - off
  - false
  """
if let array = try? Yams.load(yaml: yamlString, .default, .withBoolAsTrueFalse()) as? [Any] {
  print(array)
}

// Prints:
// [true, "on", "off", false]
```

### Expanding Environment Variables

For example:

```swift
import Yams

extension Constructor {
  public static func withEnv(_ env: [String: String]) -> Constructor {
    var map = defaultMap
    map[.str] = String.constructExpandingEnvVars(env: env)
    return Constructor(map)
  }
}

private extension String {
  static func constructExpandingEnvVars(env: [String: String]) -> (_ node: Node) -> String? {
    return { (node: Node) -> String? in
      assert(node.isScalar)
      return node.scalar!.string.expandingEnvVars(env: env)
    }
  }

  func expandingEnvVars(env: [String: String]) -> String {
    var result = self
    for (key, value) in env {
      result = result.replacingOccurrences(of: "${\(key)}", with: value)
    }

    return result
  }
}

// Usage:

let yamlString = """
  - first
  - ${SECOND}
  - SECOND
  """
let env = ["SECOND": "2"]
if let array = try? Yams.load(yaml: yamlString, .default, .withEnv(env)) as? [String] {
  print(array)
}

// Prints:
// ["first", "2", "SECOND"]
```

### Converting Between Formats

Because Yams conforms to Swift 4's Codable protocol and provides a YAML Encoder and Decoder,
you can easily convert between YAML and other formats that also provide Swift 4 Encoders and
Decoders, such as JSON and Plist.

### Error Handling

Failable operations in Yams throw Swift errors.

### Types

| Name           | Yams Tag      | YAML Tag                      | Swift Types                    |
|----------------|---------------|-------------------------------|--------------------------------|
| ...            | `implicit`    | ``                            | ...                            |
| ...            | `nonSpecific` | `!`                           | ...                            |
| String         | `str`         | `tag:yaml.org,2002:str`       | `String`                       |
| Sequence       | `seq`         | `tag:yaml.org,2002:seq`       | `Array<Any>`                   |
| Map            | `map`         | `tag:yaml.org,2002:map`       | `Dictionary<AnyHashable, Any>` |
| Boolean        | `bool`        | `tag:yaml.org,2002:bool`      | `Bool`                         |
| Floating Point | `float`       | `tag:yaml.org,2002:float`     | ...                            |
| Null           | `null`        | `tag:yaml.org,2002:null`      | `Void`                         |
| Integer        | `int`         | `tag:yaml.org,2002:int`       | `FixedWidthInteger`            |
| ...            | `binary`      | `tag:yaml.org,2002:binary`    | `Data`                         |
| ...            | `merge`       | `tag:yaml.org,2002:merge`     | ...                            |
| ...            | `omap`        | `tag:yaml.org,2002:omap`      | ...                            |
| ...            | `pairs`       | `tag:yaml.org,2002:pairs`     | ...                            |
| Set            | `set`         | `tag:yaml.org,2002:set`       | `Set<AnyHashable>`             |
| Timestamp      | `timestamp`   | `tag:yaml.org,2002:timestamp` | `Date`                         |
| ...            | `value`       | `tag:yaml.org,2002:value`     | ...                            |
| YAML           | `yaml`        | `tag:yaml.org,2002:yaml`      | Unsupported                    |
