# CALNAV integratie – huidige status (24-07-2026)

## Doel en huidige status
Deze omgeving is opgezet om een nieuwe taal (`CALNAV`) toe te voegen aan `codebase-memory-mcp` met een eerste, werkende tree-sitter parser-integratie.

Huidige status:
- CALNAV is toegevoegd aan de taal-registratie.
- `.txt` wordt als CALNAV behandeld.
- Een eerste (dummy) tree-sitter grammar is gekoppeld en compileert mee.
- Indexeren en architectuuroverzicht werken op de testset in `private/test-calnav`.

---

## Omgeving die is opgebouwd (en zo opnieuw opzetten in een nieuw project)

### 0) Context van de opbouw (lessons learned uit de log)
Na installatie van VS Code, Git en Python op Windows bleek voor dit project alsnog een volledige **MSYS2 UCRT64** toolchain nodig.

Belangrijkste observaties uit de opbouwlog:
- `gcc` en `make` waren initieel niet beschikbaar in UCRT64 (`command not found`).
- Een algemene `pacman -Syu` update alleen was niet voldoende; compilers/build-tools moesten expliciet worden geïnstalleerd.
- `python` en `pkg-config` waren ook initieel afwezig in UCRT64 en zijn later toegevoegd.
- Builden met GCC 16.1.0 gaf meerdere `internal compiler error: Segmentation fault` fouten.
- Overstap naar `clang/clang++` in UCRT64 loste dit op en leverde stabiele builds op.

Daarom is de aanbevolen standaard voor nieuwe projecten: **MSYS2 UCRT64 + clang**.

### 1) Vereiste terminal/runtime
Gebruik **MSYS2 UCRT64** als buildomgeving (niet standaard PowerShell-omgeving zonder MSYS2 init).

Benodigde terminalconfiguratie in VS Code (globaal profiel):

```jsonc
"terminal.integrated.profiles.windows": {
  "MSYS2 UCRT64": {
    "path": "C:\\msys64\\usr\\bin\\bash.exe",
    "args": ["-li"],
    "env": {
      "MSYSTEM": "UCRT64",
      "CHERE_INVOKING": "1"
    }
  }
},
"terminal.integrated.defaultProfile.windows": "MSYS2 UCRT64"
```

Waarom dit nodig is:
- De compiler (`clang`) wordt uit UCRT64 verwacht.
- Zonder `MSYSTEM=UCRT64` + profile-init (`/etc/profile`) ontbreekt vaak `/ucrt64/bin` in `PATH`.

### 1a) Minimale pakketset in MSYS2 UCRT64 (bewezen werkend)
Volg in nieuwe projecten minimaal deze stappen:

1. Update package databases en basispakketten:

```bash
pacman -Syu
```

2. Installeer build-basics:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-zlib make
```

3. Installeer Python + pkgconf voor scripts/tooling:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-python mingw-w64-ucrt-x86_64-pkgconf
```

