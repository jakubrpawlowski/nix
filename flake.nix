{
  description = "amongus macOS setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      username = "amongus";
      homeDirectory = "/Users/${username}";
    in
    {
      darwinConfigurations.amongus = inputs.darwin.lib.darwinSystem {
        modules = [
          (
            { pkgs, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-darwin";

              programs.zsh.enable = true;
              environment.shells = [ pkgs.zsh ];

              nix.settings.experimental-features = "nix-command flakes";

              environment.systemPackages = [
                (pkgs.writeShellScriptBin "focus-wow" ''
                  if /usr/bin/pgrep -f '[W]orld of Warcraft.app/Contents/MacOS/World of Warcraft' >/dev/null 2>&1; then
                    /usr/bin/open -b com.blizzard.worldofwarcraft
                  fi
                '')
              ];

              system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
              system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
              system.defaults.NSGlobalDomain.KeyRepeat = 4;
              system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
              system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
              system.defaults.WindowManager.EnableTiledWindowMargins = false;
              system.defaults.dock.autohide = true;
              system.defaults.dock.orientation = "left";
              system.defaults.dock.static-only = true;
              system.defaults.screensaver.askForPassword = true;
              system.defaults.screensaver.askForPasswordDelay = 0;

              networking.knownNetworkServices = [ "Wi-Fi" ];
              networking.dns = [
                "1.1.1.1"
                "1.0.0.1"
              ];

              system.keyboard.enableKeyMapping = true;
              system.keyboard.remapCapsLockToEscape = true;
              system.keyboard.userKeyMapping =
                let
                  # https://gist.github.com/paultheman/808be117d447c490a29d6405975d41bd
                  lcontrol = 30064771296; # 0x7000000e0
                  lopt = 30064771298; # 0x7000000e2
                  ropt = 30064771302; # 0x7000000e6
                  rcmd = 30064771303; # 0x7000000e7
                in
                [
                  {
                    HIDKeyboardModifierMappingSrc = rcmd;
                    HIDKeyboardModifierMappingDst = lcontrol;
                  }
                  {
                    HIDKeyboardModifierMappingSrc = lopt;
                    HIDKeyboardModifierMappingDst = ropt;
                  }
                  {
                    HIDKeyboardModifierMappingSrc = ropt;
                    HIDKeyboardModifierMappingDst = lopt;
                  }
                ];

              system.stateVersion = 7;
              system.primaryUser = username;

              fonts.packages = [ pkgs.nerd-fonts.inconsolata ];

              services.skhd.enable = true;
              services.skhd.skhdConfig = ''
                ralt - a: open -a 'Safari'
                ralt - s: focus-wow
                ralt - f: open -a 'DeepSeek Harness'
              '';

              users.users.${username}.home = homeDirectory;
            }
          )
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username}.imports = [
                (
                  { pkgs, ... }:
                  {
                    home.stateVersion = "26.05";

                    home.packages = [ pkgs.just ];

                    programs.fzf.enable = true;
                    programs.fzf.enableZshIntegration = true;
                    programs.gh.enable = true;
                    programs.git.enable = true;
                    programs.git.settings.user.email = "jakub.r.pawlowski@gmail.com";
                    programs.git.settings.user.name = "kuba";
                    programs.gitui.enable = true;
                    programs.ripgrep.enable = true;
                    programs.zoxide.enable = true;
                    programs.zoxide.enableZshIntegration = true;
                    programs.zsh.enable = true;
                    programs.zsh.enableCompletion = true;
                    programs.zsh.autosuggestion.enable = true;
                    programs.zsh.syntaxHighlighting.enable = true;
                  }
                )
              ];
            };
          }
        ];
      };
    };
}
