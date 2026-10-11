#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1 || ! command -v flock >/dev/null 2>&1 || \
   ! command -v setsid >/dev/null 2>&1; then
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "OpenCode Credentials Feature requires Debian or Ubuntu (apt-get)." >&2
        exit 1
    fi
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends jq util-linux
    rm -rf /var/lib/apt/lists/*
fi

# Only the empty mount point and the sync script go into the image; the
# credentials arrive at runtime through the volume.
mkdir -p /mnt/opencode-credentials
install -m 0755 "$(dirname "$0")/opencode-credentials-sync" /usr/local/bin/opencode-credentials-sync
echo "OpenCode credentials sync installed"
