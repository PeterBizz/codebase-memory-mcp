# CALNAV CALLS-extraction handoff — 2026-09-05

**Audience:** codebase-memory-mcp builder agent (owns `internal/cbm/*.c`).
**Author:** tree-sitter-cal development agent (owns the grammar; must NOT edit `internal/cbm/*.c`).
**Trigger:** `trace_call_path` on `navdev-full.Table.11067889.IsFeatureEnabled` returns `callees_total: 0, callers_total: 0` despite ~40 real call sites in the corpus.

## TL;DR

The tree-sitter-cal grammar is correct and complete for this construct. The gap is in the MCP C extractor, two one-line table additions:

1. `internal/cbm/lang_specs.c:179` — `calnav_call_types` lists only `"call_statement"`; add `"call_expression"`.
2. `internal/cbm/extract_calls.c` (`extract_callee_from_fields`, ~line 270) — the `function`-field kind allowlist lacks `"member_access"`; add it.

Everything below is evidence and risk analysis for those two changes.

## Evidence

### Grammar side is correct (verified with tree-sitter CLI, 2026-09-05)

`FeatureSwitch.IsFeatureEnabled('WAREHOUSEEMPLOYEECHECK')` parses as:

- expression position (inside `if_header` condition, assignment value, call argument):
  `call_expression` with `function: (member_access object: (identifier) member: (identifier))`, `arguments: (argument_list ...)`
- statement position: `call_statement` with the same `function: (member_access ...)` shape.

### Extractor side drops both shapes

- `lang_specs.c:179`: `static const char *calnav_call_types[] = {"call_statement", NULL};`
  → `handle_calls` (extract_calls.c:3487) only fires for `call_statement` nodes. All expression-position calls are never visited. Every one of the ~40 `IsFeatureEnabled` call sites is expression-position.
- `extract_callee_from_fields` handles `member_expression`, `member_access_expression`, `field_expression`, `dot`, … but not CAL's `member_access` node name → returns NULL → call dropped. So even statement-position member calls (`Rec.MODIFY;`) produce no edge. Only bare-identifier calls (`Helper(1,2);`) mint edges — that is where the existing 14,939 CALLS edges come from.
- Result for `IsFeatureEnabled`: 39 inbound USAGE edges (member identifier occurrences), 0 inbound CALLS; body contains only expression-position calls plus `ERROR(...)` (builtin, no def) → out-degree 0. Hence the empty trace.

### Walker mechanics (verified against indexed `codebase-memory-mcp` project)

- `cbm_extract_unified` (extract_unified.c:2372) is a pre-order cursor walk over **every** node, calling `handle_calls` per node. Adding `"call_expression"` to `calnav_call_types` is sufficient — no walker changes needed.
- `handle_calls` → `select_primary_callee` → `extract_callee_name` → `extract_callee_from_fields` (the `function` field). With `"member_access"` added to the kind list, the callee text is the full dotted source text `FeatureSwitch.IsFeatureEnabled`.
- `terminal_callee_leaf` (extract_calls.c:3060): `member_access` matches `strstr(kind, "member")` → `terminal_is_last` → recurses to the `member` identifier. So `callee_leaf` = the member identifier occurrence, `callee_expr` = the whole `member_access`. The usage pass (extract_usages.c:2578) consumes exactly those two occurrences; the receiver (`FeatureSwitch`) stays an ordinary USAGE. This matches the designed behavior for other languages.
- Resolution: `registry.c:simple_name()` takes the last dot segment → `IsFeatureEnabled` → by-name lookup. Unique project-wide name → `unique_name` strategy, confidence 0.75. No LSP exists for CALNAV, so registry resolution is the only path — and it works for unique names.
- `primary_callee_name_is_allowed` → `cbm_is_keyword(name, CBM_LANG_CALNAV)` falls to `generic_keywords`, compared case-sensitively. C/AL keywords are uppercase (`IF`, `BEGIN`, …) and never collide with the lowercase generic list; builtins like `MESSAGE`/`ERROR`/`GET` are not keywords → no filtering problem.
- `is_method` suppression guards exist only for Perl/Python/TS/JS; CALNAV calls are unflagged, so no weak-match suppression kicks in.

