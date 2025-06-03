// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Yams",
    platforms: [.iOS(.v13), .macOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CYaml",
            exclude: ["CMakeLists.txt"],
            cSettings: [.define("YAML_DECLARE_STATIC")]
        ),
        .target(
            name: "Yams",
            dependencies: ["CYaml"],
            exclude: ["CMakeLists.txt"],
            cSettings: [.define("YAML_DECLARE_STATIC")]
        ),
        .testTarget(
            name: "YamsTests",
            dependencies: ["Yams"],
            exclude: ["CMakeLists.txt"],
            resources: [
                .copy("Fixtures/SourceKitten#289/debug.yaml"),
            ]
        )
    ]
)
