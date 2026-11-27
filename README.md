# OpenCode for Termux

Run [OpenCode](https://opencode.ai) — the open source AI coding agent — natively on Android with Termux.

No proot, no chroot, no Linux container. The installer downloads the official OpenCode release and runs it through the Termux `glibc` loader.

> Repository: [sakil843/Opencode-](https://github.com/sakil843/Opencode-)
>
> Made by **Sakil** ([@sakil843](https://github.com/sakil843))

## Quick Start

One command install:

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/install.sh | bash
```

Then start OpenCode:

```bash
opencode
```

Add an API key / log in:

```bash
opencode auth login
```

## Requirements

- Termux installed from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub releases](https://github.com/termux/termux-app/releases) — **not** the Play Store build
- Android 9+ (API 28 or newer)
- `aarch64` (ARM64) or `x86_64` device
- About 250 MB of free storage
- Internet connection for installation and AI requests

## What the installer does

1. Detects your architecture and Termux environment.
2. Installs `glibc` (and any missing tools) through `pkg`.
3. Downloads the latest official OpenCode release from GitHub.
4. Stores the real binary in `~/.local/share/opencode-termux`.
5. Creates a small `opencode` launcher in `$PREFIX/bin` that runs the binary through the glibc loader with Termux certificates and DNS settings.

Nothing is installed system-wide outside Termux, and no root is required.

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/update.sh | bash
```

Or, if you cloned this repository:

```bash
bash update.sh
```

On Termux, use `update.sh` instead of `opencode upgrade`. The built-in upgrade command replaces the binary with a glibc build that is not wrapped for Android.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/uninstall.sh | bash
```

To also delete OpenCode config, auth and session data:

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/uninstall.sh | bash -s -- --purge
```

`glibc` is left installed because other Termux packages may use it.

## Install options

```bash
# Install a specific version
bash install.sh --version 1.19.6

# Install from a local release archive (offline)
OPENCODE_ARCHIVE=/path/to/opencode-linux-arm64.tar.gz bash install.sh --no-deps

# Skip automatic package installation
bash install.sh --no-deps

# Show help
bash install.sh --help
```

Environment variables:

| Variable | Default | Description |
| --- | --- | --- |
| `OPENCODE_VERSION` | latest | Version to install, e.g. `1.19.6` |
| `OPENCODE_INSTALL_DIR` | `~/.local/share/opencode-termux` | Where the real binary is stored |
| `OPENCODE_BIN_DIR` | `$PREFIX/bin` | Where the `opencode` launcher is created |
| `OPENCODE_REPO` | `anomalyco/opencode` | GitHub repository to download releases from |
| `OPENCODE_ARCHIVE` | (none) | Install from a local release `.tar.gz` instead of downloading |

## Manual install

```bash
git clone https://github.com/sakil843/Opencode-.git
cd opencode
bash install.sh
```

## Troubleshooting

**`glibc loader not found`**

```bash
pkg install glibc-repo
pkg update
pkg install glibc
```

**Download failed or GitHub API rate limit**

Pin a known version instead of using the latest:

```bash
bash install.sh --version 1.19.6
```

**TLS / certificate errors**

```bash
pkg install ca-certificates
```

**`Unsupported architecture`**

OpenCode releases are available for `aarch64`/`arm64` and `x86_64` only. 32-bit ARM devices are not supported.

**A previous opencode installation was replaced**

The installer backs it up to `$PREFIX/bin/opencode.bak.<timestamp>`. Restore it with:

```bash
mv "$PREFIX/bin/opencode.bak.<timestamp>" "$PREFIX/bin/opencode"
```

## বাংলা নির্দেশনা

### এক কমান্ডে ইনস্টল

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/install.sh | bash
```

ইনস্টল শেষ হলে চালান:

```bash
opencode
```

API key যোগ করতে:

```bash
opencode auth login
```

### আপডেট

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/update.sh | bash
```

### আনইনস্টল

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/uninstall.sh | bash
```

সম্পূর্ণ কনফিগ ও ডাটা মুছতে `--purge` ব্যবহার করুন:

```bash
curl -fsSL https://raw.githubusercontent.com/sakil843/Opencode-/main/uninstall.sh | bash -s -- --purge
```

### প্রয়োজন

- F-Droid বা GitHub থেকে ইনস্টল করা Termux (Play Store ভার্সন নয়)
- Android 9 বা তার উপরে
- ARM64 (`aarch64`) বা `x86_64` ডিভাইস
- প্রায় ২৫০ MB ফাঁকা জায়গা এবং ইন্টারনেট

## Author

**Sakil** — [github.com/sakil843](https://github.com/sakil843)

## License

[MIT](LICENSE)
