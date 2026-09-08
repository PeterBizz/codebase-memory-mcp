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

## Current status
- ✅ Baseline unresolved GET metrics
- ✅ Method matrix acceptance drafted
- 🚧 Design table-method target resolution (in progress)
- ⏭️ Next: map typed `Record` declarations in resolver pipeline and define target selection contract.
