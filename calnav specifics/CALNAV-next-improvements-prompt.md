# CALNAV — next improvements (prompt for a new chat)

Copy-paste the block below as the opening prompt of a new chat session.

---

## Prompt

I'm continuing CALNAV (NAV C/AL) integration work across two repos:

- `c:\Users\peter\Source\Repos\Everest\tree-sitter-cal` — the grammar/parser
- `c:\Users\peter\Source\Repos\Everest\codebase-memory-mcp` — the MCP indexer (C code, vendored parser at `internal/cbm/vendored/grammars/calnav/`)
- Corpus: `c:\Users\peter\Source\Repos\Everest\NAVDev\AllFobDev` (7,683 NAV export files)

**Current verified baseline** (see `calnav specifics/CALNAV-status-update-2026-08-31.md`):
project `navdev-full`, nodes 37,660, edges 107,267, parse_partial_count 13
(10 MenuSuite — excluded by design; 2 Forms with Latin-1 bytes; 1 pathological Table).
Grammar is done: 76/76 corpus tests pass. The C extractor in codebase-memory-mcp is stock —
no C/AL-specific extraction exists yet. This round the scope WIDENS to the C extractor.

**Build/verify workflow (mandatory):**
1. Parser: `npx tree-sitter generate; npx tree-sitter test` in tree-sitter-cal
2. Sync: `.\scripts\sync-calnav-to-mcp.ps1`
3. Build: MSYS2 UCRT64 bash, `CC=clang CXX=clang++ scripts/build-incremental.sh` (stop any running `codebase-memory-mcp.exe` first; libstdc++ duplicate-section warnings are benign)
4. Reindex: `cli delete_project --project navdev-full`, then `& '.\calnav specifics\indexeer NAVDEV-FULL.ps1'`
5. Regression gate: parse_partial_count must stay ≤ 13; nodes/edges may only grow for explainable reasons

**Todo list (implement in order, verify after each):**

1. **Object identity QNs** — give every NAV object a stable qualified name of the form
   `Kind ID Name` (e.g. `Codeunit 80 Sales-Post`) so Functions/Triggers nest under it.
   Implement a `cbm_calnav_qn_name` style helper in the calnav language spec.
2. **Object nodes as Class** — emit Table/Form/Report/Codeunit/Dataport/XMLport objects as
   Class-like definition nodes containing their members.
3. **Triggers as Functions** — extract `trigger_value` bodies (OnRun, OnValidate,
   OnAfterGetRecord, field/control triggers) as Function/Method nodes with the containing
   object as parent.
4. **Event declarations** — extract `event_declaration` nodes as functions (they carry
   negative internal IDs, already parsed by the grammar).
5. **CALLS edges** — extract `call_expression` into CALLS edges: intra-object procedure
   calls, plus cross-object patterns (`CODEUNIT.RUN(...)`, `MyCodeunitVar.SomeProc(...)`,
   `RecordVar.FieldTrigger` style where resolvable via VAR declarations).
6. **Imports/usages** — map VAR record/codeunit/page variable declarations and
   `TableRelation=` properties to IMPORTS/USAGE edges between objects.
7. **Latin-1 transcode** — add a byte transcode (Latin-1 → UTF-8) fallback for files that
   fail UTF-8 validation, fixing `Form/78593.txt` and `Form/11018361.txt`
   (parse_partial 13 → 11).
8. **Entry points** — flag OnRun triggers, job-queue codeunits and similar as entry points
   so `get_architecture` surfaces them.
9. **(Optional) MenuSuite** — currently excluded by decision; only revisit if navigation
   edges from MENUNODES become valuable (would clear the remaining 10 parse_partials).
10. **(Optional) Table/5079** — pathological `InitValue=[...punctuation...]`; special-case
    in grammar only if a clean rule exists.

**Constraints:**
- Keep changes minimal and traceable; verify after every extractor change (steps 1–5 of the workflow).
- Don't change file formats or schema semantics without documenting migration impact.
- MenuSuite objects stay excluded unless todo 9 is explicitly picked up.
- Use the incremental build scripts only — no ad-hoc build commands.

Start with todo 1 and report the node/edge delta after each reindex.

---

## Background notes (not part of the prompt)

- Todos 1–8 correspond to the C-side work that was prototyped and then reverted on
  31-08-2026 when scope was narrowed to grammar-only. The prototype touched:
  `internal/cbm/{cbm,extract_calls,extract_defs,extract_imports,extract_unified,helpers,lang_specs}.c`
  and `helpers.h`. That code is gone (git checkout) — reimplement fresh against the
  current grammar's node types (`internal/cbm/vendored/grammars/calnav/node-types.json`).
- Grammar node types of interest: `object_declaration`, `procedure`, `trigger_value`,
  `event_declaration`, `call_expression`, `var_section`, `variable_declaration`,
  `property` (TableRelation / SourceTable).
- Regression baseline lives in `CALNAV-status-update-2026-08-31.md`.
