Set-ScriptLocation
& .\SetupMCPEnvironment.ps1
$projects = Get-Projects
foreach ($pproject in $projects) {
    if ( $(read-host "Wil je project '$($pproject.name)' bekijken? (j/n)") -eq 'j') {
        $projectName = $pproject.name
        break
    }   
} 
## Create Hash tabel with results for each aspect:
$aspectResults = @{}
$aspects = @("overview", "structure", "dependencies", "languages", "file_tree", "graph_schema", "call_graph", "data_flow",
    "control_flow", "dependencies", "metrics", "routes", "packages", "entry_points", "hotspots", "boundaries", "layers", "clusters", "cycles")
foreach ($aspect in $aspects) {
    Write-Host "`nOphalen van aspect '$aspect' voor $projectName..." -ForegroundColor Cyan
    $JsonReceived = Get-MCPProjectInfo -ProjectName $projectName -Aspects $aspect 
   
    if ($Jsonreceived -and $Jsonreceived.PSObject.Properties.Match("error").Count -gt 0) {
        Write-Host "Aspect '$aspect' geeft fout: $($Jsonreceived.error)" -ForegroundColor Red
        $Jsonreceived = $Jsonreceived.error
    }
    else {
        $Jsonreceived = $Jsonreceived.text
        Write-Host "Aspect '$aspect' ophalen OK." -ForegroundColor Green
    }
    
    $store = $true
    if ($Jsonreceived.StartsWith('Unknown aspect')) {
        Write-Host "Aspect '$aspect' is onbekend." -ForegroundColor Yellow
        $store = $false
    }
    else {
        ## check last $Jsonreceived is equal to earlier received $Jsonreceived
        foreach ($receivedAspect in $aspectResults.Keys) {
            if ($receivedAspect -ne $aspect) {
                if ($aspectResults[$receivedAspect] -eq $Jsonreceived) {
                    Write-Host "Aspect '$aspect' geeft zelfde resultaat als eerder ontvangen aspect '$receivedAspect'." -ForegroundColor Yellow
                    $store = $false
                }
            }
        }     
    } 
    if ($store) {
        $aspectResults[$aspect] = $Jsonreceived
    }
}

$aspectResults
