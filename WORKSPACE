load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "a5f00fd89eff67291f6cd3efdc8fad30f4727e6ebb90718f3f05bbf3c3dd5ed7",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/0.33.0/rules_apple.0.33.0.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

local_repository(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    path = "../rules_xcodeproj",
)

# http_archive(
#     name = "com_github_buildbuddy_io_rules_xcodeproj",
#     sha256 = "3a45e9e20bfb36c306ccc51407b97ff7d320c597d3c1c533cbdee9e66cff5cda",
#     url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.2.0/release.tar.gz",
# )

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()
