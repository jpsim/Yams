load(
    "@rules_cc//cc:defs.bzl",
    "cc_library"
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library"
)

cc_library(
    name = "CYaml",
    srcs = glob(["Sources/CYaml/src/*.c", "Sources/CYaml/src/*.h"]),
    hdrs = ["Sources/CYaml/include/yaml.h"],
    includes = ["Sources/CYaml/include"],
    visibility = [
        "//Tests:__subpackages__",
    ],
)

swift_library(
    name = "Yams",
    module_name = "Yams",
    srcs = glob(["Sources/Yams/*.swift"]),
    copts = [
        "-DSWIFT_PACKAGE",
    ],
    visibility = [
        "//visibility:public"
    ],
    deps = ["//:CYaml"],
)
