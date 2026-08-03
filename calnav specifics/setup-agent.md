Je bent mijn setup-agent op Windows. Doel: mijn lokale ontwikkelomgeving werkend krijgen voor codebase-memory-mcp met MSYS2 UCRT64 + clang, inclusief incrementele build en VS Code MCP-validatie.

Werkregels:
1) Voer alles stapsgewijs uit en toon na elke stap:
   - commando
   - korte output-samenvatting
   - pass/fail
2) Stop bij fouten niet direct; probeer 1 alternatief en leg uit wat je doet.
3) Gebruik GEEN WSL. Gebruik MSYS2 UCRT64.
4) Eindig met een checklist “klaar/niet klaar”.

Context:
- OS: Windows
- Vereist: VS Code, Git, Python (Windows), MSYS2
- Repo pad: C:\Users\<USER>\Source\Repos\Everest\codebase-memory-mcp

Taken:

A. MSYS2 UCRT64 basis controleren
- Controleer of C:\msys64\usr\bin\bash.exe bestaat.
- Run in MSYS2:
  pacman -Syu
- Installeer benodigde pakketten:
  pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-zlib make
  pacman -S --needed mingw-w64-ucrt-x86_64-python mingw-w64-ucrt-x86_64-pkgconf
  pacman -S --needed mingw-w64-ucrt-x86_64-clang

B. Verificatie toolchain
Controleer versies:
- make --version
- python --version
- pkg-config --version
- clang --version
- clang++ --version
Als iets ontbreekt: fixen en opnieuw controleren.

C. VS Code terminal profiel (MSYS2 UCRT64)
Controleer/zet in VS Code settings:
- terminal.integrated.profiles.windows -> MSYS2 UCRT64
  path: C:\msys64\usr\bin\bash.exe
  args: -li
  env:
    MSYSTEM=UCRT64
    CHERE_INVOKING=1
- terminal.integrated.defaultProfile.windows = MSYS2 UCRT64

D. Build validatie
In repo root:
1) Clean/proefbuild met clang:
   CC=clang CXX=clang++ scripts/build.sh
2) Incrementele build:
   CC=clang CXX=clang++ scripts/build-incremental.sh
Leg kort uit dat incrementeel: gewijzigde objecten + relink doet.

E. MCP/CLI validatie
Voer uit:
1) index_repository op:
   C:\Users\<USER>\Source\Repos\Everest\codebase-memory-mcp\private\test-calnav
2) list_projects
3) get_architecture op het nieuwe project
Rapporteer:
- projectnaam
- nodes/edges
- parse_partial/skipped indien aanwezig

F. Oplevering
Geef op het einde:
1) Definitieve “runbook” met exacte commando’s (copy/paste)
2) Bekende valkuilen + fixes (kort)
3) Statusmatrix:
   - MSYS2 UCRT64
   - clang toolchain
   - build.sh
   - build-incremental.sh
   - MCP index/search