## Proposed minimal patch

```c
// internal/cbm/lang_specs.c
static const char *calnav_call_types[] = {"call_statement", "call_expression", NULL};

// internal/cbm/extract_calls.c, extract_callee_from_fields(), function-field kind list
strcmp(fk, "member_access") == 0 ||   // add alongside "member_expression" etc.
```

No other changes required for the baseline fix.

## Expected effect on navdev-full

- `IsFeatureEnabled`: 0 → ~40 inbound CALLS edges (unique-name, 0.75 confidence).
- Corpus-wide: the 2026-09-05 def/ref dump counted 293,826 `ref.call` captures (bare + member, statement + expression). Today only bare `call_statement` callees mint edges (14,939). Expect a large CALLS growth — plausibly an order of magnitude. USAGE count drops correspondingly (member identifiers at call sites are consumed as callee leaves; field accesses like `Rec."No."` remain USAGE).
- `trace_call_path` on table functions starts answering both directions.

## Drawbacks / risks (considered before handoff)

1. **False positives from name-only resolution.** C/AL has no type resolution in MCP, so `SomeVar.Validate(...)` binds any same-named procedure project-wide when the name is unique, and multi-candidate names fall to suffix match (0.55) or bail at >256 candidates. This is the same trade-off already accepted for other no-LSP languages. Optional mitigation (builder's call): set `call.is_method = true` for `member_access`-function calls so weak short-name matches are suppressed — but note that would also suppress the *desired* `FeatureSwitch.IsFeatureEnabled` unique-name edge unless the suppression only applies to multi-candidate/weak cases. Recommend: first ship without `is_method`, measure, then decide.
2. **USAGE→CALLS migration is a consumer-visible behavior change.** Tools that currently grep USAGE edges for call sites (the where-used workaround scripts) must read CALLS instead. The `ref.call`/`ref.member` captures in `queries/whereused.scm` (grammar-side contract) are unaffected.
3. **No double-counting risk.** `call_statement` and `call_expression` are disjoint node kinds in the grammar (a statement call is not wrapped in a `call_expression`); nested calls (`ERROR(STRSUBSTNO(...))`) are separate nodes visited once each — correct.
4. **Quoted member names** (`Rec."No. of Lines"(...)`) carry quotes in both callee text and def name (def side: `func_node_name` takes `procedure_name`'s first named child, which for quoted names is the `quoted_identifier` including quotes) — consistent, no action needed.
5. **`@id` suffixes** never appear at call sites and are excluded from def names by the grammar's `name:` field — consistent.
6. **Performance:** roughly doubles call-node visits for CALNAV files; negligible against the 7,683-file corpus.
7. **Out of scope for this fix (do not bundle):** receiver-type resolution via VAR declarations (`FeatureSwitch@... : Record 11067889` → qualify callee as `Table.11067889.IsFeatureEnabled`), triggers-as-functions, object identity QNs. Those are todos 1–4/6 in `CALNAV-next-improvements-prompt.md` and would raise confidence, but the two-line patch already delivers the where-used value.

## Validation protocol (per INTEGRATION_CHECKLIST.md)

1. Apply patch, incremental build (`calnav specifics\incremental build.ps1`).
2. `cli delete_project --project navdev-full`, then `.\calnav specifics\indexeer NAVDEV-FULL.ps1`.
3. Assert: `trace_call_path` on `navdev-full.Table.11067889.IsFeatureEnabled` → callers include `Table.7311.CheckName`, `Form.5703.UpdateEnabled`, `Table.5766.OpenActivityHeader`, etc. (grep corpus for `IsFeatureEnabled` to cross-check ~40 sites).
4. Record new baseline (nodes/edges/CALLS delta) in `CALNAV-status.md` and report the delta back to the tree-sitter-cal agent for `DELIVERY_SUMMARY.md`.
5. Watch for false-positive hotspots: procedures with very common names (`INIT`, `Validate`, `GetItem`) — spot-check a few traces.
