.\build\c\codebase-memory-mcp.exe install --dry-run

## echte install, let op dat de exe wordt gekoppieerd naar de locatie C:\Users\peter\.local\bin\codebase-memory-mcp.exe
.\build\c\codebase-memory-mcp.exe install -y  ## Gind fout omdat managed install. 

.\build\c\codebase-memory-mcp.exe install -y --force  ## Gaat ook fout. 

## overstappen naar alleen MCP. 
## dat doen we in mcp.josn ( let op per profiles) 

## MCP Setup is nog leeg :
 C:\Users\peter\AppData\Roaming\Code\User>
Get-Content $env:APPDATA\Code\User\mcp.json

## Indexeren 