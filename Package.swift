// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Yams",
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
