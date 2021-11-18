// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.3.1"),
    ],
    targets: [
        .target(name: "CYaml", cSettings: [.define("YAML_DECLARE_EXPORT")]),
        .target(name: "Yams", dependencies: ["CYaml"]),
        .target(name: "yams-fuzzer", dependencies: ["Backtrace", "Yams"]),
        .testTarget(name: "YamsTests", dependencies: ["Yams"])
    ]
)
