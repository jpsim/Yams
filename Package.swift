// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    targets: [
        .target(name: "CYaml", cSettings: [.define("YAML_DECLARE_EXPORT")]),
        .target(name: "Yams", dependencies: ["CYaml"]),
        .testTarget(name: "YamsTests", dependencies: ["Yams"])
    ]
)
