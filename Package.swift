// swift-tools-version:5.4
import PackageDescription

let dependencies: [Package.Dependency]
#if swift(>=5.6) && swift(<5.7) && os(macOS)
dependencies = [.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")]
#else
dependencies = []
#endif

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    dependencies: dependencies,
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
