Set-ScriptLocation  
$location = Get-Location
$codebaseMemoryexeFilename = Join-Path $location "..\build\c\codebase-memory-mcp.exe" 
& $codebaseMemoryexeFilename daemon start