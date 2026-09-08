Set-ScriptLocation 
$ErrorActionPreference = 'Stop'
$Location = Get-Location
$CodebaseMemoryexeFilename = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"
Write-Host "Testen NAVDev en Tree-sitter-cal paden..."
$NAVDevRoot = Resolve-Path (Join-Path $Location "..\..\NAVDev")
$NAVDevRootSource = Resolve-Path (Join-Path $NAVDevRoot "AllFobDev\")
$TreeSitterCalRoot = Resolve-Path (Join-Path $Location "..\..\tree-sitter-cal")

function Get-MCPProjects{
    $Json =Invoke-MCPCbmJson -Command 'list_projects' -Payload '{}'
    $($json | ConvertFrom-Json ).structuredContent.projects
}

function Invoke-MCPCbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload,
        [Parameter()] [string] $OutFile = $null
    )

    $ArgsFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $ArgsFile -Value $Payload -Encoding utf8NoBOM -NoNewline
        Write-Host "Invoking codebase-memory-mcp.exe with command '$Command' and payload: $Payload" -ForegroundColor Yellow
        & $CodebaseMemoryexeFilename cli --json $Command --args-file $ArgsFile 2>$OutFile
    }
    finally {
        Remove-Item -Path $ArgsFile -ErrorAction SilentlyContinue
    }
}

function Get-MCPEnvelopeData {
    param(
        [Parameter(Mandatory)] [string] $Json
    )

    $Envelope = $Json | ConvertFrom-Json

    if ($null -ne $Envelope -and $null -ne $Envelope.structuredContent) {
        return $Envelope.structuredContent
    }

    if ($null -ne $Envelope -and $null -ne $Envelope.content -and $Envelope.content.Count -gt 0) {
        $Text = $Envelope.content[0].text
        if (-not [string]::IsNullOrWhiteSpace($Text)) {
            try {
                return $Text | ConvertFrom-Json
            }
            catch {
                return $Text
            }
        }

        return $Envelope.content
    }

    return $Envelope
}

function Get-MCPProjectInfo {
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter()] [string] $Aspects = 'all',     # 'all', 'languages', 'architecture', 'graph_schema'
        [Parameter()] [switch] $ListAspectsOnly = $false
    )
    $Payload = [pscustomobject]@{
        project = $ProjectName
        aspects = @($Aspects)
    } | ConvertTo-Json -Compress

    $Json = Invoke-MCPCbmJson -Command 'get_architecture' -Payload $Payload
    Get-MCPEnvelopeData -Json $Json
}

function Index-MCPProject {
    param(
        [Parameter()] [string] $ProjectName = "navdev-full",            
        [Parameter()] [switch] $FastMode = $false
    )    
    $fastModeJson = if ($FastMode) { ',"mode":"fast"' } else { '' }
    $Payload = '{"repo_path":"' + ($ProjectFolder -replace '\\', '\\\\') + '", "name":"' + $ProjectName +'"' + $fastModeJson + '}'
    $Json = Invoke-MCPCbmJson -Command 'index_repository' -Payload $Payload
    Get-MCPEnvelopeData -Json $Json
}

function Get-MCPIndexStatus {
    param(
        [Parameter()] [string] $ProjectName = "navdev-full"
    )
    $statusArgs = '{"project":"' + $ProjectName + '"}'
    $Json = Invoke-MCPCbmJson -Command 'index_status' -Payload $statusArgs
    Get-MCPEnvelopeData -Json $Json
}


function Delete-MCPProject {
    param(
        [Parameter(Mandatory)] [string] $ProjectName
    )
    $deleteArgs = '{"project":"' + $ProjectName + '"}'
    $Json = Invoke-MCPCbmJson -Command 'delete_project' -Payload $deleteArgs
    Get-MCPEnvelopeData -Json $Json
}