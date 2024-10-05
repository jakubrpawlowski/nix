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
                # programs.zsh.envExtra = ''
                #   export ANDROID_HOME=~/Library/Android/sdk
                #   export PATH=$PATH:$ANDROID_HOME/emulator
                #   export PATH=$PATH:$ANDROID_HOME/tools
                #   export PATH=$PATH:$ANDROID_HOME/tools/bin
                #   export PATH=$PATH:$ANDROID_HOME/platform-tools
                # '';
                programs.nushell.enable = true;
                programs.kitty.enable = true;
                programs.kitty.font.size = 12;
                programs.kitty.font.name = "Menlo";
                programs.kitty.settings = {
                  background_opacity = "0.8"; 
                };
                programs.gitui.enable = true;
                programs.git.enable = true;
                programs.git.userName = "kuba";
                programs.git.userEmail = "jakub.r.pawlowski@gmail.com";
                programs.helix.enable = true;
                programs.helix.defaultEditor = true;
                programs.helix.settings = {
                  theme = "papercolor-dark";
                  editor = {
                    true-color = true;
                    file-picker = {
                      hidden = false;
                    };
                  };
                };
                programs.helix.languages = {
                  language = [
                    {
                      name = "reason";
                      scope = "source.reason";
                      file-types = [ "re" ];
                      auto-format = true;
                      language-servers = [ "ocamllsp" ];
                      comment-token = "//";
                      roots = [ "dune-project" ];
                      formatter = { command = "refmt"; };
                    }
                  ];
                };
                # Android
                # programs.java.enable = true;
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
