<#
.SYNOPSIS
    Enable CBM_DIAGNOSTICS=1 for codebase-memory-mcp and locate the results.

.DESCRIPTION
    The shared CBM daemon captures CBM_DIAGNOSTICS only from the FIRST
    daemon-backed session that starts it. This script:
      1. Checks whether a daemon is still running (it must exit first).
      2. Sets $env:CBM_DIAGNOSTICS = "1" in the current shell so any client
         launched from this shell (e.g. `code .`) inherits it.
      3. With -FindResults, shows the diagnostics directory, the
         diagnostics.start log event, and tails trajectory.ndjson.

.EXAMPLE
    .\Run-CbmDiagnostics.ps1              # prepare: check daemon, set env var
    code .                                # launch first session from same shell

.EXAMPLE
    .\Run-CbmDiagnostics.ps1 -FindResults # locate and inspect the output files
#>
param(
    [switch]$FindResults
)

$daemonLog = Join-Path $HOME '.cache\codebase-memory-mcp\logs\cbm-daemon.log'
if ($env:CBM_DIAGNOSTICS = '1') {
    Write-Host "CBM_DIAGNOSTICS=1 is already set in this shell." -ForegroundColor Green
    Write-Host "I will show you results now"
    $FindResults = $true
}

if ($FindResults) {
    Write-Host "== diagnostics.start events in cbm-daemon.log ==" -ForegroundColor Cyan
    if (Test-Path $daemonLog) {
        Select-String -Path $daemonLog -Pattern 'diagnostics\.start' |
            Select-Object -Last 3 | ForEach-Object { $_.Line }
    } else {
        Write-Warning "Daemon log not found: $daemonLog"
    }

    Write-Host "`n== Diagnostics directories in %TEMP% ==" -ForegroundColor Cyan
    $dirs = Get-ChildItem "$env:TEMP\cbm-diagnostics-*" -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    if (-not $dirs) {
        Write-Warning "No cbm-diagnostics-* directory found. Was CBM_DIAGNOSTICS=1 set before the daemon started?"
        return
    }
    $dirs | Format-Table FullName, LastWriteTime -AutoSize

    $latest = $dirs[0]
    $traj = Join-Path $latest.FullName 'trajectory.ndjson'
    if (Test-Path $traj) {
        Write-Host "`n== Last 5 samples from $traj ==" -ForegroundColor Cyan
        Get-Content $traj -Tail 5
    }
    return
}

# --- Prepare mode ---
$running = Get-Process codebase-memory-mcp -ErrorAction SilentlyContinue
if ($running) {
    Write-Warning ("Daemon/frontend still running (PID {0}). The daemon only reads CBM_DIAGNOSTICS at startup." -f ($running.Id -join ', '))
    Write-Warning "Close ALL daemon-backed MCP sessions (VS Code windows etc.) so the daemon exits, then re-run this script."
    return
}

$env:CBM_DIAGNOSTICS = '1'
Write-Host "CBM_DIAGNOSTICS=1 set in this shell." -ForegroundColor Green
Write-Host "Now launch the first MCP client FROM THIS SHELL so it inherits the variable, e.g.:"
Write-Host "    code ." -ForegroundColor Yellow
Write-Host "Or add to your mcp.json server config instead:  `"env`": { `"CBM_DIAGNOSTICS`": `"1`" }"
Write-Host "`nAfter reproducing the issue, run:  .\Run-CbmDiagnostics.ps1 -FindResults"
