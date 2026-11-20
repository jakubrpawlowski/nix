# amongus Nix setup

Minimal nix-darwin + home-manager configuration for this Mac (Apple Silicon).
The flake exposes exactly one configuration: `amongus`.

## What is managed

- zsh with completion, autosuggestions, and syntax highlighting
- git, gitui, fzf, ripgrep, zoxide, just
- macOS defaults, DNS, keyboard remapping, and the Inconsolata Nerd Font
- skhd hotkeys:
  - `ralt - a`: open Safari
  - `ralt - f`: open DeepSeek Harness

No editor, terminal, language server, or per-machine package split is managed.

## First install

Nix is not installed yet. Bootstrap it with Lix, which is the current
nix-darwin recommendation and has a working uninstaller. nix-darwin takes over
Nix management on the first switch and uses upstream Nix by default.

1. Install the Xcode Command Line Tools if they are missing:

   ```bash
   xcode-select --install
   ```

2. Install Lix:

   ```bash
   curl -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

3. Open a new terminal and verify:

   ```bash
   nix --version
   ```

4. Run the first switch from this repo. This installs nix-darwin and builds the
   `amongus` configuration:

   ```bash
   sudo nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
     switch --flake ~/projects/nix#amongus
   ```

5. Restart, then approve skhd in
   System Settings → Privacy & Security → Accessibility.

## Rebuild

```bash
sudo darwin-rebuild switch --flake ~/projects/nix#amongus
```

## Update

```bash
cd ~/projects/nix
nix flake update
sudo darwin-rebuild switch --flake .#amongus
```

`flake.lock` pins the current inputs. `nix flake update` refreshes them.
