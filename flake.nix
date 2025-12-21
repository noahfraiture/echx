{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {

            buildInputs = with pkgs; [
            ];

            packages = with pkgs; [
            ];

            DIRENV = "env";
          };
          go = pkgs.mkShell {
            packages = with pkgs; [
              go-task
              templ
              tailwindcss_4
              sqlc
              nodejs_24
            ];
            DIRENV = "go website";
          };
          python = pkgs.mkShell {
            packages =
              with pkgs;
              [ python312 ]
              ++ (with pkgs.python312Packages; [
              ]);

            DIRENV = "python";
          };
          rust = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              clippy
              openssl
              rust
              rust-analyzer
              rustc
              rustfmt
            ];
            DIRENV = "rust";
          };
          gleam = pkgs.mkShell {
            packages = with pkgs; [
              rebar3
              gleam
              erlang
            ];
            DIRENV = "gleam";
          };
        }
      );
    };
}
