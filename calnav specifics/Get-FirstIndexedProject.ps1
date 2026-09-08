param(
    [string]$Project,
    [string]$Binary = (Join-Path $PSScriptRoot '..\build\c\codebase-memory-mcp.exe')
)

if (-not (Test-Path $Binary)) 
  { throw "Binary not found: $Binary" }

if (-not $Project) {
    Write-Host "Indexed projects:" -ForegroundColor Cyan
    $json = & $Binary cli --json list_projects 2>$null | Where-Object { $_ -match '^\s*\{' } | Out-String
    # --json returns an MCP envelope: {"content":[{"type":"text","text":"<payload-json>"}]}
    # The payload is a JSON *string* inside content[0].text, so parse twice.
    $envelope = $json | ConvertFrom-Json
    $projects = ($envelope.content[0].text | ConvertFrom-Json).projects
    Write-Host "Querying first project: $($projects[0].name), $($projects[0].root_path)`n" -ForegroundColor Yellow
}

$Project = '.\test-calnav'

# Request the 'languages' aspect explicitly, however it will only show nodes and edges count. 
#$org =$true
$org = $false
if ($org ) {
    $arch = & $Binary cli get_architecture --json --project $($Project) --aspects languages 
    $arch = & $Binary cli get_architecture --json --payload $Payload
    & $Binary cli get_architecture --help
    & $Binary cli get_architecture --json --args-file $ArgsFile
    $repoSummary = [pscustomobject](($arch -replace ':\s*', '=') | ConvertFrom-StringData)
    $repoSummary
}
else {   
    Set-ScriptLocation
    . .\SetupMCPEnvironment.ps1
    $aspects = 'languages'
    $aspects = 'structure'
    $PayloadObject = [pscustomobject]@{
        project = $Project
        aspects = @($Aspects)
    }
    $Payload = $PayloadObject | ConvertTo-Json -Depth 5 -Compress
    $Json = Invoke-MCPCbmJson -Command 'get_architecture' -Payload $Payload -outfile .\testoutfile.txt
    $Envelope = $Json | ConvertFrom-Json
    $Envelope.content[0].text
}








