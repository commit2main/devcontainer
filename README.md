# 10x Slackers Universal Dev Container Image

## Supported languages and tooling

- Python (3.13)
  - Ruff
- Node (LTS)
  - npm, yarn, pnpm
- C/C++ (Debian Trixie)
  - gcc, clang, llvm, cmake, cppcheck, valgrind, gdb
- Pre-Commit

## Usage

Create a `.devcontainer/devcontainer.json` file with the following contents:

```json
// For format details, see https://aka.ms/devcontainer.json. For config options, see the
// README at: https://github.com/devcontainers/templates/tree/main/src/debian
{
  "name": "project_title",
  // Or use a Dockerfile or Docker Compose file. More info: https://containers.dev/guide/dockerfile
  "image": "ghcr.io/commit2main/universal:latest"
  // Features to add to the dev container. More info: https://containers.dev/features.
  // "features": {}
  // Use 'forwardPorts' to make a list of ports inside the container available locally.
  // "forwardPorts": []
  // Configure tool-specific properties.
  // "customizations": {}
  // Uncomment to connect as root instead. More info: https://aka.ms/dev-containers-non-root.
  // "remoteUser": "root"
}
```
