# skr1ptz

Custom shell configuration and utility scripts by [@und1sk0](https://github.com/und1sk0).

This repository provides a highly-opinionated `.zshrc` setup tailored for **macOS (Intel & Apple Silicon)** with useful defaults, security-minded git helpers, AWS shortcuts, and quality-of-life functions for everyday development and operations work.

---

## ✨ Features

- **Oh-My-Zsh Base** with randomized themes, Git plugin, and `vi` mode.
- **PATH Handling**
  - Base system paths, plus Homebrew prepended by chip architecture (`arm64` → `/opt/homebrew/bin`), not macOS version.
  - Deduplicates `$PATH` on every shell start.
- **Convenient Aliases**
  - Shortcuts for Git, Terraform (`tfa`, `tfp`, etc.), Kubernetes (`k`, `kd`, `kp`), and system tools.
  - `rgr` for recursive grep (`rg` is left free for ripgrep).
  - `vz` to edit and reload `.zshrc` instantly.
- **Git Safety Nets**
  - `gp` and `gpsup` prevent accidental pushes to `main` or `master`.
  - `prune` cleans up local branches whose remote tracking branch is gone (`-f` to force-delete unmerged ones); hops off the current branch first if it's one of the stale ones.
- **AWS Utilities**
  - `ssm` helper for starting AWS SSM sessions.
  - Default AWS profile set to `default`.
- **System Enhancements**
  - Syntax highlighting for `less` output.
  - `fm` to extract ffmpeg metadata.
  - Colorized diffs with `colordiff`.
- **Plugin Support**
  - Bundles [`zi`](https://github.com/z-shell/zi) plugin manager for Zsh.
  - Auto-sources additional configs from `$HOME/.zshconfig/*.zsh`.
- **Rancher Desktop Integration** — automatically manages its PATH.

---

## 🚀 Installation

The real config lives at `zshrc.zsh` in this repo. The actual setup on this
machine wires it in via two symlinks rather than a plain copy, so edits here
take effect immediately without re-installing anything:

```bash
ln -s ~/git/skr1ptz ~/bin
ln -s bin/zshrc.zsh ~/.zshrc
source ~/.zshrc
```

> ⚠️ This will override your existing `~/.zshrc`. Back it up first if you need to preserve custom settings.

## 🛠 Usage Highlights

- **Safe Git Push**
  ```bash
  gp     # push current branch (fails if on main/master)
  gpsup  # push and set upstream (fails if on main/master)
  prune  # delete local branches with no remote tracking (-f to force)
  ```

- **Terraform**
  ```bash
  tfi   # terraform init
  tfp   # terraform plan
  tfa   # terraform apply
  tfd   # terraform destroy
  tff   # terraform fmt
  ```

- **Kubernetes Contexts**
  ```bash
  k     # kubectl
  kd    # use dev context
  kp    # use prod context
  ```

- **AWS**
  ```bash
  ssm i-1234567890abcdef0   # start SSM session
  ```

---

## 📂 Extending

Place custom Zsh configs in `~/.zshconfig/*.zsh` and they will be automatically sourced on startup.

---

## 🧑‍💻 Maintainer

[**und1sk0**](https://github.com/und1sk0)

---

## 🧰 Tools (`bin/`)

Standalone scripts live in [`bin/`](bin/), documented in [`bin/README.md`](bin/README.md). Add it to your `PATH` to run them by name.

- **`substack-mirror`**: mirror a Substack publication's posts to Markdown files (Python + pandoc).
