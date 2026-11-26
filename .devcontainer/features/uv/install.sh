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
    version="$(curl -fsSLI --retry 3 -o /dev/null -w '%{url_effective}' https://github.com/astral-sh/uv/releases/latest)"
    version="${version##*/}"
fi
if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid uv release tag: $version" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

asset="uv-${arch}-unknown-linux-gnu.tar.gz"
url="https://github.com/astral-sh/uv/releases/download/${version}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL --retry 3 "$url" -o "$tmp/$asset"
curl -fsSL --retry 3 "${url}.sha256" -o "$tmp/$asset.sha256"
checksum="$(awk 'NR == 1 { print $1 }' "$tmp/$asset.sha256")"
if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "Invalid uv checksum" >&2
    exit 1
fi
printf '%s  %s\n' "$checksum" "$tmp/$asset" | sha256sum --check --status

for binary in uv uvx; do
    member="$(tar -tzf "$tmp/$asset" | grep -E "(^|/)${binary}$" || true)"
    if [[ -z "$member" || "$member" == *$'\n'* ]]; then
        echo "Expected exactly one $binary binary in $asset" >&2
        exit 1
    fi
    tar -xOf "$tmp/$asset" "$member" > "$tmp/$binary"
    install -m 0755 "$tmp/$binary" "/usr/local/bin/$binary"
done

/usr/local/bin/uv --version
