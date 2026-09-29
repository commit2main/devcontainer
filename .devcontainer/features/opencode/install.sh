#!/usr/bin/env bash
set -euo pipefail

version="${VERSION:-latest}"
if [[ "$version" == latest ]]; then
    version=2
elif [[ ! "$version" =~ ^2\.[0-9]+\.[0-9]+$ ]]; then
    echo "OpenCode version must be a V2 release (2.x.y): $version" >&2
    exit 1
fi

npm install --global --no-audit --no-fund "@opencode/cli@$version"
installed="$(opencode --version)"
if [[ ! "$installed" =~ (^|[[:space:]])v?2\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected OpenCode V2, got: $installed" >&2
    exit 1
fi
echo "OpenCode $installed installed"
