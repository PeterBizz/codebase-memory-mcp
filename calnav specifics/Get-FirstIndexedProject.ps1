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

# Request the 'languages' aspect explicitly, however it will only show nodes and edges count. 
$org =$true
if ($org ) {
    $arch = & $Binary cli get_architecture --project $($projects[0].name) --aspects languages 2>$null
    $repoSummary = [pscustomobject](($arch -replace ':\s*', '=') | ConvertFrom-StringData)
    $repoSummary
}
else {   
    Set-ScriptLocation
     $Payload = '{"project":"' + $ProjectName + '","aspect":"' + $Aspects + '"}'
    $Json = Invoke-MCPCbmJson -Command 'get_architecture' -Payload $Payload
    $($Json | ConvertFrom-Json).StructuredContent    
}
$repoSummary = [pscustomobject](($arch -replace ':\s*', '=') | ConvertFrom-StringData)
$repoSummary







