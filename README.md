# Universal Dev Container Image

Customized dev container with language runtimes and tooling pre-installed.

## Supported languages and tooling

- Base image: `mcr.microsoft.com/devcontainers/base:trixie`
- Python 3.14
  - pip, pipx, uv, Ruff
- Node.js (LTS)
  - npm, yarn, pnpm, nvm
- C/C++ (Debian Trixie)
  - build-essential, cmake, cppcheck, valgrind, clang, clang-format, lldb, llvm, gdb, meson, ninja-build
- Go (latest)
  - gopls, staticcheck, golint, revive, Delve (dlv), golangci-lint, gomodifytags, goplay, gotests, impl
- Rust (latest)
  - Cargo, rustup, rust-analyzer, rust-src, rustfmt, Clippy
- Java (Temurin JDK 21)
  - SDKMAN! (Maven and Gradle are not enabled)
- Developer tooling
  - GitHub CLI, pre-commit

## Usage

Create a `.devcontainer/devcontainer.json` file with the following contents:

```json
{
  "name": "project_title",
  "image": "ghcr.io/commit2main/universal:latest"
  // "features": {}
  // "forwardPorts": []
  // "customizations": {}
  // "remoteUser": "root"
}
```
