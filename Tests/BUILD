load("@build_bazel_rules_apple//apple:macos.bzl", "macos_build_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_build_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_build_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_build_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

config_setting(
    name = "linux",
    constraint_values = ["@platforms//os:linux"],
)

genrule(
    name = "LinuxMain",
    srcs = ["LinuxMain.swift"],
    outs = ["main.swift"],
    cmd = "cp $< $@",
)

swift_test(
    name = "UnitTests",
    srcs = glob(["YamsTests/*.swift"]) + select({
        ":linux": ["main.swift"],
        "//conditions:default": [],
    }),
    data = glob(["YamsTests/Fixtures/**/*.*"]),
    module_name = "YamsTests",
    deps = [
        "//:Yams",
    ],
)

macos_build_test(
    name = "macOSBuildTest",
    minimum_os_version = "10.9",
    targets = [
        "//:Yams",
        "//:CYaml",
    ],
)

watchos_build_test(
    name = "watchOSBuildTest",
    minimum_os_version = "2.0",
    targets = [
        "//:Yams",
        "//:CYaml",
    ],
)

tvos_build_test(
    name = "tvOSBuildTest",
    minimum_os_version = "9.0",
    targets = [
        "//:Yams",
        "//:CYaml",
    ],
)

ios_build_test(
    name = "iOSBuildTest",
    minimum_os_version = "8.0",
    targets = [
        "//:Yams",
        "//:CYaml",
    ],
)
