Set-ScriptLocation; 
& .\SetupMCPEnvironment.ps1
$projects = Get-Projects

foreach ($pproject in $projects) {
    write-Host " Name: $($pproject.name), Root path: $($pproject.root_path)" -ForegroundColor Green

    if ( $(read-host "Wil je dit project verwijderen? (j/n)") -eq 'j') {
        $projectName = $pproject.name
        Write-Host "(Index voor Project $projectName aan het verwijderen" -ForegroundColor Red
        Delete-MCPProject -ProjectName $projectName
    }    
}