4. Installeer Clang toolchain (aanbevolen default):

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-clang
```

5. Verifieer:

```bash
make --version
python --version
pkg-config --version
clang --version
clang++ --version
```

Opmerking:
- In de opbouwlog is `gcc` wel werkend gekregen, maar buildstabiliteit was beter met `clang`.

### 2) Compiler-instellingen
Gebruik consequent:
- `CC=clang`
- `CXX=clang++`

Voorbeeld (MSYS2 terminal):
```bash
CC=clang CXX=clang++ scripts/build-incremental.sh
```

### 2a) Waarom niet standaard GCC in deze setup
In de log zijn tijdens `scripts/build.sh` met GCC meerdere interne compilerfouten waargenomen (ICE/segfaults in AVX intrinsic headers). Daardoor is `clang` als project-standaard gekozen voor deze Windows UCRT64 omgeving.

### 3) Testprojectstructuur
Voor snelle validatie is een lokale testcase-map gebruikt:
- `calnav specifics/test-calnav/codeunit/50000.txt`
- extra testbestanden onder `calnav specifics/test-calnav/...`

Deze map kan in elk nieuw project 1-op-1 worden nagebouwd als rooktest.

### 4) VS Code-integratie (MCP) – gevalideerde setup
Uit de integratielog blijkt dat de ontwikkelopzet in VS Code succesvol is gevalideerd.

Gevalideerde onderdelen:
- lokale build werkt;
- eigen fork/binary wordt gebruikt;
- VS Code profiel-specifieke MCP-configuratie werkt;
- `codebase-memory-mcp` verschijnt als MCP-server;
- geen afhankelijkheid van een officiële release-installatie.

Praktische implicatie voor nieuwe projecten:
- je kunt lokaal bouwen en die binary direct koppelen in je VS Code-profielconfig;
- je kunt taalwijzigingen (zoals CALNAV) meteen via MCP-tools in Copilot Chat valideren zonder aparte release pipeline.

Aanbevolen eerste MCP-validatie in een nieuw project:
1. `index_repository` op de volledige repo.
2. Daarna `search_code` op een bekend trefwoord.
3. Resultaten vergelijken met verwachting (nulmeting vóór taaltoevoeging).

Nulmeting uit deze omgeving (volgens log):
- Project: `C-Users-peter-Source-Repos-Everest-codebase-memory-mcp`
- Nodes: `20,828`
- Edges: `109,907`
- Parse partial: `64` bestanden (met o.a. grote ranges in `cli.c` en delen van `mcp.c`)
- Excluded by design: `1` bestand (PNG)

Waarom deze nulmeting belangrijk is:
- hiermee kun je vóór/na taalintegratie aantonen wat het effect is op parserdekking en zoekresultaten.

---

## Buildomgeving en incrementele build

### Probleem dat is opgelost
`scripts/build.sh` deed altijd een clean build (verwijdert build artifacts), daardoor traag bij kleine wijzigingen.

### Oplossing
Nieuw script toegevoegd:
- `scripts/build-incremental.sh`

Eigenschappen:
- Geen clean-stap vooraf.
- Roept `make -f Makefile.cbm cbm` (of `cbm-with-ui`) aan.
- Herbouwt alleen gewijzigde objecten + relink van binary.

Gebruik:
```bash
CC=clang CXX=clang++ scripts/build-incremental.sh
```

PowerShell-equivalent (wanneer je niet in een MSYS2 tab zit):
```powershell
$env:MSYSTEM='UCRT64'; $env:CHERE_INVOKING='1'; & "C:\msys64\usr\bin\bash.exe" -lc 'source /etc/profile; cd /c/Users/peter/Source/Repos/Everest/codebase-memory-mcp; CC=clang CXX=clang++ scripts/build-incremental.sh'
```

Met UI:
```bash
CC=clang CXX=clang++ scripts/build-incremental.sh --with-ui
```

### Verwacht gedrag bij “1 spatie gewijzigd”
Bij wijziging in een bronbestand (bijv. `src/discover/language.c`):
1. Dat bestand/object wordt opnieuw gecompileerd.
2. Daarna volgt relink van `codebase-memory-mcp(.exe)`.

Dat lijkt “veel output”, maar is nog steeds incrementeel correct gedrag.

---

## Samenvatting broncode-aanpassingen voor de eerste parser

### 1) Taalregistratie
- `internal/cbm/cbm.h`
  - `CBM_LANG_CALNAV` toegevoegd aan `CBMLanguage` enum.

### 2) Taaldetectie op extensie + naam
- `src/discover/language.c`
  - Extensie mapping toegevoegd: `.txt -> CBM_LANG_CALNAV`
  - Weergavenaam toegevoegd: `CALNAV`

### 3) Koppeling met language specs
- `internal/cbm/lang_specs.c`
  - `extern const TSLanguage *tree_sitter_calnav(void);`
  - Spec-entry toegevoegd voor `CBM_LANG_CALNAV` met `tree_sitter_calnav` als factory.

### 4) Eerste grammarbestanden (dummy parser)
Toegevoegd onder:
- `internal/cbm/vendored/grammars/calnav/parser.c`
- `internal/cbm/vendored/grammars/calnav/scanner.c`
- `internal/cbm/vendored/grammars/calnav/tree_sitter/parser.h`
- `internal/cbm/vendored/grammars/calnav/LICENSE`

Opmerking:
- Deze eerste parser is een template-gebaseerde start (afgeleid van dotenv-grammatica), bedoeld om de volledige keten (detectie → compile → link → index) werkend te maken.

### 5) Build-shim toegevoegd
- `internal/cbm/grammar_calnav.c`
  - Include van CALNAV parser/scanner, zodat wildcard `grammar_*.c` in `Makefile.cbm` automatisch meeneemt in build.

### 6) Incrementele buildscript toegevoegd
- `scripts/build-incremental.sh`
  - Productiebuild zonder clean.

### 7) CALNAV parser logging
De CALNAV tree-sitter parser logt nu extra detail op debug-niveau.

Inschakelen:
```powershell
$env:CBM_LOG_LEVEL = 'debug'
$env:CBM_LOG_FILE = 'C:\temp\calnav-parser.log'
```

Uitschakelen:
```powershell
$env:CBM_LOG_LEVEL = 'none'
Remove-Item Env:CBM_LOG_FILE -ErrorAction SilentlyContinue
```

Waar komt het logfile terecht:
- als `CBM_LOG_FILE` is gezet, wordt daar exact dat pad gebruikt;
- als `CBM_LOG_FILE` niet is gezet, gaan de logs naar stderr en wordt er geen apart logfile gemaakt.

Tip:
- laat `CBM_LOG_LEVEL` op `debug` staan als je de volledige tree-sitter lex/parse trace wilt zien;
- `info`, `warn` of `error` verminderen de hoeveelheid output zonder de codewijziging terug te draaien.

---

## Validatie-resultaat (samengevat)
Op testproject `calnav specifics/test-calnav`:
- Project succesvol geïndexeerd.
- `get_architecture` toont nodes/edges voor bestanden/modules.
- CALNAV-keten functioneert end-to-end.
- Er zijn `parse_partial` signalen mogelijk door de dummy grammar (verwacht in deze fase).

---

## 2026-09-05 — Calls extraction patch and reindex (validation)

Actie: twee kleine wijzigingen in de extractor om expression-position en CAL `member_access` callees te vangen, vervolgens incremental build + re-index van `navdev-full`.

Resultaat (post-reindex):
- Nodes (sum node labels): **37,706** (was ~37,660) — delta **+46**.
- Edges (sum edge types): **115,604** (was 107,267) — delta **+8,337**.
- `CALLS` edges: **48,431** (was ~14,939) — delta **+33,492**.

Spot-check: `trace_call_path` against `navdev-full.Table.11067889.IsFeatureEnabled` returns **121** callers (examples: `Table.7311.CheckName`, `Form.5703.UpdateEnabled`, `Table.5766.OpenActivityHeader`).

Opmerking: dit matcht de verwachte effecten uit de handoff — veel expression-position member calls zijn nu CALLS edges in plaats van USAGE, en de overall CALLS growth is aanzienlijk.

Aanbeveling: monitor voor false positives op veelvoorkomende procedure-namen en overweeg (optioneel) `call.is_method` suppression for `member_access` if noise appears.

---

## Aanbevolen volgende stap
De omgeving staat nu goed. Voor functionele CALNAV-extractie is de volgende stap:
- de dummy grammar vervangen/uitbreiden met een echte CALNAV/AL-N grammar,
- en daarna gericht node-types (functions/classes/imports/calls) mappen in `lang_specs.c`.

Aanvullend voor nieuwe projecten:
- neem de pakketinstallatievolgorde uit deze notitie over,
- gebruik vanaf dag 1 `CC=clang CXX=clang++`,
- en gebruik standaard `scripts/build-incremental.sh` voor dagelijkse iteratie.
