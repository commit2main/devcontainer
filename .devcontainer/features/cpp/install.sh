#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    build-essential cmake cppcheck valgrind clang clang-format lldb llvm gdb meson ninja-build
rm -rf /var/lib/apt/lists/*
