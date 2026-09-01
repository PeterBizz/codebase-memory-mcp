# CALNAV integration — status update (31-08-2026)

Supplement to `CALNAV-status.md` (24-07-2026 setup guide). This document records the
grammar-improvement round completed on 31-08-2026 and the verified baseline.

## Summary

The tree-sitter-cal grammar was extended to cover real-world NAV C/AL export syntax found
in the `NAVDev/AllFobDev` corpus (7,683 files). Scope was deliberately limited to
**grammar-only changes**: no C extractor code in codebase-memory-mcp was modified.
All previously experimental C-side edits were reverted to stock.

Result: parse_partial files dropped from **1,408 → 13** (0.17% of corpus).

## Verified baseline (clean reindex, 31-08-2026)

| Metric | Value |
|---|---|
| Project | `navdev-full` |
| Source | `NAVDev/AllFobDev` (7,683 files) |
| Nodes | 37,660 |
| Edges | 107,267 |
| skipped_count | 0 |
| parse_partial_count | **13** |
| Index time | ~88 s |

### Residual parse_partial files (13)

| Files | Cause | Status |
|---|---|---|
| 10× `MenuSuite/*.txt` | MENUNODES section only partially supported | **Excluded by decision** — MenuSuite objects are skipped per user instruction |
| `Form/78593.txt` (line 740), `Form/11018361.txt` (line 551) | Invalid encoding byte (Latin-1) inside an identifier | Needs C-side transcode → out of grammar-only scope |
| `Table/5079.txt` | Pathological `InitValue=[!"#$%&'()+,-./:;<=>[\]]^_\`{|}~]` value | Grammar-level edge case, not worth special-casing |

## Grammar fixes delivered (tree-sitter-cal/grammar.js)

- MENUITEMS nested blocks
- Negative event IDs (`internal_id: /-?\d+/`)
- Dataport `FIELDS` inside dataitem
- Multiline SIFT bracket values
- Slash property keys (`Format/Evaluate`)
- Non-empty EVENTS entries
- MENUNODES section (partial)
- Anonymous procedures (`PROCEDURE @id();`)
- `Binary[n]` type
- `infinite` coordinates
- `TableRelation=TableN.Field` suffix
- Depth-3 nested brace comments
- Bracketed object headers (`OBJECT [Form …]`)
- Stray `;` in VAR sections
- Non-ASCII identifiers

Corpus tests: **76/76 pass** (`npx tree-sitter test`).

## Repository state

### tree-sitter-cal
- `grammar.js` — all fixes above (modified, keep)
- `src/parser.c`, `src/node-types.json` — regenerated artifacts

### codebase-memory-mcp
- `internal/cbm/vendored/grammars/calnav/{parser.c, tree_sitter/parser.h, node-types.json}` — synced from tree-sitter-cal (modified, keep)
- `internal/cbm/*.c|h` extractor sources — **reverted to stock** (`git checkout --`); the
  abandoned experimental work covered trigger/event function extraction, call_expression
  CALLS edges, object-identity QNs, Class nodes, calnav imports, Latin-1 transcode and
  entry-point detection — see `CALNAV-next-improvements-prompt.md`

## Reproducible workflow (proven)

```powershell
# 1. Regenerate parser (from tree-sitter-cal)
npx tree-sitter generate; npx tree-sitter test

# 2. Sync into MCP vendored tree
.\scripts\sync-calnav-to-mcp.ps1

# 3. Rebuild MCP (MSYS2 UCRT64 + clang; stop daemon/processes first)
#    from codebase-memory-mcp root:
$env:MSYSTEM='UCRT64'; $env:CHERE_INVOKING='1'
& 'C:\msys64\usr\bin\bash.exe' -lc 'source /etc/profile; cd /c/Users/peter/Source/Repos/Everest/codebase-memory-mcp; CC=clang CXX=clang++ scripts/build-incremental.sh'

# 4. Clean reindex + verify
& '.\build\c\codebase-memory-mcp.exe' cli delete_project --project navdev-full
& '.\calnav specifics\indexeer NAVDEV-FULL.ps1'
# expect: parse_partial_count=13, nodes=37660, edges=107267
```

## Risks / notes

- Grammar-only scope means the knowledge graph still lacks C/AL-aware semantics
  (triggers as functions, cross-object CALLS, object identity QNs). Parse coverage is
  excellent; extraction depth is generic.
- The duplicate-section libstdc++ warnings during the incremental build are benign.
- Node/edge counts are the regression criterion for future parser changes:
  any deviation from 37,660 / 107,267 (with unchanged corpus) needs investigation.
