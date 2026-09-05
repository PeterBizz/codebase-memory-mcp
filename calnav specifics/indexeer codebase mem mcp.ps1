$ErrorActionPreference = 'Stop'
Set-ScriptLocation
$Location = Get-Location
$exe = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"
$ProjectName = "codebase-memory-mcp"
$ProjectFolder = (Resolve-Path (Join-Path $Location '..\..\codebase-memory-mcp')).Path

function Invoke-CbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    $ArgsFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $ArgsFile -Value $Payload -Encoding utf8NoBOM -NoNewline
        & $Exe cli --json $Command --args-file $ArgsFile
    }
    finally {
        Remove-Item -Path $ArgsFile -ErrorAction SilentlyContinue
    }
}


Write-Host "Reindexing '$ProjectName' from '$ProjectFolder'..." -ForegroundColor Cyan

$Payload = '{"repo_path":"' + ($ProjectFolder -replace '\\', '\\\\') + '","name":"' + $ProjectName + '"}'
$Json = Invoke-CbmJson -Command 'index_repository' -Payload $Payload
$Json
