"""Definitions for handling Bazel repositories for Yams. """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.
    Args:
      repo_rule: The repository rule to be executed (e.g., `http_archive`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def yams_rules_dependencies():
    """Fetches repositories that are dependencies of Yams.
    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies are downloaded and that they are isolated
    from changes to those dependencies.
    """
    _maybe(
        http_archive,
        name = "rules_cc",
        # Latest 08-10-20
        urls = ["https://github.com/bazelbuild/rules_cc/archive/1477dbab59b401daa94acedbeaefe79bf9112167.tar.gz"],
        sha256 = "b87996d308549fc3933f57a786004ef65b44b83fd63f1b0303a4bbc3fd26bbaf",
        strip_prefix = "rules_cc-1477dbab59b401daa94acedbeaefe79bf9112167/",
    )

    _maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        sha256 = "e3542e52585c2fde910da845dfcc017d99deafaae57f2125e8a18d04750ac41b",
        url = "https://github.com/bazelbuild/rules_apple/archive/9d064b9e8ec9bc920e6f561529611d1d4c6c1c68.zip",
        strip_prefix = "rules_apple-9d064b9e8ec9bc920e6f561529611d1d4c6c1c68"
    )

    _maybe(
        http_archive,
        name = "build_bazel_rules_swift",
        sha256 = "af5de6233958438f87cfe899e6a084b967812feb920c3c11a608d6b434c97364",
        url = "https://github.com/bazelbuild/rules_swift/archive/22a2472c0272a5f57e895ffcdec0617317253d64.zip",
        strip_prefix = "rules_swift-22a2472c0272a5f57e895ffcdec0617317253d64"
    )
