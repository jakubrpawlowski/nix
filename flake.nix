{
  description = "my sys setup";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    # adds home manager apps to mac spotlight search
    mac-app-util.url = "github:hraban/mac-app-util";
    compass.url = "github:jakubrpawlowski/compass";
  };
  outputs =
    inputs:
    let
      username = "uzytkownik";
      homeDirectory = "/Users/${username}";
    in
    {
      darwinConfigurations.default = inputs.darwin.lib.darwinSystem {
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
              nix.extraOptions = ''
                experimental-features = nix-command flakes
              '';
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
              system.stateVersion = 4;
              system.primaryUser = username;
              system.activationScripts.postActivation.text = ''
                # Set black wallpaper
                osascript -e 'tell application "System Events" to tell every desktop to set picture to "/System/Library/Desktop Pictures/Solid Colors/Black.png"' 2>/dev/null || true
              '';
              # Match the nixbld group ID to what macOS/Nix actually created during installation
              # This might not be needed on a fresh installation
              ids.gids.nixbld = 350;
              fonts.packages = [
                pkgs.nerd-fonts.inconsolata
              ];
              services.skhd.enable = true;
              services.skhd.skhdConfig = ''
                ralt - a: open -a 'Safari'
                ralt - f: open -a "${homeDirectory}/Applications/Home Manager Apps/kitty.app"
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
                inputs.mac-app-util.homeManagerModules.default
                (
                  { pkgs, ... }:
                  let
                    turtle-language-server = pkgs.buildNpmPackage {
                      pname = "turtle-language-server";
                      version = "3.5.0";
                      src = ./pkgs/turtle-language-server;
                      npmDepsHash = "sha256-yxFhK6+lViCryAHC2EhE7HtGdBwXiBiD25uhcTF5Jf4=";
                      dontBuild = true;
                      postInstall = ''
                        mkdir -p $out/bin
                        echo '#!/bin/sh' > $out/bin/turtle-language-server
                        echo "exec ${pkgs.nodejs_24}/bin/node $out/lib/node_modules/turtle-language-server-wrapper/node_modules/turtle-language-server/dist/cli.js \"\$@\"" >> $out/bin/turtle-language-server
                        chmod +x $out/bin/turtle-language-server
                      '';
                    };
                  in
                  {
                    home.stateVersion = "26.05";
                    targets.darwin.copyApps.enable = false;
                    targets.darwin.linkApps.enable = true;
                    home.packages = [
                      # PERSONAL
                      inputs.compass.packages.${pkgs.stdenv.hostPlatform.system}.default
                      pkgs.age
                      pkgs.arduino-cli
                      pkgs.delve
                      pkgs.deno
                      pkgs.dotnetCorePackages.sdk_10_0-bin
                      pkgs.erlang
                      pkgs.erlang-language-platform
                      pkgs.esptool
                      pkgs.ffmpeg
                      pkgs.fennel-ls
                      pkgs.fnlfmt
                      pkgs.gleam
                      pkgs.gopls
                      pkgs.hurl
                      pkgs.icdiff
                      pkgs.just
                      pkgs.lua-language-server
                      pkgs.marksman
                      pkgs.nil
                      pkgs.nixfmt
                      pkgs.ocamlformat
                      pkgs.ocamlPackages.ocaml-lsp
                      pkgs.oci-cli
                      pkgs.opentofu
                      pkgs.pandoc
                      pkgs.pi-coding-agent
                      pkgs.sops
                      pkgs.ssh-to-age
                      pkgs.stylua
                      pkgs.uv
                      pkgs.wakeonlan
                      pkgs.watchexec
                      pkgs.yt-dlp
                      (pkgs.weechat.override {
                        configure =
                          { availablePlugins, ... }:
                          {
                            scripts = with pkgs.weechatScripts; [
                              wee-slack
                            ];
                            plugins = with availablePlugins; [
                              python
                            ];
                          };
                      })
                      # WORK
                      pkgs.graph-easy
                      pkgs.nodejs_24
                      pkgs.serd
                      turtle-language-server
                      pkgs.slides
                      pkgs.typescript-language-server
                    ];
                    home.file.".pi/agent/AGENTS.md".text = ''
                      # Agent Rules
                      1. Simplicity.
                      2. Minimalism.
                      3. Break work into smallest logical milestones (one function, one feature, etc.).
                      4. Default: current working directory for all file operations.
                    '';
                    home.file.".pi/agent/extensions/notify-sound/index.ts".text =
                      builtins.readFile ./pi-extensions/notify-sound/index.ts;
                    home.file.".pi/agent/extensions/format-on-change/index.ts".text =
                      builtins.readFile ./pi-extensions/format-on-change/index.ts;
                    home.file.".pi/agent/extensions/web-tools/index.ts".text =
                      builtins.readFile ./pi-extensions/web-tools/index.ts;
                    home.file.".pi/agent/extensions/web-tools/ddg-parser.js".text =
                      builtins.readFile ./pi-extensions/web-tools/ddg-parser.js;
                    home.file.".pi/agent/extensions/confirm-actions/index.ts".text =
                      builtins.readFile ./pi-extensions/confirm-actions/index.ts;
                    home.file.".config/helix/runtime/queries/turtle/highlights.scm".text = ''
                      (comment) @comment.line
                      (namespace) @namespace
                      (iri_reference) @string.special.url
                      (string) @string
                      (integer) @constant.numeric.integer
                      (decimal) @constant.numeric.float
                      (double) @constant.numeric.float
                      (boolean_literal) @constant.builtin
                      (pn_local) @variable
                      [ "," ";" "." ] @punctuation.delimiter
                      [ "@prefix" "PREFIX" "@base" "BASE" ] @keyword.directive
                      [ "[" "]" "(" ")" ] @punctuation.bracket
                      (lang_tag) @attribute
                      [ "^^" ] @operator
                      ("a") @keyword.operator
                    '';
                    programs.fzf.enable = true;
                    programs.fzf.enableZshIntegration = true;
                    programs.gh.enable = true;
                    programs.git.enable = true;
                    programs.git.settings.user.email = "jakub.r.pawlowski@gmail.com";
                    programs.git.settings.user.name = "kuba";
                    programs.gitui.enable = true;
                    programs.go.enable = true;
                    programs.helix.defaultEditor = true;
                    programs.helix.enable = true;
                    programs.helix.package = pkgs.helix;
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
                      language-server.lua-language-server = {
                        config.Lua.runtime.version = "LuaJIT";
                      };
                      language-server.turtle-language-server = {
                        command = "turtle-language-server";
                        args = [ "--stdio" ];
                      };
                      language = [
                        {
                          name = "fennel";
                          scope = "source.fennel";
                          file-types = [ "fnl" ];
                          comment-token = ";";
                          language-servers = [ "fennel-ls" ];
                          auto-format = true;
                          formatter = {
                            command = "fnlfmt";
                            args = [ "-" ];
                          };
                        }
                        {
                          name = "html";
                          scope = "text.html.basic";
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
                          scope = "source.js";
                          auto-format = true;
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
                          name = "lua";
                          scope = "source.lua";
                          language-servers = [ "lua-language-server" ];
                          auto-format = true;
                          formatter = {
                            command = "stylua";
                            args = [ "-" ];
                          };
                        }
                        {
                          name = "markdown";
                          scope = "source.md";
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
                          scope = "source.nix";
                          auto-format = true;
                          formatter = {
                            command = "nixfmt";
                          };
                        }
                        {
                          name = "ocaml";
                          scope = "source.ocaml";
                          auto-format = true;
                          language-servers = [ "ocamllsp" ];
                          formatter = {
                            command = "ocamlformat";
                            args = [
                              "--enable-outside-detected-project"
                              "--name"
                              "any_file_name.ml"
                              "-"
                            ];
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
                          scope = "source.tsx";
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
                          scope = "source.ts";
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
                        {
                          name = "turtle";
                          scope = "source.turtle";
                          file-types = [ "ttl" ];
                          comment-token = "#";
                          language-servers = [ "turtle-language-server" ];
                          auto-format = false;
                          formatter = {
                            command = "serdi";
                            args = [
                              "-o"
                              "turtle"
                              "-"
                            ];
                          };
                        }
                      ];
                      grammar = [
                        {
                          name = "turtle";
                          source = {
                            git = "https://github.com/GordianDziwis/tree-sitter-turtle";
                            rev = "7f789ea7ef765080f71a298fc96b7c957fa24422";
                          };
                        }
                      ];
                    };
                    # disable opening urls with left click
                    programs.kitty.extraConfig = ''
                      mouse_map left click ungrabbed
                    '';
                    programs.kitty.font.size = 20;
                    programs.kitty.font.name = "Inconsolata Nerd Font Mono";
                    programs.kitty.keybindings = {
                      # launch new pane with current directory
                      "kitty_mod+enter" = "launch --cwd=current";
                      # window pane navigation
                      "alt+q" = "first_window";
                      "alt+w" = "second_window";
                      "alt+e" = "third_window";
                      "alt+r" = "fourth_window";
                      "alt+t" = "fifth_window";
                      # tab navigation
                      "alt+1" = "goto_tab 1";
                      "alt+2" = "goto_tab 2";
                      "alt+3" = "goto_tab 3";
                      "alt+4" = "goto_tab 4";
                      "alt+5" = "goto_tab 5";
                    };
                    programs.kitty.settings = {
                      scrollback_lines = 5000;
                      active_border_color = "#aa00aa";
                      # background_opacity = 0.8;
                      detect_urls = "no";
                      enabled_layouts = "fat:bias=82;full_size=2;,stack";
                      hide_window_decorations = "yes";
                      inactive_text_alpha = 0.5;
                      macos_option_as_alt = "yes";
                      macos_show_window_title_in = "none";
                      paste_actions = "no-op";
                      tab_bar_edge = "top";
                      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{'[Alt+' + str(index) + ']' if index <= 5 else str(index)} {tab.active_wd.split('/')[-1]}";
                      term = "xterm-256color";
                      window_margin_width = 4;
                      window_padding_width = 4;
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
                    # Opam still requires running:
                    # opam init --bare
                    # one time and selecting:
                    # 5. No, I'll remember to run eval $(opam env) when I need opam
                    programs.opam.enableZshIntegration = true;
                    programs.ripgrep.enable = true;
                    programs.ripgrep.arguments = [
                      "--type-add=tsx:*.tsx"
                    ];
                    programs.zoxide.enable = true;
                    programs.zoxide.enableNushellIntegration = true;
                    programs.zoxide.enableZshIntegration = true;
                    programs.zsh.autosuggestion.enable = true;
                    programs.zsh.enable = true;
                    programs.zsh.enableCompletion = true;
                    programs.zsh.syntaxHighlighting.enable = true;
                    programs.zsh.initContent = builtins.readFile ./zsh-custom.zsh;
                  }
                )
              ];
            };
          }
        ];
      };
    };
}
