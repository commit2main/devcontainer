#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "OpenCode Feature requires Debian or Ubuntu (apt-get)." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 || \
   ! command -v tar >/dev/null 2>&1 || [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl jq tar
    rm -rf /var/lib/apt/lists/*
fi

version="${VERSION:-latest}"
if [[ "$version" == latest ]]; then
    version="$(curl -fsSL --retry 3 https://opencode.ai/update/api/latest/cli/npm | jq -er '.version')"
fi
if [[ ! "$version" =~ ^2\.[0-9]+\.[0-9]+$ ]]; then
    echo "OpenCode version must be a V2 release (2.x.y): $version" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) target=linux-x64-baseline ;;
    aarch64|arm64) target=linux-arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

package="cli-$target"
metadata="$(curl -fsSL --retry 3 "https://registry.npmjs.org/@opencode%2f${package}/${version}")"
url="$(jq -er '.dist.tarball' <<< "$metadata")"
integrity="$(jq -er '.dist.integrity' <<< "$metadata")"
if [[ "$url" != "https://registry.npmjs.org/@opencode/${package}/-/${package}-${version}.tgz" || \
      "$integrity" != sha512-* ]]; then
    echo "Unexpected OpenCode package metadata" >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 "$url" -o "$tmp/opencode.tgz"

expected="$(printf '%s' "${integrity#sha512-}" | base64 -d | od -An -tx1 | tr -d ' \n')"
actual="$(sha512sum "$tmp/opencode.tgz" | cut -d ' ' -f1)"
if [[ ! "$expected" =~ ^[[:xdigit:]]{128}$ || "$actual" != "$expected" ]]; then
    echo "OpenCode package integrity check failed" >&2
    exit 1
fi

tar -xOf "$tmp/opencode.tgz" package/bin/opencode > "$tmp/opencode"
install -m 0755 "$tmp/opencode" /usr/local/bin/opencode

installed="$(/usr/local/bin/opencode --version)"
if [[ ! "$installed" =~ (^|[[:space:]])v?2\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected OpenCode V2, got: $installed" >&2
    exit 1
fi
echo "OpenCode $installed installed"
