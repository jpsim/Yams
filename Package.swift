import PackageDescription

let package = Package(
    name: "Yams",
    targets: [
        Target(name: "Yams", dependencies: ["CYaml"])
    ]
)
