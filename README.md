# Nix Setup

## Installation

1. Install Nix using the Determinate Systems installer:
   ```bash
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```
   **IMPORTANT: Select NO for Determinate Nix when prompted**

2. Restart

3. Initialize nix-darwin:
   ```bash
   sudo nix run nix-darwin -- switch --flake .#default
   ```

4. Restart

5. For subsequent configuration updates:
   ```bash
   sudo darwin-rebuild switch --flake ~/projects/nix/.#default
   ```

## Workarounds

1. skhd was not showing in Accessibility on Tahoe and to fix it I created app
   bundle wrapper:

```bash
sudo mkdir -p /Applications/skhd.app/Contents/MacOS
sudo ln -sf /run/current-system/sw/bin/skhd /Applications/skhd.app/Contents/MacOS/skhd
```

and then in Accessibility + navigated to /Applications/ and selected skhd.app
