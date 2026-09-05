Set-ScriptLocation
$Location =Get-Location
Set-StrictMode -Version Latest

$env:CBM_LOG_LEVEL = 'debug'
$env:CBM_LOG_FORMAT = 'text'
$env:CBM_DIAGNOSTICS = '0'

$env:CBM_LOG_FILE = Join-Path $Location '..\private\calnav-parser.log'

$exe = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"
$repo = Join-Path $Location ".\test-calnav"
$projectName = 'Mini-calnav'

function Write-Section {
	param([string]$Title)
	Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Write-Entries {
	param(
		[string]$Title,
		[object[]]$Items,
		[scriptblock]$Formatter
	)
	Write-Section $Title
	if (-not $Items -or $Items.Count -eq 0) {
		Write-Host '(none)' -ForegroundColor DarkGray
		return
	}
	foreach ($item in $Items) {
		& $Formatter $item
	}
}

function Get-JsonResult {
	param([string]$JsonText)
	if ([string]::IsNullOrWhiteSpace($JsonText)) {
		return $null
	}
	return ($JsonText | ConvertFrom-Json).structuredContent
}

## $clearLog = Read-Host "Clear existing logfile first? (y/n)"
$clearLog = 'y'
if ($clearLog -eq 'y' -and (Test-Path $env:CBM_LOG_FILE)) {
	Remove-Item $env:CBM_LOG_FILE -Force
}

# A full index already replaces the project data, so no delete step is needed.

$indexArgs = [pscustomobject]@{
	repo_path = $repo
	name      = $projectName
	mode      = 'full'
} | ConvertTo-Json -Compress

$Json = $indexArgs | & $exe cli --json index_repository

$IndexResult = Get-JsonResult $Json
$statusArgs = [pscustomobject]@{
	project = $projectName
	verbose = $true
} | ConvertTo-Json -Compress

$StatusJson = $statusArgs | & $exe cli --json index_status
$StatusResult = Get-JsonResult $StatusJson

Write-Section 'Index response'
if ($IndexResult) {
	$IndexResult | ConvertTo-Json -Depth 20
} else {
	$Json
}

if ($IndexResult) {
	Write-Section 'Index summary'
	$IndexResult | Format-List | Out-String | Write-Host
}

if ($StatusResult) {
	Write-Section 'Project summary'
	[pscustomobject]@{
		project = $StatusResult.project
		nodes   = $StatusResult.nodes
		edges   = $StatusResult.edges
		status  = $StatusResult.status
		root    = $StatusResult.root_path
		logfile = $env:CBM_LOG_FILE
	} | Format-List | Out-String | Write-Host

	Write-Entries 'Parse partial files' $StatusResult.parse_partial.files {
		param($f)
		Write-Host ('- {0}' -f $f.path) -ForegroundColor Yellow
		Write-Host ('  error_ranges: {0}' -f $f.error_ranges)
	}

	Write-Entries 'Skipped files' $StatusResult.skipped.files {
		param($f)
		Write-Host ('- {0}' -f $f.path) -ForegroundColor Yellow
		Write-Host ('  phase: {0}' -f $f.phase)
		Write-Host ('  reason: {0}' -f $f.reason)
	}

	Write-Section 'Not indexed by design'
	if ($StatusResult.not_indexed) {
		if ($StatusResult.not_indexed.dirs -and $StatusResult.not_indexed.dirs.Count -gt 0) {
			Write-Host 'Directories:' -ForegroundColor Green
			$StatusResult.not_indexed.dirs | ForEach-Object { Write-Host ('- {0}' -f $_) }
		} else {
			Write-Host 'Directories: (none)' -ForegroundColor DarkGray
		}
		if ($StatusResult.not_indexed.files -and $StatusResult.not_indexed.files.Count -gt 0) {
			Write-Host 'Files:' -ForegroundColor Green
			$StatusResult.not_indexed.files | ForEach-Object {
				Write-Host ('- {0}' -f $_.path)
				Write-Host ('  reason: {0}' -f $_.reason)
			}
		} else {
			Write-Host 'Files: (none)' -ForegroundColor DarkGray
		}
	}
}

Write-Section 'Current logfile'
Write-Host "Log path: $env:CBM_LOG_FILE" -ForegroundColor Yellow
if (Test-Path $env:CBM_LOG_FILE) {
	$tail = Get-Content $env:CBM_LOG_FILE | Select-Object -Last 200
	$tail
    code $env:CBM_LOG_FILE
} else {
	Write-Warning "Log file was not created."
}

