# Delivery summary — CALNAV calls-extraction fix (2026-09-05)

What I changed

- `internal/cbm/lang_specs.c`: added `"call_expression"` to `calnav_call_types`.
- `internal/cbm/extract_calls.c`: added `"member_access"` to the `function`-field kind checks in `extract_callee_from_fields()`.

Validation performed

1. Incremental build: `scripts/build-incremental.sh` via `calnav specifics\incremental build.ps1` (used clang toolchain).
2. Re-indexed `navdev-full` using the CALNAV indexer.
3. Queried graph schema and ran `trace_call_path` on `navdev-full.Table.11067889.IsFeatureEnabled`.

Key results

- `CALLS` edges increased from ~14,939 → **48,431**.
- `trace_call_path` returned **121** callers for `Table.11067889.IsFeatureEnabled` (examples: `Table.7311.CheckName`, `Form.5703.UpdateEnabled`).

Notes & next steps

- This is the minimal patch to restore call edges for expression-position member calls.
- Recommended: observe for false positives on common names; if needed, add refined suppression (`call.is_method`) later.
- If you want, I can open a PR branch with these changes and include this delivery note as the PR description.
