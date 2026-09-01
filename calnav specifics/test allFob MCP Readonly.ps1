$ErrorActionPreference = 'Stop'

$Exe = ".\build\c\codebase-memory-mcp.exe"
$LogFile = 'C:\Users\peter\Source\Repos\Everest\codebase-memory-mcp\private\calnav-parser-deamon.log'
$Project = 'navdev-full'

$ExampleRepo = 'C:\Users\peter\Source\Repos\Everest\tree-sitter-cal\examples'

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

$ProjectsJson = & $Exe cli --json list_projects | Where-Object { $_ -match '^\{' }
$Projects = ($ProjectsJson | ConvertFrom-Json).structuredContent.projects | where-object { $_.name -eq $Project }
foreach ($ProjectItem in $Projects) {
    $ProjectItem.name
}

$env:CBM_LOG_LEVEL = 'debug'
$env:CBM_LOG_FORMAT = 'text'
$env:CBM_LOG_FILE = $LogFile

Invoke-CbmJson -Command 'get_graph_schema' -Payload ('{"project":"' + $Project + '"}')
Invoke-CbmJson -Command 'get_architecture' -Payload ('{"project":"' + $Project + '","aspects":["file_tree"]}')
Invoke-CbmJson -Command 'search_graph' -Payload ('{"project":"' + $Project + '","query":"Section"}')
Invoke-CbmJson -Command 'query_graph' -Payload ('{"project":"' + $Project + '","query":"MATCH (f:Function) RETURN f.qualified_name AS qn LIMIT 5"}')
Invoke-CbmJson -Command 'trace_call_path' -Payload ('{"project":"' + $Project + '","function_name":"TestProcdure"}')

$PayLoad = '{"project":"' + $Project + '","query":"name_pattern=*CompanyOpen*"}'
Invoke-CbmJson -Command 'search_graph' -Payload ($PayLoad)
Invoke-CbmJson -Command 'trace_call_path' -Payload ('{"project":"' + $Project + '","function_name":"navdev-full.Codeunit.1.CompanyOpen"}')