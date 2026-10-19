#!/usr/bin/env bash
set -euo pipefail

version="${VERSION:-latest}"
if [[ "$version" != latest && ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "oh-my-pi version must be latest or an exact x.y.z release: $version" >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "oh-my-pi Feature requires Debian or Ubuntu (apt-get)." >&2
    exit 1
fi

machine="$(uname -m)"
case "$machine" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported architecture: $machine" >&2; exit 1 ;;
esac
target="linux-$arch"

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 || \
   ! command -v sha256sum >/dev/null 2>&1 || ! command -v install >/dev/null 2>&1 || \
   ! command -v mktemp >/dev/null 2>&1 || ! command -v chmod >/dev/null 2>&1 || \
   [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl jq coreutils
    rm -rf /var/lib/apt/lists/*
fi

if [[ "$version" == latest ]]; then
    endpoint="https://build.stencil.so/api/products/omp/latest/${target}?channel=stable"
else
    endpoint="https://build.stencil.so/api/products/omp/versions/${version}/${target}"
fi
metadata="$(curl -fsSL --retry 3 "$endpoint")"
resolved="$(jq -er '.build.version | select(type == "string")' <<< "$metadata")"
checksum="$(jq -er '.file.sha256 | select(type == "string")' <<< "$metadata")"
url="$(jq -er '.download | select(type == "string")' <<< "$metadata")"
platform="$(jq -er '.file.platform | select(type == "string")' <<< "$metadata")"
file_arch="$(jq -er '.file.arch | select(type == "string")' <<< "$metadata")"
if [[ ! "$resolved" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || \
      ! "$checksum" =~ ^[[:xdigit:]]{64}$ || \
      ! "$url" =~ ^https://[^[:space:]]+$ || \
      "$platform" != linux || "$file_arch" != "$arch" ]]; then
    echo "Unexpected oh-my-pi release metadata" >&2
    exit 1
fi
if [[ "$version" != latest && "$resolved" != "$version" ]]; then
    echo "oh-my-pi release metadata does not match requested version: $version" >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 "$url" -o "$tmp/omp"
if ! printf '%s  %s\n' "$checksum" "$tmp/omp" | sha256sum --check --status; then
    echo "oh-my-pi binary SHA-256 verification failed" >&2
    exit 1
fi

chmod 0755 "$tmp/omp"
reported="$("$tmp/omp" --version)"
if [[ "$reported" != "omp/$resolved" && "$reported" != "omp/$resolved "* ]]; then
    echo "oh-my-pi binary version does not match release metadata: $resolved" >&2
    exit 1
fi
install -m 0755 "$tmp/omp" /usr/local/bin/omp
installed="$(/usr/local/bin/omp --version)"
if [[ "$installed" != "omp/$resolved" && "$installed" != "omp/$resolved "* ]]; then
    echo "Installed oh-my-pi version does not match release metadata: $resolved" >&2
    exit 1
fi
echo "oh-my-pi $installed installed"
