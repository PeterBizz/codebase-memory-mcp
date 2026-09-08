$ErrorActionPreference = 'Stop'
Set-ScriptLocation
. .\SetupMCPEnvironment.ps1

$ProjectName = "test-calnav"
$ProjectFolder = (Resolve-Path (Join-Path $Location '.\test-calnav')).Path
Write-Host "Reindexing '$ProjectName' from '$ProjectFolder'..." -ForegroundColor Cyan
$Result = Index-MCPProject -ProjectName $ProjectName -ProjectFolder $ProjectFolder
Write-Host 
$result.project
$result.status
