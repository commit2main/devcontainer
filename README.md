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
  - Updates: [build](.github/workflows/build.yml) and publish workflows ([OpenCode](.github/workflows/publish-opencode.yml), [Claude Code](.github/workflows/publish-claude-code.yml), [Claude Credentials](.github/workflows/publish-claude-credentials.yml), [OpenCode Credentials](.github/workflows/publish-opencode-credentials.yml)), [Dependabot](.github/dependabot.yml)

## Usage

### Universal image

Create `.devcontainer/devcontainer.json`:

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

### Claude Code and OpenCode features

To add only the CLIs to an existing Debian/Ubuntu dev container (x86_64 or ARM64):

```json
{
  "features": {
    "ghcr.io/commit2main/devcontainer/claude-code:1": {},
    "ghcr.io/commit2main/devcontainer/opencode:1": {}
  }
}
```

Both install a checksum-verified standalone binary and take a `version` option:
`latest` (default), `stable` or `x.y.z` for Claude Code; `latest` or `2.x.y` for
OpenCode. Credentials are never baked into the image.

### Shared Claude credentials

The [`claude-credentials`](.devcontainer/features/claude-credentials/) feature
shares the host's Claude Code config directory with every dev container, so you
log in once. It is not part of the universal image.

1. Create the volume once per host (`podman` works in place of `docker`):

   ```bash
   docker volume create --driver local --opt type=none --opt o=bind \
     --opt device="$(realpath "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")" claude-credentials
   ```

2. Enable the feature for all dev containers in your VS Code user settings:

   ```json
   {
     "dev.containers.defaultFeatures": {
       "ghcr.io/commit2main/devcontainer/claude-credentials:1": {}
     }
   }
   ```

3. Reopen in Container as usual; existing containers need a rebuild.

Notes:

- The volume is mounted at `/mnt/claude-credentials` and `CLAUDE_CONFIG_DIR`
  points to it, independent of host and container user names.
- The whole directory is shared: credentials, settings, history and sessions.
- Host files are never copied, chowned or chmodded, so the container user must
  map to the host user. This is the default with Docker (`updateRemoteUserUID`)
  and with VS Code on rootless Podman (`--userns=keep-id`).
- `claude-credentials-check` runs on each start and warns, without failing the
  container, if the volume is not bind-backed, not writable or has no credentials.

### Shared OpenCode credentials

The [`opencode-credentials`](.devcontainer/features/opencode-credentials/)
feature keeps OpenCode V2 logins in sync between the host and every dev
container. Each side keeps its own `opencode.db`, so sessions stay separate;
only the output of `opencode auth export` is exchanged, through a `0600` file in
a host directory. It is not part of the universal image.

1. Run the host setup once from a clone of this repository (pass `podman` if
   that is your engine). It creates the store in
   `~/.local/share/opencode-credentials`, the `opencode-credentials` volume
   bound to it, and a systemd user service that syncs the host's OpenCode:

   ```bash
   .devcontainer/features/opencode-credentials/host-setup.sh docker
   ```

2. Enable the feature for all dev containers in your VS Code user settings:

   ```json
   {
     "dev.containers.defaultFeatures": {
       "ghcr.io/commit2main/devcontainer/opencode-credentials:1": {}
     }
   }
   ```

3. Reopen in Container as usual; existing containers need a rebuild.

Notes:

- `opencode-credentials-sync` runs on each start and then every 30 seconds
  (`OPENCODE_CREDENTIALS_INTERVAL`) when either side changed. It never fails the
  container and does nothing if OpenCode is not installed.
- Logins and logouts propagate everywhere. A refreshed OAuth token replaces
  older copies: the copy that expires later wins. The last remaining credential
  is never removed automatically.
- A token refreshed on one machine reaches the others within one interval. Two
  machines refreshing the same token inside that window can still invalidate
  each other; log in again if that happens.
- The same user-mapping requirement as for the Claude feature applies; host
  files are never chowned or chmodded, and secrets never appear in arguments or
  logs.
