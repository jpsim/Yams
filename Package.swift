// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    targets: [
        .target(
            name: "CYaml",
            exclude: ["CMakeLists.txt"],
            cSettings: [.define("YAML_DECLARE_EXPORT")]
        ),
        .target(
            name: "Yams",
            dependencies: ["CYaml"],
            exclude: ["CMakeLists.txt"]
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
