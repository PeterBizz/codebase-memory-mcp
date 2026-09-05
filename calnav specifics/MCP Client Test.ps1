# ==================================================================================
# Get-CodebaseMemoryTools.ps1
# Standalone script om de codebase-memory-mcp executable te starten en tools op te halen.
# ==================================================================================

# 1. Definieer het pad naar de MCP Server Executable
Set-ScriptLocation 
$Location = Get-Location
$ServerExecutable = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"

$ServerArguments  = @() # Leeg indien de server geen extra argumenten vereist bij opstarten

# Los het relatieve pad op naar een absoluut pad om opstartfouten te voorkomen
$AbsoluteProcessPath = Resolve-Path $ServerExecutable -ErrorAction SilentlyContinue
if (-not $AbsoluteProcessPath) {
    Write-Error "Fout: Kan het bestand niet vinden op locatie: $ServerExecutable"
    Write-Host "Controleer of je in de juiste map staat (huidige map is: $(Get-Location))" -ForegroundColor Yellow
    exit
}

# 2. Configureer de Proces Start-Informatie voor Stdio Communicatie
$StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
$StartInfo.FileName               = $AbsoluteProcessPath.Path
$StartInfo.Arguments              = $ServerArguments -join " "
$StartInfo.RedirectStandardInput  = $true
$StartInfo.RedirectStandardOutput = $true
$StartInfo.RedirectStandardError  = $true
$StartInfo.UseShellExecute        = $false
$StartInfo.CreateNoWindow         = $true

# 3. Start het Codebase Memory MCP Proces
Write-Host "Starten van MCP Server: $($AbsoluteProcessPath.Path)..." -ForegroundColor Cyan
$McpProcess = [System.Diagnostics.Process]::Start($StartInfo)

if (-not $McpProcess) {
    throw "Lanceren van de MCP server process is mislukt."
}

# Geef de server 1 seconde de tijd om op te starten
Start-Sleep -Seconds 1

# 4. Formuleer de JSON-RPC Payloads (MCP Standaard)
# Protocol vereist eerst een 'initialize' handshake, daarna pas 'tools/list'
$InitializePayload = @{
    jsonrpc = "2.0"
    id      = 1
    method  = "initialize"
    params  = @{
        protocolVersion = "2024-11-05"
        capabilities    = @{}
        clientInfo      = @{
            name    = "PowerShell-MCP-Client"
            version = "1.0.0"
        }
    }
} | ConvertTo-Json -Depth 10 -Compress

$ListToolsPayload = @{
    jsonrpc = "2.0"
    id      = 2
    method  = "tools/list"
} | ConvertTo-Json -Depth 10 -Compress

# 5. Schrijf en lees van de Stdio Streams
$StreamWriter = $McpProcess.StandardInput
$StreamReader = $McpProcess.StandardOutput

# Handshake verzenden
Write-Host "Verzenden van 'initialize' handshake..." -ForegroundColor Gray
$StreamWriter.WriteLine($InitializePayload)
$StreamWriter.Flush()
$InitResponse = $StreamReader.ReadLine() # Initialisatie-bevestiging opvangen

# Tools opvragen
Write-Host "Verzenden van 'tools/list' verzoek..." -ForegroundColor Gray
$StreamWriter.WriteLine($ListToolsPayload)
$StreamWriter.Flush()
$ToolsResponse = $StreamReader.ReadLine()

# 6. Verwerk en toon de beschikbare Tools
if ($ToolsResponse) {
    try {
        $JsonObject = $ToolsResponse | ConvertFrom-Json
        
        if ($JsonObject.result -and $JsonObject.result.tools) {
            Write-Host "`n[Beschikbare Tools in Codebase-Memory-MCP]" -ForegroundColor Green
            
            # Toon de naam en beschrijving van elke gevonden tool
            foreach ($Tool in $JsonObject.result.tools) {
                [PSCustomObject]@{
                    ToolNaam    = $Tool.name
                    Beschrijving = $Tool.description
                } | Format-List
            }
        } else {
            Write-Warning "Geen tools geretourneerd of de server gaf een foutmelding."
            $JsonObject | Format-List
        }
    } catch {
        Write-Error "Fout bij het parsen van de server JSON-respons: $_"
        Write-Host "Ruwe Output: $ToolsResponse" -ForegroundColor Magenta
    }
} else {
    Write-Error "De MCP Server reageerde niet op het tools/list verzoek."
    $StdError = $McpProcess.StandardError.ReadToEnd()
    if ($StdError) { Write-Host "Stderr Foutmelding: $StdError" -ForegroundColor Red }
}

# 7. Schoon de processen en streams netjes op
Write-Host "Sluiten van MCP sessie..." -ForegroundColor Gray
$StreamWriter.Close()
$StreamReader.Close()
if (-not $McpProcess.HasExited) {
    $McpProcess.Kill()
}
$McpProcess.Dispose()
