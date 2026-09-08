# AGENTS.md

Canonical `provider/v1` contract. CUE is the source; JSON Schema is the export;
fixtures are the executable examples.

## Rules

- Edit `provider.cue`, never `schema/`. Run `nix run .#export` and commit the
  result in the same change. The check diffs the export against the commit
- Every struct is closed (`@experiment(explicitopen)`). Open a struct only
  with an explicit `...` and only with a reason in a comment
- No `anyOf` or `oneOf` in the export. Prefer regex, `const`, `enum`,
  `minLength`, and `$ref`. Check the export after every CUE edit
- `#Duration` is the single duration grammar. Do not reintroduce
  `time.Duration`; it exports as a bare string and drops the constraint
- `struct.MinFields` does not export and also drops `additionalProperties:
  false` from the containing object. Do not use it. Non-empty `actions` is a
  consumer runtime rule, not a schema rule
- Payloads (`input`, `data`, `output`) stay `_`. Consuming tools define them
- Every behavior change adds a fixture: an accepted case under `valid/` and a
  rejected case under `invalid/`. Frame fixtures need a `request-`, `event-`,
  or `result-` filename prefix; the check picks the definition from it
- Bump `VERSION` and tag `v<VERSION>` for any change consumers can observe.
  Consumers pin the tag

## Commands

```bash
nix flake check      # vet fixtures, diff export
nix run .#export     # regenerate schema/
nix fmt              # cue fmt + nixfmt
```
