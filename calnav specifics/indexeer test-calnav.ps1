
$ProjectName = "test-calnav"
$projectfolder = '.\calnav specifics\test-calnav'
$codebaseMemoryexeFilename = ".\build\c\codebase-memory-mcp.exe"
$mcpCommand = "cli --json index_repository "
$DaemonStatus = & $codebaseMemoryexeFilename daemon status
if ($DaemonStatus -match "daemon: not running") {
    Write-Host "Starting the MCP daemon..."
    & $codebaseMemoryexeFilename daemon start
    ##& $codebaseMemoryexeFilename daemon stop
} else {
    Write-Host "MCP daemon is already running."
    $DaemonStatus
}
$projectfolder = (Resolve-Path $projectfolder).Path
$ProjectFolder = $projectfolder -replace "\\", "\\"  # Escape backslashes for JSON
##Get-ChildItem -Path $projectfolder -Recurse | Select-Object FullName, Length, LastWriteTime | Sort-Object LastWriteTime -Descending | Format-Table -AutoSize
$JsonPayload = '{"repo_path":"' + $($ProjectFolder) + '", "name":"' + $($ProjectName) + '"}'

Write-Host "Reindexing '$ProjectName' from '$ProjectFolder'..." -ForegroundColor Cyan
$Json = & $codebaseMemoryexeFilename $mcpCommand $JsonPayload
$Json
