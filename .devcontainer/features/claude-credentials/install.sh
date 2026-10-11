#!/bin/sh
set -eu

# Only the empty mount point and the check script go into the image; the
# credentials themselves arrive at runtime through the volume.
mkdir -p /mnt/claude-credentials
install -m 0755 "$(dirname "$0")/claude-credentials-check" /usr/local/bin/claude-credentials-check
echo "Claude credentials mount point installed"
