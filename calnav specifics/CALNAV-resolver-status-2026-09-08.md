# CALNAV Resolver Status — 2026-09-08

## Scope
Improve receiver-based table method resolution so `Record` variable calls (e.g., `AccountingSetup.GET`) resolve to typed table targets instead of unresolved suffix-only fallbacks.

## Baseline (navdev-full)
- Total `CALLS` edges with `.GET` callee: **7,277**
- `.GET` calls targeting `Function`: **5,360**
- `.GET` calls targeting non-`Function`: **1,917**
- `.GET` strategy distribution: **100% `callee_suffix`** in current graph
- Unresolved table-like calls (GET/FIND/SET*/INSERT/MODIFY/DELETE/RENAME/etc. heuristic): **1,976**

## Confirmed behavior sample
- `Codeunit/11000004.txt` contains `AccountingSetup.GET;`
- `AccountingSetup` is declared as `Record 98`
- Current call edge remains unresolved (`strategy=callee_suffix`, `candidates=0`), so it lands in non-`Function` sample results.

## Method Matrix (Phase 1)
Receiver typing applies to:
- Read: `GET`, `FIND`, `FINDFIRST`, `FINDLAST`, `FINDSET`, `NEXT`, `ISEMPTY`, `COUNT`, `CALCFIELDS`
- Filter/navigation: `SETRANGE`, `SETFILTER`, `SETCURRENTKEY`, `ASCENDING`, `MARK`, `MARKEDONLY`, `RESET`
- Write: `INSERT`, `MODIFY`, `DELETE`, `DELETEALL`, `RENAME`, `VALIDATE`, `TRANSFERFIELDS`
- Transaction/locking: `LOCKTABLE`

## Phase 2 backlog
- Implicit `Rec` binding rules
- `WITH` scope stack resolution
- Variable shadowing precedence and nested scope handling
- Temporary record metadata handling (`temporary=true` annotation)
- Confidence tiering for ambiguous receiver scopes
- Corpus extensions for Rec/WITH/shadow/temp regressions

## Implementation completed (2026-09-08)
- ✅ Rolled back prior 3-file experimental resolver patch first
- ✅ Added AST-based CALNAV `Record` typing in `extract_type_assigns` (`var_declaration` -> `type_reference` -> `object_ref_type`)
- ✅ Added resolver hinting in both sequential and parallel call passes using `result->type_assigns`
- ✅ Hint behavior:
	- prefer `Table.<id>.<Method>` (`strategy=calnav_record_method`) when table function exists
	- fallback to `Table.<id>` Module (`strategy=calnav_record_module`) for standard record methods like `GET`

## Validation results (clean reindex)
- Build: `scripts/build-incremental.sh` via MSYS2 UCRT64 + `CC=clang CXX=clang++` — **success**
- Reindex: `navdev-full` (NAVDev/AllFobDev) — **success**
	- `parse_partial_count`: **0**
	- `nodes`: **37,713**
	- `edges`: **133,519**

## Post-change metrics
- Total `.GET` `CALLS` edges: **10,067**
- `.GET` with `strategy=callee_suffix AND candidates=0`: **2,545**
- `.GET` strategy distribution:
	- `calnav_record_module`: **7,522**
	- `callee_suffix`: **2,545**
- Confirmed sample fix:
	- `Codeunit/11000004.txt` + `AccountingSetup.GET`
	- now resolves to `navdev-full.Table.98` with `strategy=calnav_record_module`, `confidence=0.88`, `candidates=1`

## Remaining follow-up
- Phase 2 still pending: implicit `Rec`, `WITH` scope stack, shadowing precedence, and temporary-record semantics.
