{
  description = "A Phoenix project";

  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, gitignore }:
    flake-utils.lib.eachSystem [
      # TODO: Configure your supported system here.
      "x86_64-linux"
      "aarch64-linux"
      "i686-linux"
      "x86_64-darwin"
    ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          inherit (gitignore.lib) gitignoreSource;

          # Set the Erlang version
          erlangVersion = "erlangR24";
          # Set the Elixir version
          elixirVersion = "elixir_1_12";
          erlang = pkgs.beam.interpreters.${erlangVersion};
          elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};
          elixir_ls = pkgs.beam.packages.${erlangVersion}.elixir_ls;

          inherit (pkgs.lib) optional optionals;

          fileWatchers =
            with pkgs;
            (optional stdenv.isLinux inotify-tools
              ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]));

        in
        rec {
          # TODO: Add your Elixir package
          # packages = flake-utils.lib.flattenTree {
          # } ;

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = gitignoreSource ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
                nix-linter.enable = true;
                # TODO: Add a linter for Elixir
              };
            };
          };
          devShell = nixpkgs.legacyPackages.${system}.mkShell {
            buildInputs = [
              erlang
              elixir
              elixir_ls
            ] ++ (with pkgs; [
              nodejs
            ]) ++ fileWatchers;

            inherit (self.checks.${system}.pre-commit-check) shellHook;

            LANG = "C.UTF-8";
            ERL_AFLAGS = "-kernel shell_history enabled";
          };
        }
      )
  ;
}
