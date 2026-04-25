# Universal Dev Container Image

Customized dev container with language runtimes and tooling pre-installed.

## Supported languages and tooling

- Base image: `mcr.microsoft.com/devcontainers/base:trixie`
- Python (latest)
  - Ruff, uv
- Node.js (LTS)
  - npm, yarn, pnpm
- C/C++ (Debian Trixie)
  - build-essential, cmake, cppcheck, valgrind, clang, clang-format, lldb, llvm, gdb, meson, ninja-build
- Go (latest)
- Rust (latest)
- Java (Temurin JDK 21)
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
