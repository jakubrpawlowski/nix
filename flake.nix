{
  description = "my sys setup";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    home-manager.url = "github:nix-community/home-manager/master";
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
          system.keyboard.enableKeyMapping = true;
          system.keyboard.remapCapsLockToEscape = true;
          system.nixpkgsRelease = "24.05";
          system.stateVersion = 4;
          services.nix-daemon.enable = true;
          services.postgresql.enable = true;
          services.postgresql.package = pkgs.postgresql_15;
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
                  pkgs.just
                  pkgs.less
                  # this will need to be swapped to fnm https://github.com/NixOS/nixpkgs/issues/202401
                  pkgs.nodejs_20
                  pkgs.sops
                  pkgs.yarn
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
                programs.kitty.enable = true;
                programs.kitty.font.size = 16;
                programs.kitty.font.name = "Menlo";
                programs.helix.enable = true;
                programs.helix.defaultEditor = true;
                programs.helix.settings = {
                  theme = "modus_vivendi_tinted";
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
                programs.zoxide.enable = true;
                programs.zoxide.enableZshIntegration = true;
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
