#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1 || [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates
    rm -rf /var/lib/apt/lists/*
fi

version="${VERSION:-latest}"
if [[ "$version" == latest ]]; then
    version="$(curl -fsSL --retry 3 https://api.github.com/repos/astral-sh/ruff/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
fi
if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid Ruff release tag: $version" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

asset="ruff-${arch}-unknown-linux-gnu.tar.gz"
url="https://github.com/astral-sh/ruff/releases/download/${version}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL --retry 3 "$url" -o "$tmp/$asset"
curl -fsSL --retry 3 "${url}.sha256" -o "$tmp/$asset.sha256"
checksum="$(awk 'NR == 1 { print $1 }' "$tmp/$asset.sha256")"
if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "Invalid Ruff checksum" >&2
    exit 1
fi
printf '%s  %s\n' "$checksum" "$tmp/$asset" | sha256sum --check --status

member="$(tar -tzf "$tmp/$asset" | grep -E '(^|/)ruff$' || true)"
if [[ -z "$member" || "$member" == *$'\n'* ]]; then
    echo "Expected exactly one Ruff binary in $asset" >&2
    exit 1
fi
tar -xOf "$tmp/$asset" "$member" > "$tmp/ruff"
install -m 0755 "$tmp/ruff" /usr/local/bin/ruff

/usr/local/bin/ruff --version
