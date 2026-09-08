$ErrorActionPreference = 'Stop'
Set-ScriptLocation
$Location = Get-Location
$exe = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"

$ProjectName = "test-calnav2"
$ProjectFolder = (Resolve-Path (Join-Path $Location '.\test-calnav')).Path
function Invoke-CbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    $ArgsFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $ArgsFile -Value $Payload -Encoding utf8NoBOM -NoNewline
        Write-Host "Invoking codebase-memory-mcp.exe with command '$Command' and payload: $Payload" -ForegroundColor Yellow
        & $Exe cli --json $Command --args-file $ArgsFile
    }
    finally {
        Remove-Item -Path $ArgsFile -ErrorAction SilentlyContinue
    }
}

Write-Host "Reindexing '$ProjectName' from '$ProjectFolder'..." -ForegroundColor Cyan

$Payload = '{"repo_path":"' + ($ProjectFolder -replace '\\', '\\\\') + '", "name":"' + $ProjectName + '"}'
$Payload | ConvertFrom-Json
$Json = &Invoke-CbmJson -Command 'index_repository' -Payload $Payload 2>$NULL 
$Result = $($Json | ConvertFrom-Json).StructuredContent
Write-Host " Indexer result: " -ForegroundColor Green
$result.project
$result.status