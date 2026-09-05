$ErrorActionPreference = 'Stop'
Set-ScriptLocation
$Location =Get-Location

$LogFile = Join-Path $Location '..\private\calnav-parser-deamon_navdev.log'
$exe = Join-Path $Location "..\build\c\codebase-memory-mcp.exe"
$Project = 'navdev-full'

function Invoke-CbmJson {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    $ArgsFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $ArgsFile -Value $Payload -Encoding utf8NoBOM -NoNewline
        & $Exe cli --json $Command --args-file $ArgsFile
    }
    finally {
        Remove-Item -Path $ArgsFile -ErrorAction SilentlyContinue
    }
}

$env:CBM_LOG_LEVEL = 'debug'
$env:CBM_LOG_FORMAT = 'text'
$env:CBM_LOG_FILE = $LogFile

$GraphSchema = Invoke-CbmJson -Command 'get_graph_schema' -Payload ('{"project":"' + $Project + '"}')
$ArchFileTree = Invoke-CbmJson -Command 'get_architecture' -Payload ('{"project":"' + $Project + '","aspects":["file_tree"]}')
Invoke-CbmJson -Command 'search_graph' -Payload ('{"project":"' + $Project + '","query":"Section"}')
Invoke-CbmJson -Command 'query_graph' -Payload ('{"project":"' + $Project + '","query":"MATCH (f:Function) RETURN f.qualified_name AS qn LIMIT 5"}')
Invoke-CbmJson -Command 'trace_call_path' -Payload ('{"project":"' + $Project + '","function_name":"Init"}')

$PayLoad = '{"project":"' + $Project + '","query":"name_pattern=*CompanyOpen*"}'
Invoke-CbmJson -Command 'search_graph' -Payload ($PayLoad)
Invoke-CbmJson -Command 'trace_call_path' -Payload ('{"project":"' + $Project + '","function_name":"navdev-full.Codeunit.1.CompanyOpen"}')
Invoke-CbmJson -Command 'trace_call_path' -Payload ('{"project":"' + $Project + '","function_name":"navdev-full.Codeunit.1.CompanyOpen"}')