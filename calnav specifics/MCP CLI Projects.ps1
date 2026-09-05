# --- CONFIGURATIE ---
# Pas dit aan naar het juiste pad van jouw binary

Set-ScriptLocation 
$Location = Get-Location
$codebaseMemoryexeFilename = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"

Write-Host "=== Ophalen van bekende projecten uit codebase-memory-mcp ===" -ForegroundColor Cyan

# Haal projecten op via de CLI en filter direct op pure JSON (Jouw filter logica)
$projectsJson = & $codebaseMemoryexeFilename cli --json list_projects | Where-Object { $_ -match '^\{' }

$projects = @()
if (-not [string]::IsNullOrWhiteSpace($projectsJson)) {
    try {
        $projectData = $(ConvertFrom-Json $projectsJson -ErrorAction Stop).content.text
        $projectData = $projectData | ConvertFrom-Json
        
        # Sla de projecten-array op
        $projects = $projectData.projects
        
    } catch {
        Write-Host "[!] Fout bij het parsen van list_projects JSON." -ForegroundColor Red
    }
}

# --- VANGNET ALS ER GEEN PROJECTEN ZIJN ---
if ($projects.Count -eq 0) {
    Write-Host "`n[i] De database is momenteel leeg of projecten konden niet worden geladen." -ForegroundColor Yellow
    $ans = Read-Host "Wil je nu een nieuwe repository indexeren? (j/n)"
    if ($ans -eq 'j' -or $ans -eq 'y') {
        $repoPath = Read-Host "Voer het absolute pad naar de repository in"
        if (Test-Path $repoPath) {
            Write-Host "Bezig met indexeren via de daemon..." -ForegroundColor Yellow
            & $codebaseMemoryexeFilename cli index_repository --repo-path "$repoPath"
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
    
       
    ##--$nodes = $pproject.nodes ? $pproject.nodes : 0
    ##--$edges = $pproject.edges ? $pproject.edges : 0
    $repoPath = $pproject.root_path

    Write-Host "`n--------------------------------------------------" -ForegroundColor Gray
    Write-Host "Project gevonden: $projectName" -ForegroundColor Magenta
    ## Write-Host "Nodes: $nodes | Edges: $edges | Branch: $($pproject.branch)" -ForegroundColor Gray
    Write-Host "--------------------------------------------------" -ForegroundColor Gray
    Write-Host "Wat wil je met dit project doen?"
    Write-Host " 1] Full Index (Bestaande index behouden, wijzigingen scannen)"
    Write-Host " 2] Re-Index (Eerst de graaf wissen, daarna volledig schoon opbouwen)"
    Write-Host " 3] Project Verwijderen (Wissen zonder opnieuw te maken)"
    Write-Host " 4] Alleen taalcontrole (Geen wijzigingen, direct taalgebruik inzien)"
    Write-Host " 5] Overslaan / Volgende"
    
    $choice = Read-Host "Maak een keuze (1-5)"
    
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
            & $codebaseMemoryexeFilename cli delete_project --project "$projectName"
            Write-Host "Project succesvol verwijderd." -ForegroundColor Green
        }
        "4" {
            Show-LanguageUsage -projectName $projectName
        }
        "5" {
            Write-Host "Project $projectName overgeslagen." -ForegroundColor Gray
        }
        default {
            Write-Host "Ongeldige keuze. Project overgeslagen." -ForegroundColor Yellow
        }
    }
}

# --- TAAL GEBRUIK CONTROLE FUNCTIE ---
function Show-LanguageUsage {
    param ([string]$projectName)
    Write-Host "`nOphalen van gegevens voor $projectName..." -ForegroundColor Cyan
    
    # Vraag de architectuur op via de CLI en pas jouw regex-filter toe
    $archJson = & $codebaseMemoryexeFilename cli --json get_architecture --project "$projectName" | Where-Object { $_ -match '^\{' }
    
    if (-not [string]::IsNullOrEmpty($archJson)) {
        try {
            $archData = ConvertFrom-Json $archJson
            Write-Host "=== Architectuur in de index voor '$projectName' ===" -ForegroundColor Green
            $targetData = $archData.structuredContent.Text

            if ($targetData.languages) {
                # Toon de talenmatrix netjes onder elkaar
                $targetData.languages | Format-List | Out-String | Write-Host -ForegroundColor White
            } else {
                $targetData | Format-List | Out-String | Write-Host
            }
        } catch {
            Write-Host "Kon architectuur-JSON niet verwerken." -ForegroundColor Red
        }
    } else {
        Write-Host "Kon taalgegevens niet valideren via get_architecture." -ForegroundColor Red
    }
}

Write-Host "`n=== Script voltooid ===" -ForegroundColor Cyan
