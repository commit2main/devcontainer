#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Claude Code Feature requires Debian or Ubuntu (apt-get)." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 || \
   [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl jq
    rm -rf /var/lib/apt/lists/*
fi

base_url="https://downloads.claude.ai/claude-code-releases"
version="${VERSION:-latest}"
if [[ "$version" == latest || "$version" == stable ]]; then
    version="$(curl -fsSL --retry 3 "$base_url/$version")"
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Claude Code version must be x.y.z, latest, or stable: $version" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) target=linux-x64 ;;
    aarch64|arm64) target=linux-arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

manifest="$(curl -fsSL --retry 3 "$base_url/$version/manifest.json")"
expected="$(jq -er --arg target "$target" '.platforms[$target].checksum' <<< "$manifest")"
if [[ ! "$expected" =~ ^[a-f0-9]{64}$ ]]; then
    echo "Unexpected Claude Code checksum in release manifest" >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 "$base_url/$version/$target/claude" -o "$tmp/claude"
actual="$(sha256sum "$tmp/claude" | cut -d ' ' -f1)"
if [[ "$actual" != "$expected" ]]; then
    echo "Claude Code checksum verification failed" >&2
    exit 1
fi

install -m 0755 "$tmp/claude" /usr/local/bin/claude
installed="$(/usr/local/bin/claude --version)"
if [[ "$installed" != "$version (Claude Code)" ]]; then
    echo "Expected Claude Code $version, got: $installed" >&2
    exit 1
fi
echo "Claude Code $installed installed"
