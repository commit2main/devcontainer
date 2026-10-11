#!/usr/bin/env bash
# One-time host setup: creates the shared store and its bind-backed volume, and
# a systemd user service that keeps the host's OpenCode in sync with the store.
#
#   host-setup.sh [docker|podman]
set -euo pipefail

engine="${1:-docker}"
volume=opencode-credentials
store="${XDG_DATA_HOME:-$HOME/.local/share}/opencode-credentials"
bin="$HOME/.local/bin"
unit="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/opencode-credentials-sync.service"

for tool in "$engine" opencode jq flock systemctl; do
    command -v "$tool" >/dev/null 2>&1 || { echo "$tool is required on the host." >&2; exit 1; }
done

mkdir -p "$store"
chmod 700 "$store"
store="$(realpath "$store")"

if "$engine" volume inspect "$volume" >/dev/null 2>&1; then
    device="$("$engine" volume inspect -f '{{ index .Options "device" }}' "$volume")"
    if [[ "$device" != "$store" ]]; then
        echo "Volume $volume exists but is not bound to $store." >&2
        echo "Remove it with '$engine volume rm $volume' and run this script again." >&2
        exit 1
    fi
else
    "$engine" volume create --driver local --opt type=none --opt o=bind \
        --opt device="$store" "$volume" >/dev/null
fi

install -D -m 0755 "$(dirname "$0")/opencode-credentials-sync" "$bin/opencode-credentials-sync"
mkdir -p "$(dirname "$unit")"
cat >"$unit" <<UNIT
[Unit]
Description=Sync OpenCode credentials with the dev container store

[Service]
Environment=OPENCODE_CREDENTIALS_DIR=$store
Environment=PATH=$(dirname "$(command -v opencode)"):/usr/local/bin:/usr/bin
ExecStart=$bin/opencode-credentials-sync --watch
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
UNIT
systemctl --user daemon-reload
systemctl --user enable --now opencode-credentials-sync.service
echo "OpenCode credentials are shared through $store (volume $volume)."
