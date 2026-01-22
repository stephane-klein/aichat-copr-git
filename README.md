[![Copr build status](https://copr.fedorainfracloud.org/coprs/stephaneklein/aichat-git/package/aichat-git/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/stephaneklein/aichat-git/package/aichat-git/)

# COPR repository for AIChat (git version)

[COPR](https://copr.fedorainfracloud.org/) package to install the development version of [AIChat](https://github.com/sigoden/aichat/) on [Fedora Linux](https://en.wikipedia.org/wiki/Fedora_Linux).

## Installation

To add the repository ([link](https://copr.fedorainfracloud.org/coprs/stephaneklein/aichat-git)):

```sh
$ sudo dnf copr enable stephaneklein/aichat-git
```

To install the `aichat-git` package:

```sh
$ sudo dnf install aichat-git
```

**Note**: This package conflicts with the stable `aichat` package. You can only have one installed at a time.

## How it works

This package uses **COPR's native SCM integration** with a lightweight GitHub Action for daily triggering:

1. **Daily trigger at 02:00 UTC**: GitHub Action calls COPR webhook
2. **COPR executes `.copr/build-srpm.sh`**: Queries GitHub API for latest commit from `sigoden/aichat`
3. **Change detection**: If no new commit, build is aborted (no unnecessary rebuilds)
4. **Dynamic packaging**: If a new commit exists:
   - Extracts version from `Cargo.toml`
   - Clones the upstream repository
   - Generates source tarball
   - Builds SRPM with version format: `{version}+git{date}.{sha}`
5. **COPR builds**: The package is built for all configured Fedora versions

**All build logic runs on COPR** - GitHub Action only triggers the build via webhook.

## Setup (for maintainers)

### Create the COPR project via CLI

Create the project with network access enabled (required for Cargo):

```sh
$ copr-cli create stephaneklein/aichat-git \
    --chroot fedora-42-x86_64 \
    --chroot fedora-42-aarch64 \
    --chroot fedora-43-x86_64 \
    --chroot fedora-43-aarch64 \
    --enable-net on \
    --description "Development version of AIChat built from latest git commit" \
    --instructions 'sudo dnf copr enable stephaneklein/aichat-git && sudo dnf install aichat-git'
```

Add the package with SCM/make_srpm method:

```sh
$ copr-cli add-package-scm stephaneklein/aichat-git \
    --name aichat-git \
    --clone-url https://github.com/stephane-klein/aichat-copr-git.git \
    --commit main \
    --spec aichat-git.spec \
    --method make_srpm \
    --webhook-rebuild on
```

Enable webhook in COPR:

1. Go to Project Settings → Integrations
2. Copy the webhook URL (should be: `https://copr.fedorainfracloud.org/webhooks/github/216045/e9e8cc96-301d-4dea-84a5-dadac9e5e892/`)
3. The GitHub Action in this repo already uses this webhook

Trigger a first build:

```sh
$ copr-cli buildscm stephaneklein/aichat-git \
    --clone-url https://github.com/stephane-klein/aichat-copr-git.git \
    --commit main \
    --spec aichat-git.spec \
    --method make_srpm
```

### Manual rebuild

To manually trigger a rebuild:

**Via GitHub Actions:**

Go to Actions tab → "Trigger daily COPR build" → "Run workflow"

**Via CLI:**

```sh
$ copr-cli buildscm stephaneklein/aichat-git \
    --clone-url https://github.com/stephane-klein/aichat-copr-git.git \
    --commit main \
    --spec aichat-git.spec \
    --method make_srpm
```

**Via web interface:**

Go to [package page](https://copr.fedorainfracloud.org/coprs/stephaneklein/aichat-git/package/aichat-git/) → Click "Rebuild"

## Architecture

### File Structure

- **`.copr/build-srpm.sh`**: Build automation script
  - Queries GitHub API for latest upstream commit
  - Detects changes (aborts if no new commit)
  - Clones `sigoden/aichat` repository
  - Extracts version from `Cargo.toml`
  - Generates source tarball
  - Builds SRPM with dynamic versioning

- **`.copr/Makefile`**: Simple wrapper that calls `build-srpm.sh`

- **`aichat-git.spec`**: RPM spec file
  - Accepts variables from build script via `--define`
  - Version format: `{upstream_version}+git{date}.{sha}`
  - Contains fallback default values for local builds

- **`.github/workflows/trigger_copr_build.yml`**: Daily trigger
  - Runs at 02:00 UTC daily
  - Calls COPR webhook to start build
  - Can also be triggered manually

## Local testing

### Build with mock (complete local test)

Install Mock:

```sh
$ sudo dnf install mock fedora-packager
$ sudo usermod -a -G mock $USER
# Log out and back in for group changes to take effect
```

Build the SRPM:

```sh
# Generate SRPM
$ make -f .copr/Makefile srpm outdir=$(pwd)

# Or directly with the bash script
$ bash .copr/build-srpm.sh $(pwd)

# Build with Mock (--enable-network required for Cargo dependencies)
$ mock -r fedora-42-x86_64 --enable-network aichat-git-*.src.rpm
```

The resulting RPM will be in `/var/lib/mock/fedora-42-x86_64/result/`.

Install and test:

```sh
$ sudo dnf install /var/lib/mock/fedora-42-x86_64/result/aichat-git-*.x86_64.rpm
$ aichat --version
```

### Quick spec file validation

```sh
# Check spec file syntax
$ rpmlint aichat-git.spec
```
