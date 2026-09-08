## Script to run some basis MCP queries and dump the result to JSON files in the output folder. 
## This is useful for testing and debugging MCP queries.


param(
    [string]$Project = 'navdev-full'
)
Set-ScriptLocation; 
$RepoRoot = Resolve-Path (Join-Path $(Get-Location).ProviderPath "..\..")
$Exe = Join-Path $RepoRoot 'build\c\codebase-memory-mcp.exe'
if (-not (Test-Path $Exe)) { throw "codebase-memory-mcp.exe not found at expected paths ($Exe)" }

$OutDir = Join-Path $(Get-Location).ProviderPath '\output'
New-Item -Path $OutDir -ItemType Directory -Force | Out-Null

function Run-JsonCli($command, $argsObj, $outName) {
    $tmp = [System.IO.Path]::GetTempFileName()
    $argsObj | ConvertTo-Json -Compress | Set-Content -Path $tmp -Encoding UTF8
    $outPath = Join-Path $OutDir ($outName + '.json')
    & $Exe cli --json $command --args-file $tmp > $outPath 2>&1
    # strip non-JSON log prefixes by keeping the last line that starts with '{' or '['
    try {
        $raw = Get-Content -Raw -Path $outPath -ErrorAction Stop
        $lines = $raw -split "\r?\n"
        $jsonLine = $lines | Where-Object { $_ -match '^\s*[\{\[]' } | Select-Object -Last 1
        if ($jsonLine) { Set-Content -Path $outPath -Value $jsonLine -Encoding UTF8 }
    } catch { }
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

Run-JsonCli 'list_projects' @{ } 'list_projects'
Run-JsonCli 'get_graph_schema' @{ project = $Project } 'graph_schema'

$cypherCount = "MATCH ()-[r:CALLS]->(t) WHERE NOT t:Function RETURN count(r) as calls_without_function"
$cypherSample = "MATCH (s)-[r:CALLS]->(t) WHERE NOT t:Function RETURN s, r, t LIMIT 200"
Run-JsonCli 'query_graph' @{ project = $Project; query = $cypherCount } 'calls_without_function_count'
Run-JsonCli 'query_graph' @{ project = $Project; query = $cypherSample } 'calls_without_function_sample'

Write-Host "Wrote outputs to: $OutDir"
