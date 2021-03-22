load(
    "@rules_cc//cc:defs.bzl",
    "cc_library"
)

cc_library(
    name = "CYaml",
    srcs = glob(["src/*.c", "src/*.h"]),
    hdrs = ["include/yaml.h"],
    includes = ["include"],
    visibility = [
        "//Sources/Yams:__pkg__",
        "//Tests:__subpackages__",
    ],
)
