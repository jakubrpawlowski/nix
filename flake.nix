{
  description = "my sys setup";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: {
    darwinConfigurations.Jakubs-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
      };
      modules = [
        ({pkgs, ...}: {
          programs.zsh.enable = true;
          environment.shells = [ pkgs.zsh ];
          environment.loginShell = [ pkgs.zsh ];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
          system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
          system.defaults.dock.autohide = true;
          system.defaults.dock.orientation = "left";
          system.defaults.dock.static-only = true;
          system.keyboard.enableKeyMapping = true;
          system.keyboard.remapCapsLockToEscape = true;
          system.keyboard.userKeyMapping = let
            # https://gist.github.com/paultheman/808be117d447c490a29d6405975d41bd
            lcontrol = 30064771296; # 0x7000000e0
            lopt   =   30064771298; # 0x7000000e2
            ropt   =   30064771302; # 0x7000000e6
            rcmd   =   30064771303; # 0x7000000e7
          in [
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
          system.stateVersion = 4;
          fonts.packages = [
            (pkgs.nerdfonts.override { fonts = [ "Inconsolata" ]; })
          ];
          services.nix-daemon.enable = true;
          services.postgresql.enable = true;
          services.postgresql.package = pkgs.postgresql_15;
          services.skhd.enable = true;
          services.skhd.skhdConfig = ''
            ralt - w: open -a 'Safari'
            ralt - r: open -a "/Users/kuba/Applications/Home Manager Apps/kitty.app"
            ralt - s: open -a 'Slack'
            ralt - d: open -a 'Docker Desktop'
            ralt - e: open -a 'TablePlus'
          '';
          users.users.kuba.home = "/Users/kuba";
        })
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.kuba.imports = [
              ({pkgs, ...}: {
                home.stateVersion = "24.05";
                home.packages = [
                  # PERSONAL
                  pkgs.mc
                  pkgs.pspg
                  # WORK
                  pkgs.just
                  pkgs.sops
                  pkgs.yarn
                  # this will need to be swapped to fnm https://github.com/NixOS/nixpkgs/issues/202401
                  pkgs.nodejs_20
                  # iOS
                  pkgs.cocoapods
                  pkgs.fastlane
                  pkgs.ruby_3_3
                ];
                home.sessionVariables = {
                  PAGER = "less";
                };
                programs.fzf.enable = true;
                programs.fzf.enableZshIntegration = true;
                programs.zsh.enable = true;
                programs.zsh.enableCompletion = true;
                programs.zsh.autosuggestion.enable = true;
                programs.zsh.syntaxHighlighting.enable = true;
                # Android
                programs.zsh.envExtra = ''
                  export ANDROID_HOME=~/Library/Android/sdk
                  export PATH=$PATH:$ANDROID_HOME/emulator
                  export PATH=$PATH:$ANDROID_HOME/tools
                  export PATH=$PATH:$ANDROID_HOME/tools/bin
                  export PATH=$PATH:$ANDROID_HOME/platform-tools
                '';
                programs.nushell.enable = true;
                programs.kitty.enable = true;
                # disable opening urls with left click
                programs.kitty.extraConfig = ''
                  mouse_map left click ungrabbed
                '';
                programs.kitty.font.size = 16;
                programs.kitty.font.name = "Inconsolata Nerd Font Mono";
                programs.kitty.keybindings = {
                  # launch new pane with current directory
                  "kitty_mod+enter" = "launch --cwd=current";
                };
                programs.kitty.settings = {
                  background_opacity = "0.8";
                  detect_urls = "no";
                  hide_window_decorations = "yes";
                  tab_bar_edge = "top";
                  window_padding_width = "6.0";
                  # Kitty colors are:
                  # 0: black
                  # 1: red 2: green 3: yellow 4: blue 5: magenta 6: cyan
                  # 7: bright-white
                  # 8: bright-black (it's gray)
                  # 9: bright-red 10: bright-green 11: bright-yellow 12: bright-blue 13: bright-magenta 14: bright-cyan
                  # 15: white
                  color4 = "#0000ff"; # Set blue closer to 1990s
                  color8 = "#808080"; # Set gray closer to 1990s
                  color14 = "#00FFFF"; # Set bright-cyan closer to 1990s
                };
                programs.gitui.enable = true;
                programs.git.enable = true;
                programs.git.userName = "kuba";
                programs.git.userEmail = "jakub.r.pawlowski@gmail.com";
                programs.helix.enable = true;
                programs.helix.defaultEditor = true;
                programs.helix.themes = {
                  # Helix colors are:
                  # default
                  # black
                  # red green yellow blue magenta cyan gray          
                  # light-red light-green light-yellow light-blue light-magenta light-cyan light-gray    
                  # white
                  base16_terminal_kuba = {
                    inherits = "base16_terminal";
                    "ui.virtual.jump-label" = {
                      bg = "magenta";
                      fg = "light-yellow";
                      modifiers = [
                        "bold"
                      ];
                    };
                    "diagnostic.warning" = {
                      underline = {
                        color = "yellow";
                        style = "curl";
                      };
                    };
                    "diagnostic.error" = {
                      underline = {
                        color = "light-red";
                        style = "curl";
                      };
                    };
                  };
                };
                programs.helix.settings = {
                  theme = "base16_terminal_kuba";
                  editor = {
                    true-color = true;
                    file-picker = {
                      hidden = false;
                    };
                    mouse = false;
                  };
                };
                programs.helix.languages = {
                  language = [
                    {
                      name = "reason";
                      scope = "source.reason";
                      file-types = [
                        "re"
                        "rei"
                      ];
                      auto-format = true;
                      language-servers = [ "ocamllsp" ];
                      comment-token = "//";
                      roots = [ "dune-project" ];
                      formatter = { command = "refmt"; };
                    }
                  ];
                };
                # Android
                programs.java.enable = true;
                programs.zoxide.enable = true;
                programs.zoxide.enableZshIntegration = true;
                programs.zoxide.enableNushellIntegration = true;
                programs.opam.enable = true;
                programs.opam.enableZshIntegration = true;
                programs.awscli.enable = true;
                programs.awscli.settings = {
                  default = {
                    region = "us-west-2";
                    output = "json";
                  };
                  kube = {
                    region = "us-west-2";
                    output = "json";
                  };
                };
                programs.awscli.credentials = {
                  default = {
                    credential_process = "/Users/kuba/aws.sh";
                  };
                  kube = {
                    credential_process = "/Users/kuba/aws.sh --username kube";
                  };
                };
              })
            ];
          };
        }
      ];
    };
  };
}
