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
  - Updates: [build workflow](.github/workflows/build.yml), [OpenCode publishing](.github/workflows/publish-opencode.yml), [Claude Code publishing](.github/workflows/publish-claude-code.yml), [Claude Credentials publishing](.github/workflows/publish-claude-credentials.yml), [Dependabot](.github/dependabot.yml)

## Usage

To install only Claude Code/OpenCode in an existing dev container, add this feature:

```json
{
  "features": {
    "ghcr.io/commit2main/devcontainer/claude-code:1": {
      "version": "latest"
    },
    "ghcr.io/commit2main/devcontainer/opencode:1": {
      "version": "latest"
    }
  }
}
```

The version can also be `stable` or a specific release (`x.y.z`). The feature
supports Debian/Ubuntu on x86_64 and ARM64, verifies the native binary's SHA-256
checksum, and installs `claude` system-wide without requiring Node.js. Authenticate
with Claude Code after starting your container; credentials are not baked into the image.

### Sharing host Claude credentials

The [`claude-credentials`](.devcontainer/features/claude-credentials/) feature
mounts the host's Claude Code config directory into every dev container, so you
log in once on the host. It is not part of the universal image.

It mounts a volume named `claude-credentials` at `/mnt/claude-credentials` and
sets `CLAUDE_CONFIG_DIR` to that path, so it does not depend on the host or
container user name. Create the volume once per host, bound to your config
directory (use `podman` in place of `docker` if that is your engine):

```bash
docker volume create --driver local --opt type=none --opt o=bind \
  --opt device="$(realpath "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")" claude-credentials
```

Then enable it for all dev containers in your VS Code user settings:

```json
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/commit2main/devcontainer/claude-credentials:1": {}
  }
}
```

"Reopen in Container" works as usual; existing containers pick the feature up on
their next rebuild. Nothing is copied into the image, and the feature never
changes ownership or modes of the host files. The container user therefore has
to map to the host user that owns the directory, which is the default with
Docker (`updateRemoteUserUID`) and with VS Code on rootless Podman
(`--userns=keep-id`). On each start `claude-credentials-check` prints a warning,
without failing the container, if the volume is missing its bind, is not
writable, or holds no credentials.

The whole config directory is shared, including settings, history and sessions.
Because `CLAUDE_CONFIG_DIR` is set in the container, Claude Code keeps its
`.claude.json` inside that directory there, so the first container asks for the
onboarding choices once.

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
