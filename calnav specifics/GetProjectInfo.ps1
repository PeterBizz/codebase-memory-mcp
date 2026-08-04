$codebaseMemoryexeFilename = ".\build\c\codebase-memory-mcp.exe"
$projectName = "test-calnav"


## Step 1 : Fetch the project details > 

Write-Host "`nOphalen van info  voor $projectName..." -ForegroundColor Cyan
$archJson = & $codebaseMemoryexeFilename cli --json get_architecture --project "$projectName" | Where-Object { $_ -match '^\{' }
if (-not [string]::IsNullOrEmpty($archJson)) {
    try {
        $archData = $(ConvertFrom-Json $archJson).structuredContent
        $archData.text
        Write-Host "=== Gebruikte talen in de index voor '$projectName' ===" -ForegroundColor Green
            
        $targetData = $archData.results ? $archData.results : $archData

        if ($targetData.languages) {
            # Toon de talenmatrix netjes onder elkaar
            $targetData.languages | Format-List | Out-String | Write-Host -ForegroundColor White
        }
        else {
            $targetData | Format-List | Out-String | Write-Host
        }
    }
    catch {
        Write-Host "Kon architectuur-JSON niet verwerken." -ForegroundColor Red
    }
}
else {
    Write-Host "Kon taalgegevens niet valideren via get_architecture." -ForegroundColor Red
}
$projectName 
$requestJson  = '{"project":"'+ $projectName +'","aspects":["all"]}'
$JSON = $requestJson |& $codebaseMemoryexeFilename cli --json get_architecture | Where-Object { $_ -match '^\{' }
$($Json | convertFrom-JSON).structuredContent.text 

& $codebaseMemoryexeFilename cli --json get_architecture --project $projectName --aspects all
& $codebaseMemoryexeFilename cli --json get_architecture --project $projectName --aspects languages
## Create Hash tabel with results for each aspect:
$aspectResults = @{}
$aspects = @("overview", "structure", "dependencies","languages", "file_tree", "graph_schema", "call_graph", "data_flow",
             "control_flow", "dependencies", "metrics", "routes", "packages", "entry_points", "hotspots", "boundaries", "layers", "clusters", "cycles")
foreach ($aspect in $aspects) {
    Write-Host "`nOphalen van aspect '$aspect' voor $projectName..." -ForegroundColor Cyan
    ## $requestJson  = '{"project":"'+ $projectName +'","aspects":["'+ $aspect +'"]}'
    ##$JSON = $requestJson |& $codebaseMemoryexeFilename cli --json get_architecture | Where-Object { $_ -match '^\{' }
    $Json = & $codebaseMemoryexeFilename cli --json get_architecture --project $projectName --aspects $aspect 2>$null | Where-Object { $_ -match '^\{' }
    $Jsonreceived = $($Json | convertFrom-JSON).structuredContent.text 
    $aspectResults[$aspect] = $Jsonreceived
    ## check last $Jsonreceived is equal to earlier received $Jsonreceived
    foreach ($receivedAspect in $aspectResults.Keys) {
        if ($receivedAspect -ne $aspect) {
            if ($aspectResults[$receivedAspect] -eq $Jsonreceived) {
                Write-Host "Aspect '$aspect' geeft zelfde resultaat als eerder ontvangen aspect '$receivedAspect'." -ForegroundColor Yellow
            }
        }
    }
    if ($aspectResults[$aspect] -eq $Jsonreceived) {
        Write-Host "Aspect '$aspect' succesvol opgehaald en gevalideerd." -ForegroundColor Green
    }
    else {
        Write-Host "Aspect '$aspect' ophalen of valideren mislukt." -ForegroundColor Red
    }
    read-host "Druk op Enter om door te gaan naar het volgende aspect..."
}

 

