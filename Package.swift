// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"]),
        .library(name: "CYaml", targets: ["CYaml"])
    ],
    targets: [
        .target(name: "CYaml"),
        .target(name: "Yams", dependencies: ["CYaml"]),
        .testTarget(name: "YamsTests", dependencies: ["Yams"])
    ]
)
