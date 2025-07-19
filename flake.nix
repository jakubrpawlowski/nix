{
  description = "my sys setup";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    # adds home manager apps to mac spotlight search
    mac-app-util.url = "github:hraban/mac-app-util";
  };
  outputs = inputs: {
    darwinConfigurations.Mac = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
      };
      modules = [
        inputs.mac-app-util.darwinModules.default
        (
          { pkgs, ... }:
          {
            programs.zsh.enable = true;
            environment.shells = [ pkgs.zsh ];
            environment.loginShell = [ pkgs.zsh ];
            # I had to install https://brew.sh so I can install envoy because nix does not have aarch64-darwin version yet
            environment.systemPath = [ "/opt/homebrew/bin" ];
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
            system.stateVersion = 4;
            fonts.packages = [
              pkgs.nerd-fonts.inconsolata
            ];
            services.nix-daemon.enable = true;
            services.skhd.enable = true;
            services.skhd.skhdConfig = ''
              ralt - w: open -a 'Safari'
              ralt - r: open -a "/Users/jakubpawlowski/Applications/Home Manager Apps/kitty.app"
              ralt - s: open -a 'Slack'
              ralt - d: open -a 'Cliq'
            '';
            users.users.jakubpawlowski.home = "/Users/jakubpawlowski";
          }
        )
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.jakubpawlowski.imports = [
              inputs.mac-app-util.homeManagerModules.default
              (
                { pkgs, ... }:
                let
                  pkgs-unstable = import inputs.nixpkgs-unstable {
                    system = "aarch64-darwin";
                    config = {
                      allowUnfreePredicate =
                        pkg:
                        builtins.elem (inputs.nixpkgs-unstable.lib.getName pkg) [
                          "claude-code"
                        ];
                    };
                  };
                in
                {
                  home.stateVersion = "25.05";
                  home.packages = [
                    # PERSONAL
                    pkgs-unstable.claude-code
                    pkgs.deno
                    pkgs.erlang
                    pkgs.erlang-ls
                    pkgs.gopls
                    pkgs.marksman
                    pkgs.nil
                    pkgs.nixfmt-rfc-style
                    pkgs.weechat-unwrapped
                    # WORK
                    (pkgs.google-cloud-sdk.withExtraComponents [
                      pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
                    ])
                    pkgs.grpc-gateway
                    pkgs.kubectl
                    pkgs.nodejs_24
                    pkgs.telepresence2
                    pkgs.typescript-language-server
                    pkgs.yarn
                  ];
                  home.file.".claude/CLAUDE.md".text = ''
                    # Most Important Rule: Simplicity and Minimalism
                    - Keep code minimal
                    - No overengineering
                    - Break work into smallest logical milestones (one function, one feature, etc.)

                    # Stack specific requirements

                    ## Go
                    - Develop with TDD

                    ## React
                    - Don't include refs in dependency arrays
                  '';
                  home.file.".claude/format-code.nu".text = # nu
                    ''
                      let file_path = cat | from json | get tool_input.file_path
                      if ($file_path | str ends-with ".nix") {
                        nixfmt $file_path
                      } else if (($file_path | str ends-with ".ts") or ($file_path | str ends-with ".tsx")) {
                        npx prettier --write $file_path
                      } else if ($file_path | str ends-with ".html") {
                        deno fmt $file_path
                      }
                    '';
                  home.file.".claude/settings.json".text = builtins.toJSON {
                    hooks = {
                      Notification = [
                        {
                          matcher = "";
                          hooks = [
                            {
                              type = "command";
                              command = "afplay /System/Library/Sounds/Glass.aiff";
                            }
                          ];
                        }
                      ];
                      Stop = [
                        {
                          matcher = "";
                          hooks = [
                            {
                              type = "command";
                              command = "afplay /System/Library/Sounds/Ping.aiff";
                            }
                          ];
                        }
                      ];
                      PostToolUse = [
                        {
                          matcher = "Write|Edit|MultiEdit";
                          hooks = [
                            {
                              type = "command";
                              command = "nu ~/.claude/format-code.nu";
                            }
                          ];
                        }
                      ];
                    };
                  };
                  programs.fzf.enable = true;
                  programs.fzf.enableZshIntegration = true;
                  programs.gh.enable = true;
                  programs.git.enable = true;
                  programs.git.userEmail = "jakub.r.pawlowski@gmail.com";
                  programs.git.userName = "kuba";
                  programs.gitui.enable = true;
                  programs.go.enable = true;
                  programs.helix.defaultEditor = true;
                  programs.helix.enable = true;
                  programs.helix.extraPackages = [
                    pkgs.marksman
                  ];
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
                      auto-pairs = false;
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
                        name = "html";
                        auto-format = true;
                        formatter = {
                          command = "deno";
                          args = [
                            "fmt"
                            "-"
                            "--ext"
                            "html"
                          ];
                        };
                      }
                      {
                        name = "javascript";
                        formatter = {
                          command = "deno";
                          args = [
                            "fmt"
                            "-"
                            "--ext"
                            "js"
                          ];
                        };
                      }
                      {
                        name = "markdown";
                        auto-format = true;
                        formatter = {
                          command = "deno";
                          args = [
                            "fmt"
                            "-"
                            "--ext"
                            "md"
                          ];
                        };
                      }
                      {
                        name = "nix";
                        auto-format = true;
                        formatter = {
                          command = "nixfmt";
                        };
                      }
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
                        formatter = {
                          command = "refmt";
                        };
                      }
                      {
                        name = "tsx";
                        formatter = {
                          command = "npx";
                          args = [
                            "prettier"
                            "--stdin-filepath"
                            "any_file_name.tsx"
                          ];
                        };
                      }
                      {
                        name = "typescript";
                        auto-format = true;
                        formatter = {
                          command = "npx";
                          args = [
                            "prettier"
                            "--stdin-filepath"
                            "any_file_name.ts"
                          ];
                        };
                      }
                    ];
                  };
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
                    paste_actions = "no-op";
                    macos_option_as_alt = "yes";
                    hide_window_decorations = "yes";
                    tab_bar_edge = "top";
                    window_padding_width = "6.0";
                    # Kitty colors are:
                    # 0: black
                    # 1: red 2: green 3: yellow 4: blue 5: magenta 6: cyan
                    # 7: white (it's light gray)
                    # 8: bright-black (it's dark gray)
                    # 9: bright-red 10: bright-green 11: bright-yellow 12: bright-blue 13: bright-magenta 14: bright-cyan
                    # 15: bright-white (it's white)
                    # I like early 1990s colors
                    #                       VGA    Kitty    EGA
                    color0 = "#000000"; # #000000 #000000 #000000
                    color1 = "#aa0000"; # #800000 #cc0403 #aa0000
                    color2 = "#00aa00"; # #008000 #19cb00 #00aa00
                    color3 = "#aa5500"; # #808000 #cecb00 #aa5500
                    color4 = "#0000aa"; # #000080 #0d73cc #0000aa
                    color5 = "#aa00aa"; # #800080 #cb1ed1 #aa00aa
                    color6 = "#00aaaa"; # #008080 #0dcdcd #00aaaa
                    color7 = "#aaaaaa"; # #c0c0c0 #dddddd #aaaaaa
                    color8 = "#555555"; # #808080 #767676 #555555
                    color9 = "#ff5555"; # #ff0000 #f2201f #ff5555
                    color10 = "#55ff55"; # #00ff00 #23fd00 #55ff55
                    color11 = "#ffff55"; # #ffff00 #fffd00 #ffff55
                    color12 = "#5555ff"; # #0000ff #1a8fff #5555ff
                    color13 = "#ff55ff"; # #ff00ff #fd28ff #ff55ff
                    color14 = "#55ffff"; # #00ffff #14ffff #55ffff
                    color15 = "#ffffff"; # #ffffff #ffffff #ffffff
                  };
                  programs.kitty.enable = true;
                  programs.nushell.enable = true;
                  programs.opam.enable = true;
                  programs.opam.enableZshIntegration = true;
                  programs.ripgrep.enable = true;
                  programs.zoxide.enable = true;
                  programs.zoxide.enableNushellIntegration = true;
                  programs.zoxide.enableZshIntegration = true;
                  programs.zsh.autosuggestion.enable = true;
                  programs.zsh.enable = true;
                  programs.zsh.enableCompletion = true;
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
