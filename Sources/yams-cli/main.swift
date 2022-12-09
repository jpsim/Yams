import Yams

let yaml = """
a: 0
b: 1.2
c: [1, 2, 3]
d:
  - a
  - b
  - c
"""

dump(try Yams.load(yaml: yaml)!)

enum Instrument: String, Codable {
    case tenorSaxophone = "Tenor Saxophone"
    case trumpet = "Trumpet"
}

let bandYAML = """
members:
  - name: John Coltrane
    age: 27
  - name: Miles Davis
    age: 23
    instrument: Trumpet
"""

struct Person: Codable {
    let name: String
    let age: Int
    let instrument: Instrument?
}

struct Band: Codable {
    let members: [Person]
}

let band = try YAMLDecoder().decode(Band.self, from: bandYAML)
dump(band)

print("Back to yaml:")
print(try YAMLEncoder().encode(band))
