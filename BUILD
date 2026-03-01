load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_swift//swift:swift_interop_hint.bzl", "swift_interop_hint")
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "CYaml",
    srcs = glob([
        "Sources/CYaml/src/*.c",
        "Sources/CYaml/src/*.h",
    ]),
    hdrs = ["Sources/CYaml/include/yaml.h"],
    aspect_hints = [":CYaml_swift_interop_hint"],
    copts = [
        # Required because of https://github.com/bazelbuild/bazel/pull/10143 otherwise host transition builds fail.
        "-fPIC",
        "-DYAML_DECLARE_STATIC",
    ],
    includes = ["Sources/CYaml/include"],
    linkstatic = True,
    tags = ["swift_module"],
    visibility = ["//Tests:__subpackages__"],
)

swift_interop_hint(
    name = "CYaml_swift_interop_hint",
    module_name = "CYaml",
)

swift_library(
    name = "Yams",
    srcs = glob(["Sources/Yams/*.swift"]),
    copts = ["-DSWIFT_PACKAGE"],
    module_name = "Yams",
    visibility = ["//visibility:public"],
    deps = ["//:CYaml"],
)
