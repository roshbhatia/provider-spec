{
  description = "Canonical provider/v1 contract: CUE source, JSON Schema export, fixtures";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { nixpkgs, systems, ... }:
    let
      supportedSystems = builtins.filter (system: system != "x86_64-darwin") (import systems);
      eachSystem = nixpkgs.lib.genAttrs supportedSystems;
      # Exported definition -> schema file stem under schema/.
      definitions = {
        Manifest = "provider";
        Request = "request";
        Event = "event";
        Result = "result";
      };
      # Writes one JSON Schema per exported definition into target. Runs from
      # the repository root.
      exportScript = target: ''
        target=${target}
        mkdir -p "$target"
        ${nixpkgs.lib.concatStringsSep "\n" (
          nixpkgs.lib.mapAttrsToList (
            name: stem: ''cue def provider.cue --out jsonschema -e '#${name}' > "$target/${stem}.schema.json"''
          ) definitions
        )}
      '';
    in
    {
      formatter = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "provider-spec-format";
          runtimeInputs = [
            pkgs.cue
            pkgs.fd
            pkgs.nixfmt
          ];
          text = ''
            if [ "$#" -gt 0 ] && [ "''${1#-}" = "$1" ]; then
              exec nixfmt "$@"
            fi
            cue fmt provider.cue
            exec fd --extension nix --type file --exec-batch nixfmt "$@"
          '';
        }
      );

      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "provider-spec";
            version = nixpkgs.lib.trim (builtins.readFile ./VERSION);
            src = ./.;
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/share/provider-spec"
              cp -R provider.cue schema fixtures VERSION "$out/share/provider-spec/"
              runHook postInstall
            '';
          };

          export = pkgs.writeShellApplication {
            name = "provider-spec-export";
            runtimeInputs = [ pkgs.cue ];
            text = exportScript ''"''${1:-schema}"'';
          };
        }
      );

      checks = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          spec =
            pkgs.runCommandLocal "provider-spec-check"
              {
                src = ./.;
                nativeBuildInputs = [
                  pkgs.cue
                  pkgs.diffutils
                ];
              }
              ''
                cd "$src"
                export HOME="$TMPDIR"
                fail=0

                cue fmt --check provider.cue
                cue vet provider.cue

                for file in fixtures/manifest/valid/*.yaml; do
                  if ! cue vet -d '#Manifest' provider.cue "$file"; then
                    echo "accept expected: $file"
                    fail=1
                  fi
                done
                for file in fixtures/manifest/invalid/*.yaml; do
                  if cue vet -d '#Manifest' provider.cue "$file" 2>/dev/null; then
                    echo "reject expected: $file"
                    fail=1
                  fi
                done

                definition() {
                  case "$(basename "$1")" in
                    request-*) echo '#Request' ;;
                    event-*) echo '#Event' ;;
                    result-*) echo '#Result' ;;
                    *) echo "frame fixture $1 needs a request-, event-, or result- prefix" >&2; return 1 ;;
                  esac
                }
                for file in fixtures/frames/valid/*.json; do
                  if ! cue vet -d "$(definition "$file")" provider.cue "$file"; then
                    echo "accept expected: $file"
                    fail=1
                  fi
                done
                for file in fixtures/frames/invalid/*.json; do
                  if cue vet -d "$(definition "$file")" provider.cue "$file" 2>/dev/null; then
                    echo "reject expected: $file"
                    fail=1
                  fi
                done

                ${exportScript ''"$TMPDIR/schema"''}
                if ! diff -r schema "$target"; then
                  echo "schema/ is stale; run nix run .#export"
                  fail=1
                fi

                [ "$fail" -eq 0 ]
                touch "$out"
              '';
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.cue
              pkgs.nixfmt
            ];
          };
        }
      );
    };
}
