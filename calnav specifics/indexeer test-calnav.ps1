
$ProjectName = "test-calnav"
$projectfolder = '.\calnav specifics\test-calnav'
$codebaseMemoryexeFilename = ".\build\c\codebase-memory-mcp.exe"
$mcpCommand = "cli --json index_repository "

$projectfolder = (Resolve-Path $projectfolder).Path
$ProjectFolder = $projectfolder -replace "\\", "\\"  # Escape backslashes for JSON
##Get-ChildItem -Path $projectfolder -Recurse | Select-Object FullName, Length, LastWriteTime | Sort-Object LastWriteTime -Descending | Format-Table -AutoSize
$JsonPayLoad = '{"repo_path":"' + $($ProjectFolder) + '", "name":"' + $($ProjectName) + '"}'

$JsonPayload = '{"repo_path":"C:\\Users\\peter\\Source\\Repos\\Everest\\tree-sitter-cal\\examples", "name":"Exmple-calnav"}'
$Json = $JsonPayLoad | & $codebaseMemoryexeFilename $mcpCommand '{"repo_path":"C:\\Users\\peter\\Source\\Repos\\Everest\\tree-sitter-cal\\examples", "name":"Exmple-calnav"}'

$Json = $JsonPayLoad | & $codebaseMemoryexeFilename $mcpCommand
$Json
