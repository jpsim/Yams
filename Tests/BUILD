load("@build_bazel_rules_apple//apple:macos.bzl", "macos_build_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_build_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_build_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_build_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

config_setting(
    name = "linux",
    values = {"define": "platform=linux"},
)

swift_test(
    name = "YamsTests",
    module_name = "YamsTests",
    srcs = select({
        ":linux": glob(["YamsTests/*.swift", "*.swift"]),
        "//conditions:default": glob(["YamsTests/*.swift"]),
    }),
    data = glob(["YamsTests/Fixtures/**/*.*"]),
    deps = [
        "//Sources/Yams:Yams",
    ],
)

macos_build_test(
    name = "macOSBuildTest",
    minimum_os_version = "10.9",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ],
)

watchos_build_test(
    name = "watchOSBuildTest",
    minimum_os_version = "2.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ],
)

tvos_build_test(
    name = "tvOSBuildTest",
    minimum_os_version = "9.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ],
)

ios_build_test(
    name = "iOSBuildTest",
    minimum_os_version = "8.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ],
)
