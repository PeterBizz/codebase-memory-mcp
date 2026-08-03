$codebaseMemoryexeFilename = ".\build\c\codebase-memory-mcp.exe"

$codebaseMemoryexeFilename daemon start
##$projectName = "test-calnav"

$json = & ".\build\c\codebase-memory-mcp.exe" cli --json list_projects |
    Where-Object { $_ -match '^\{' }

$projects = $($json | ConvertFrom-Json ).structuredContent.projects
    
# 4. Voer de lus uit over de daadwerkelijke array
foreach ($pproject in $projects) {
    # Dit werkt nu gegarandeerd en toont de pure namen
    $pproject.name
    $pproject.root_path
    if ( read-host "Wil je dit project verwijderen? (j/n)" -eq 'j') {
        $projectName = $pproject.name
        Write-Host "(Index voor Project $projectName aan het verwijderen" -ForegroundColor Red
        & $codebaseMemoryexeFilename cli delete_project --project "$projectName"
    }    
}
