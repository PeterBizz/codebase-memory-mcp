Set-ScriptLocation; 
. .\SetupMCPEnvironment.ps1

Write-Host "=== Ophalen van bekende projecten uit codebase-memory-mcp ===" -ForegroundColor Cyan

$projects = Get-Projects

# --- VANGNET ALS ER GEEN PROJECTEN ZIJN ---
if ($projects.Count -eq 0) {
    Write-Host "`n[i] De database is momenteel leeg of projecten konden niet worden geladen." -ForegroundColor Yellow
    $ans = Read-Host "Wil je nu een nieuwe repository indexeren? (j/n)"
    if ($ans -eq 'j' -or $ans -eq 'y') {
        $repoPath = Read-Host "Voer het absolute pad naar de repository in"
        if (Test-Path $repoPath) {
            Write-Host "Bezig met indexeren via de daemon..." -ForegroundColor Yellow
            ReIndex
            Write-Host "Indexering voltooid!" -ForegroundColor Green
        } else {
            Write-Host "Pad bestaat niet. Script afgebroken." -ForegroundColor Red
        }
    }
    exit 0
}

# --- LOOP DOOR BESTAANDE PROJECTEN ---
foreach ($pproject in $projects) {
    $projectName = $pproject.name
    if ([string]::IsNullOrEmpty($projectName)) { continue } 
    $repoPath = $pproject.root_path

    Write-Host "`n--------------------------------------------------" -ForegroundColor Gray
    Write-Host "Project gevonden: $projectName" -ForegroundColor Magenta
    Write-Host "--------------------------------------------------" -ForegroundColor Gray
    Write-Host "Wat wil je met dit project doen?"
    Write-Host " 1] Full Index (Bestaande index behouden, wijzigingen scannen)"
    Write-Host " 2] Re-Index (Eerst de graaf wissen, daarna volledig schoon opbouwen)"
    Write-Host " 3] Project Verwijderen (Wissen zonder opnieuw te maken)"
    Write-Host " 4] Overslaan / Volgende"
    
    $choice = Read-Host "Maak een keuze (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host "Uitvoeren van Full Index voor $projectName..." -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($repoPath)) { $repoPath = Read-Host "Voer het absolute pad naar de repository in" }
            
            & $codebaseMemoryexeFilename cli index_repository --repo-path "$repoPath"
            Show-LanguageUsage -projectName $projectName
        }
        "2" {
            Write-Host "Project $projectName aan het verwijderen uit de daemon voor schone start..." -ForegroundColor Red
            & $codebaseMemoryexeFilename cli delete_project --project "$projectName"
            
            Write-Host "Volledig schoon opnieuw indexeren..." -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($repoPath)) { $repoPath = Read-Host "Voer het absolute pad naar de repository in" }
            
            & $codebaseMemoryexeFilename cli index_repository --repo-path "$repoPath"
            Show-LanguageUsage -projectName $projectName
        }
        "3" {
            Write-Host "Project $projectName definitief aan het wissen..." -ForegroundColor Red
            Delete-Project -ProjectName $projectName
            Write-Host "Project succesvol verwijderd." -ForegroundColor Green
        }        
        "4" {
            Write-Host "Project $projectName overgeslagen." -ForegroundColor Gray
        }
        default {
            Write-Host "Ongeldige keuze. Project overgeslagen." -ForegroundColor Yellow
        }
    }
}
Write-Host "`n=== Script voltooid ===" -ForegroundColor Cyan
