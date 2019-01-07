// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    targets: [
        .target(name: "CYaml"),
        .target(name: "SwiftDtoa"),
        .target(name: "Yams", dependencies: ["CYaml", "SwiftDtoa"]),
        .testTarget(name: "YamsTests", dependencies: ["Yams"])
    ]
)
