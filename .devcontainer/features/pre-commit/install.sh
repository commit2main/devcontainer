#!/usr/bin/env bash
set -euo pipefail

version="${VERSION:-latest}"
if [[ "$version" != latest && ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid pre-commit version: $version" >&2
    exit 1
fi

package=pre-commit
if [[ "$version" != latest ]]; then
    package="pre-commit==$version"
fi

export UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin
uv tool install --python "$(command -v python3)" --no-managed-python "$package"
/usr/local/bin/pre-commit --version
