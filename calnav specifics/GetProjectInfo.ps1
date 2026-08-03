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


$JSON = & $codebaseMemoryexeFilename cli --json get_architecture '{"project":"test-calnav","aspects":["all"]}' | Where-Object { $_ -match '^\{' }
$($Json | convertFrom-JSON).structuredContent.text 

