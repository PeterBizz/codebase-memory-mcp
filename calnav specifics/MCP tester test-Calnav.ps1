$ErrorActionPreference = 'Stop'
Set-ScriptLocation
. .\SetupMCPEnvironment.ps1

$ProjectName = "test-calnav2"
$ProjectFolder = (Resolve-Path (Join-Path $Location '.\test-calnav')).Path
$Projects = Get-Projects | Select-Object -ExpandProperty name
if ($Projects -contains $ProjectName) {
   Get-ProjectInfo -ProjectName $ProjectName -Aspects 'all' | ConvertFrom-Json | ConvertTo-Json -Depth 20   
      Read-Host (1)
   Delete-Project -ProjectName $ProjectName
} else {
  Write-Host (" project : $ProjectName not found" )   
}
Read-Host (" Start Index" )
Index-Project -ProjectName $ProjectName -ProjectFolder $ProjectFolder

$Projects = Get-Projects | Select-Object -ExpandProperty name
if ($Projects -contains $ProjectName) {
   Get-ProjectInfo -ProjectName $ProjectName -Aspects 'all' | ConvertFrom-Json | ConvertTo-Json -Depth 20   
   Read-Host ("And Delete again" )
   Delete-Project -ProjectName $ProjectName
} 
else {   
  Write-Host (" project : $ProjectName not found again" )   
}



