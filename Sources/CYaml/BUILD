load(
    "@rules_cc//cc:defs.bzl",
    "objc_library"
)

objc_library(
    name = "CYaml",
    srcs = glob(["src/*"]),
    hdrs = glob(["include/*"]),
    copts = [
        "-iquote",
        "external/Yams/Sources/CYaml/include",
    ],
    visibility = [
      "//Sources/Yams:__pkg__",
      "//Tests:__subpackages__"
    ],
    module_map = "include/module.modulemap",
)
