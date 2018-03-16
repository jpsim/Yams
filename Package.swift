// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
      .library(name: "Yams", targets: ["Yams"])
    ],
    targets: [
        .target(name: "CYaml"),
        .target(name: "Yams", dependencies: ["CYaml"]),
        .testTarget(name: "YamsTests", dependencies: ["Yams"])
    ]
)
