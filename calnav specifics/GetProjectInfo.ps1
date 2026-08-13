$codebaseMemoryexeFilename = ".\build\c\codebase-memory-mcp.exe"
$projectName = "test-calnav"

$json = & ".\build\c\codebase-memory-mcp.exe" cli --json list_projects |
    Where-Object { $_ -match '^\{' }

$projects = $($json | ConvertFrom-Json ).structuredContent.projects
    
# 4. Voer de lus uit over de daadwerkelijke array
foreach ($pproject in $projects) {
    ## VRaag of geberuiker dit project wil bekijken, indien ja dan $ProjectName zetten en verder gaan
    if ( $(read-host "Wil je project '$($pproject.name)' bekijken? (j/n)") -eq 'j') {
        $projectName = $pproject.name
        break
    }   
} 
## Create Hash tabel with results for each aspect:
$aspectResults = @{}
$aspects = @("overview", "structure", "dependencies","languages", "file_tree", "graph_schema", "call_graph", "data_flow",
             "control_flow", "dependencies", "metrics", "routes", "packages", "entry_points", "hotspots", "boundaries", "layers", "clusters", "cycles")
foreach ($aspect in $aspects) {
    Write-Host "`nOphalen van aspect '$aspect' voor $projectName..." -ForegroundColor Cyan
   
    $Json = & $codebaseMemoryexeFilename cli --json get_architecture --project $projectName --aspects $aspect 2>$null | Where-Object { $_ -match '^\{' }
   
    $Jsonreceived = $($Json | convertFrom-JSON).structuredContent
    if ($Jsonreceived -and $Jsonreceived.PSObject.Properties.Match("error").Count -gt 0) {
        Write-Host "Aspect '$aspect' geeft fout: $($Jsonreceived.error)" -ForegroundColor Red
        $Jsonreceived = $Jsonreceived.error
    }
    else {
        $Jsonreceived = $Jsonreceived.text
        Write-Host "Aspect '$aspect' ophalen OK." -ForegroundColor Green
    }
    $aspectResults[$aspect] = $Jsonreceived
    ## check last $Jsonreceived is equal to earlier received $Jsonreceived
    foreach ($receivedAspect in $aspectResults.Keys) {
        if ($receivedAspect -ne $aspect) {
            if ($aspectResults[$receivedAspect] -eq $Jsonreceived) {
                Write-Host "Aspect '$aspect' geeft zelfde resultaat als eerder ontvangen aspect '$receivedAspect'." -ForegroundColor Yellow
            }
        }
    }        
}
$aspectResults | Format-List | Out-String | Write-Host -ForegroundColor White

