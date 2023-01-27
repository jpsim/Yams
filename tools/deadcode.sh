#!/usr/bin/env bash

set -euo pipefail

# build
bazel build //... \
  --features swift.index_while_building \
  --features swift.use_global_index_store \
  --output_groups=+swift_index_store

# Set up temporary index store directory
readonly index_store_path="$(mktemp -d)"
rm -rf "$index_store_path"
trap "rm -rf ${index_store_path}" EXIT

# remap index store
bazel run @index-import//:index-import -- \
  -remap "^/private/var/tmp/_bazel_.+?/.+?/execroot/[^/]+=$PWD" \
  "$PWD/bazel-out/_global_index_store" \
  "$index_store_path"

# analyze for dead code
# Build SwiftLint from https://github.com/realm/SwiftLint/compare/jp-deadcode-2
# with `bazel build --config release swiftlint`
SWIFTLINT="$HOME/src/SwiftLint/bazel-bin/swiftlint"
"$SWIFTLINT" dead-code \
  --index-store-path "$index_store_path"
