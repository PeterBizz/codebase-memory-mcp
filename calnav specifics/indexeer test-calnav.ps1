$ErrorActionPreference = 'Stop'

$Exe = ".\build\c\codebase-memory-mcp.exe"
$ProjectName = "test-calnav"
$ProjectFolder = (Resolve-Path '.\calnav specifics\test-calnav').Path

function Invoke-CbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    & $Exe cli --json $Command $Payload
}

Write-Host "Reindexing '$ProjectName' from '$ProjectFolder'..." -ForegroundColor Cyan

$Payload = '{"repo_path":"' + ($ProjectFolder -replace '\\', '\\\\') + '","name":"' + $ProjectName + '"}'
$Json = Invoke-CbmJson -Command 'index_repository' -Payload $Payload
$Json
