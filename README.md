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

6. Build helix tree-sitter grammars (nix configures sources but doesn't compile
   them):
   ```bash
   hx --grammar fetch && hx --grammar build
   ```
