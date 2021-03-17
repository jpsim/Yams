load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

swift_test(
    name = "YamsTests",
    module_name = "YamsTests",
    srcs = glob(["*.swift"]),
    data = glob(["Fixtures/**/*.*"]),
    deps = [
        "//Sources/Yams:Yams",
    ]
)
