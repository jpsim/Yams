// swift-tools-version:4.2
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
    ],
    swiftLanguageVersions: [.v4, .v4_2]
)
