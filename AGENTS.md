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
- Pattern keys (`[=~"..."]: value`) take a literal regex. A key written as a
  definition reference (`[#Name]: value`) exports as `additionalProperties:
  true` with no error. `#Name` and `#EnvName` are for value positions only
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
- A consumer narrows action names with a per-field hidden check, not a closed
  struct. `actions: {[#ActionName]: #Action}` unified with the spec's pattern
  key widens the accepted set; `[name=string]: {_ok: name & #ActionName}`
  rejects a foreign name (traces does this)
- "At least one of" is not a disjunction of `!:` branches; that stays an
  incomplete value. Use a guarded list comprehension over the keys (changes
  does this)

## Commands

```bash
nix flake check      # vet fixtures, diff export
nix run .#export     # regenerate schema/
nix fmt              # cue fmt + nixfmt
```
