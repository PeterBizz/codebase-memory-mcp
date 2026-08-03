# Get-CbmLanguages.ps1
# Query codebase-memory-mcp for detected languages of an indexed project.
# Note: the MCP has no tool that lists ALL 158 supported languages —
# that list lives in README.md ("Language Support"). This script returns
# the languages *detected* in an indexed project via get_architecture.
#
# Usage:
#   .\Get-CbmLanguages.ps1                     # lists projects, queries the first one
#   .\Get-CbmLanguages.ps1 -Project <name>     # query a specific project

param(
    [string]$Project,
    [string]$Binary = (Join-Path $PSScriptRoot '..\..\build\c\codebase-memory-mcp.exe')
)

if (-not (Test-Path $Binary)) { throw "Binary not found: $Binary" }

if (-not $Project) {
    Write-Host "Indexed projects:" -ForegroundColor Cyan
    $json = & $Binary cli --json list_projects 2>$null | Where-Object { $_ -match '^\s*\{' } | Out-String
    # --json returns an MCP envelope: {"content":[{"type":"text","text":"<payload-json>"}]}
    # The payload is a JSON *string* inside content[0].text, so parse twice.
    $envelope = $json | ConvertFrom-Json
    $projects = ($envelope.content[0].text | ConvertFrom-Json).projects
    $projects | Format-Table name, root_path, nodes, edges -AutoSize
    $Project = $projects[0].name
    Write-Host "Querying first project: $Project`n" -ForegroundColor Yellow
}

# Request the 'languages' aspect explicitly: the default summary view omits
# the section entirely when no languages were detected (e.g. CAL-only repos).
$arch = & $Binary cli get_architecture --project $Project --aspects languages 2>$null
$langs = $arch | Select-String -Pattern 'languages:' -Context 0, 30
if ($langs) {
    $langs
} else {
    Write-Host "No languages detected in '$Project'." -ForegroundColor Yellow
    Write-Host "(Files in unsupported languages, e.g. CAL, are indexed structurally but not language-tagged.)"
    $arch
}
