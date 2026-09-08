Set-ScriptLocation 
$ErrorActionPreference = 'Stop'
$Location = Get-Location
$CodebaseMemoryexeFilename = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"
Write-Host "Testen NAVDev en Tree-sitter-cal paden..."
$NAVDevRoot = Resolve-Path (Join-Path $Location "..\..\NAVDev")
$NAVDevRootSource = Resolve-Path (Join-Path $NAVDevRoot "AllFobDev\")
$TreeSitterCalRoot = Resolve-Path (Join-Path $Location "..\..\tree-sitter-cal")

function Get-Projects{
    $Json =Invoke-MCPCbmJson -Command 'list_projects' -Payload '{}'
    $($json | ConvertFrom-Json ).structuredContent.projects
}

function Invoke-MCPCbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    $ArgsFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $ArgsFile -Value $Payload -Encoding utf8NoBOM -NoNewline
        Write-Host "Invoking codebase-memory-mcp.exe with command '$Command' and payload: $Payload" -ForegroundColor Yellow
        & $CodebaseMemoryexeFilename cli --json $Command --args-file $ArgsFile 2>$null
    }
    finally {
        Remove-Item -Path $ArgsFile -ErrorAction SilentlyContinue
    }
}

function Get-MCPProjectInfo {
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter()] [string] $Aspects = 'all',     # 'all', 'languages', 'architecture', 'graph_schema'
        [Parameter()] [switch] $ListAspectsOnly = $false
    )
    $Payload = '{"project":"' + $ProjectName + '","aspect":"' + $Aspects + '"}'
    $Json = Invoke-MCPCbmJson -Command 'get_architecture' -Payload $Payload
    $($Json | ConvertFrom-Json).StructuredContent    
}

function Index-MCPProject {
    param(
        [Parameter()] [string] $ProjectName = "navdev-full",
        [Parameter()] [string] $ProjectFolder = $NAVDevRootSource, 
        [Parameter()] [switch] $FastMode = $false
    )    
    $fastModeJson = if ($FastMode) { ',"mode":"fast"' } else { '' }
    $Payload = '{"repo_path":"' + ($ProjectFolder -replace '\\', '\\\\') + '", "name":"' + $ProjectName +'"' + $fastModeJson + '}'
    $Json = Invoke-MCPCbmJson -Command 'index_repository' -Payload $Payload
    $($Json | ConvertFrom-Json).StructuredContent   
}

function Index-MCPProject2 {
    param(
        [Parameter()] [string] $ProjectName = "navdev-full",
        [Parameter()] [string] $ProjectFolder = $NAVDevRootSource, 
        [Parameter()] [switch] $FastMode = $false
    )    

    $mode = if ($FastMode) { 'fast' } else { 'full' }
    $Json = & $CodebaseMemoryexeFilename cli --json index_repository --name $ProjectName --repo-path $ProjectFolder --mode $mode 2>$null
    $($Json | ConvertFrom-Json).StructuredContent   
}

function Get-MCPIndexStatus {
    param(
        [Parameter()] [string] $ProjectName = "navdev-full"
    )
    $statusArgs = [pscustomobject]@{
        project = $ProjectName
        verbose = $true
    } | ConvertTo-Json -Compress

    $Json = Invoke-MCPCbmJson -Command 'index_status' -Payload $statusArgs
    $($Json | ConvertFrom-Json).StructuredContent   
}

function Delete-MCPProject {
    param(
        [Parameter(Mandatory)] [string] $ProjectName
    )
    $Payload = '{"project":"' + $ProjectName + '"}'
    $Json = Invoke-MCPCbmJson -Command 'delete_project' -Payload $Payload
    $($Json | ConvertFrom-Json).StructuredContent   
}