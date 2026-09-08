# provider-spec

Canonical `provider/v1` contract: CUE source, JSON Schema export, fixtures.

A provider is an executable described by a manifest. A caller writes one
`request` frame to its standard input and reads `event` frames followed by one
`result` frame from its standard output. This repository specifies the manifest
and the frame envelopes. Payloads (`input`, `data`, `output`) belong to the
consuming tool.

- `provider.cue`: the source of truth. Every struct is closed.
- `schema/`: JSON Schema 2020-12 exported from the CUE, one file per
  definition. `provider.schema.json` is the manifest. Generated; do not edit.
- `fixtures/manifest/{valid,invalid}/*.yaml`: manifests the contract accepts
  and rejects.
- `fixtures/frames/{valid,invalid}/*.json`: frames, named by kind prefix
  (`request-`, `event-`, `result-`).
- `VERSION`: the released contract version. Tags are `v<VERSION>`.

## Duration

One grammar, shared by every consumer:

```
^([0-9]+(\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$
```

Accepts `500ms`, `1h30m`, `1.5s`, `1h30m15.25s`, `0s`. Rejects `0`, `-1s`,
`.5s`, `1.s`, `1h 30m`, `1H`, `1d`. This is a strict subset of Go's
`time.ParseDuration`. The `duration-*` fixtures are the test vectors.

## Regenerate

```bash
nix run .#export
```

`nix flake check` vets every fixture with its expected outcome and fails when
`schema/` differs from a fresh export.

## Consume

Pin the tag as a flake input and copy the schema you need:

```nix
inputs.provider-spec.url = "github:roshbhatia/provider-spec/v1.0.0";
```

```bash
cp ${provider-spec}/schema/provider.schema.json provider/spec/
cp ${provider-spec}/VERSION provider/spec/VERSION
```

Add a check that diffs the committed copy against the input so a forgotten
copy fails the build. Validate at runtime with any JSON Schema 2020-12
validator; the export uses no `anyOf` or `oneOf`.
