load("@build_bazel_rules_apple//apple:macos.bzl", "macos_build_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_build_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_build_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_build_test")

macos_build_test(
    name = "MacOSBuildTest",
    minimum_os_version = "10.9",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ]
)

watchos_build_test(
    name = "WatchOSBuildTest",
    minimum_os_version = "2.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ]
)

tvos_build_test(
    name = "tvOSBuildTest",
    minimum_os_version = "9.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ]
)

ios_build_test(
    name = "iOSBuildTest",
    minimum_os_version = "8.0",
    targets = [
        "//Sources/Yams:Yams",
        "//Sources/CYaml:CYaml",
    ]
)

