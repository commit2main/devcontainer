# Universal Dev Container Image

Customized dev container with language runtimes and tooling pre-installed.

## Supported languages and tooling

- Base image: `mcr.microsoft.com/devcontainers/base:trixie`
- Python 3.14
  - pip, pipx, [uv](.devcontainer/features/uv/), [Ruff](.devcontainer/features/ruff/)
- Node.js (LTS)
  - npm, yarn, pnpm, nvm
- C/C++ (Debian Trixie)
  - [C/C++ tools](.devcontainer/features/cpp/): build-essential, cmake, cppcheck, valgrind, clang, clang-format, lldb, llvm, gdb, meson, ninja-build
- Go (latest)
  - gopls, staticcheck, golint, revive, Delve (dlv), golangci-lint, gomodifytags, goplay, gotests, impl
- Rust (latest)
  - Cargo, rustup, rust-analyzer, rust-src, rustfmt, Clippy
- Java (Temurin JDK 21)
  - SDKMAN! (Maven and Gradle are not enabled)
- Developer tooling
  - GitHub CLI, [pre-commit](.devcontainer/features/pre-commit/), [OpenCode V2](.devcontainer/features/opencode/), [Claude Code](.devcontainer/features/claude-code/)
  - Updates: [build workflow](.github/workflows/build.yml), [OpenCode publishing](.github/workflows/publish-opencode.yml), [Claude Code publishing](.github/workflows/publish-claude-code.yml), [Dependabot](.github/dependabot.yml)

## Usage

To install only Claude Code in an existing dev container, add this feature:

```json
{
  "features": {
    "ghcr.io/commit2main/devcontainer/claude-code:1": {
      "version": "latest"
    }
  }
}
```

The version can also be `stable` or a specific release (`x.y.z`). The feature
supports Debian/Ubuntu on x86_64 and ARM64, verifies the native binary's SHA-256
checksum, and installs `claude` system-wide without requiring Node.js. Authenticate
with Claude Code after starting your container; credentials are not baked into the image.

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
