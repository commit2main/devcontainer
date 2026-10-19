#!/bin/sh
set -eu

# Only the empty mount point and checker go into the image; credentials and
# agent state arrive at runtime through the volume.
mkdir -p /mnt/omp-agent
install -m 0755 "$(dirname "$0")/omp-credentials-check" /usr/local/bin/omp-credentials-check
echo "oh-my-pi credentials and state mount point installed"
