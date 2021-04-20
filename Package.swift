// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-server/swift-backtrace.git",
            .revision("182caea1a4162debed4771621cb3149e703fb052")
        ),
    ],
    targets: [
        .target(name: "CYaml", cSettings: [.define("YAML_DECLARE_EXPORT")]),
        .target(name: "Yams", dependencies: ["CYaml"]),
        .testTarget(name: "YamsTests", dependencies: ["Backtrace", "Yams"])
    ]
)
