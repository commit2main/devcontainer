#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1 || [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates
    rm -rf /var/lib/apt/lists/*
fi

version="${VERSION:-latest}"
if [[ "$version" == latest ]]; then
    # The latest-release URL redirects to .../tag/<version>; this avoids the rate-limited GitHub API.
    version="$(curl -fsSLI --retry 3 -o /dev/null -w '%{url_effective}' https://github.com/casey/just/releases/latest)"
    version="${version##*/}"
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid just release tag: $version" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

asset="just-${version}-${arch}-unknown-linux-musl.tar.gz"
base="https://github.com/casey/just/releases/download/${version}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL --retry 3 "$base/$asset" -o "$tmp/$asset"
curl -fsSL --retry 3 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"
checksum="$(awk -v a="$asset" '$2 == a || $2 == "*" a { print $1 }' "$tmp/SHA256SUMS")"
if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "No checksum for $asset in SHA256SUMS" >&2
    exit 1
fi
printf '%s  %s\n' "$checksum" "$tmp/$asset" | sha256sum --check --status

tar -xzf "$tmp/$asset" -C "$tmp" just
install -m 0755 "$tmp/just" /usr/local/bin/just
mkdir -p /usr/share/bash-completion/completions
/usr/local/bin/just --completions bash > /usr/share/bash-completion/completions/just

/usr/local/bin/just --version
