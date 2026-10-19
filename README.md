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
  - GitHub CLI, [pre-commit](.devcontainer/features/pre-commit/), [oh-my-pi (omp)](.devcontainer/features/omp/), [Claude Code](.devcontainer/features/claude-code/)
  - Updates: [build](.github/workflows/build.yml) and publish workflows ([oh-my-pi](.github/workflows/publish-omp.yml), [Claude Code](.github/workflows/publish-claude-code.yml), [Claude Credentials](.github/workflows/publish-claude-credentials.yml), [oh-my-pi Credentials](.github/workflows/publish-omp-credentials.yml)), [Dependabot](.github/dependabot.yml)

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

### Claude Code and oh-my-pi features

To add only the CLIs to an existing Debian/Ubuntu dev container (x86_64 or ARM64):

```json
{
  "features": {
    "ghcr.io/commit2main/devcontainer/claude-code:1": {},
    "ghcr.io/commit2main/devcontainer/omp:1": {}
  }
}
```

Both install a checksum-verified standalone binary and take a `version` option:
`latest` (default), `stable` or `x.y.z` for Claude Code; `latest` (stable) or
exact `x.y.z` for [oh-my-pi](https://github.com/can1357/oh-my-pi). omp does not
require Node or Bun. Credentials are never baked into the image.

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

### Shared oh-my-pi credentials and state

The [`omp-credentials`](.devcontainer/features/omp-credentials/) feature shares
the host's **whole active agent directory** with trusted devcontainers:
`agent.db` credentials (including SQLite sidecars), `config.yml`, `models.yml`,
sessions and their artifacts. It is opt-in, independent of the CLI feature,
and not part of the universal image. Containers can read and write host secrets.
There is no copying, sync daemon, credential conversion or background service.

**Before setup:** host omp must use the same ordinary agent directory as the
volume source: `${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}`. Named profiles ignore
this override and are not shared by this feature. If you migrated to split XDG
data/state/cache directories, deliberately consolidate your existing state and
configure host `PI_CODING_AGENT_DIR` first; do not create a second empty store or
overwrite/merge databases blindly. Root-level plugins, profiles and daemon
sockets outside the agent directory are not shared.

1. Create the source directory, then a bind-backed volume once per host:

   ```bash
   agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
   mkdir -p -m 0700 "$agent_dir"
   docker volume create --driver local --opt type=none --opt o=bind \
     --opt device="$(realpath "$agent_dir")" omp-credentials
   ```

   With rootless Podman, use the same source:

   ```bash
   agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
   mkdir -p -m 0700 "$agent_dir"
   podman volume create --driver local --opt type=none --opt o=bind \
     --opt device="$(realpath "$agent_dir")" omp-credentials
   ```

   These commands do not change existing directory modes. If `omp-credentials`
   already exists, inspect it (`docker volume inspect omp-credentials` or
   `podman volume inspect omp-credentials`) and check its source. A wrong-source
   or ordinary named volume does not share host state. Detach existing consumers
   and preserve their data before manually removing/recreating that volume with
   the intended source; volume creation does not repair an existing volume.

2. Enable sharing for all devcontainers in VS Code user settings:

   ```json
   {
     "dev.containers.defaultFeatures": {
       "ghcr.io/commit2main/devcontainer/omp-credentials:1": {}
     }
   }
   ```

   Or add that feature to one project's `features` object. Install the omp CLI
   feature separately when the image does not already include it.

3. Rebuild existing containers. The feature mounts the volume at `/mnt/omp-agent`
   and sets `PI_CODING_AGENT_DIR` there, independent of user names and HOME.
   Run `omp` and `/login` once on either side using this same agent directory.

Access and handoff:

- Keep Docker's `updateRemoteUserUID` enabled or use rootless Podman
  `--userns=keep-id`. The feature never chowns/chmods host files.
- On SELinux-enforcing Podman hosts, if policy denies this trusted host-state
  mount, explicitly opt in **per devcontainer**:

  ```json
  {
    "runArgs": ["--userns=keep-id", "--security-opt=label=disable"]
  }
  ```

  This disables SELinux label separation for that container. Do not apply it
  globally or automatically relabel your real host state.
- `omp-credentials-check` warns without blocking startup about environment,
  mount or access problems. Missing `agent.db` is a normal first-use notice;
  database presence alone does not prove a valid login.
- Use sequential handoff: do not concurrently resume/edit the same session on
  host and container, or run GC while another environment uses the store.
  Session locking across container namespaces is not guaranteed.
- Different workspace paths produce different session buckets. Explicitly
  resume the shared transcript when handing off across paths; sharing files
  does not imply automatic session selection.

