& ".\build\c\codebase-memory-mcp.exe" cli --json index_repository '{"repo_path":"C:\\Users\\peter\\Source\\Repos\\Everest\\codebase-memory-mcp\\private\\test-calnav"}'

& ".\build\c\codebase-memory-mcp.exe" cli --json get_architecture

$json = & ".\build\c\codebase-memory-mcp.exe" cli --json list_projects |
    Where-Object { $_ -match '^\{' }

$projects = $($json | ConvertFrom-Json ).structuredContent.projects
    
# 4. Voer de lus uit over de daadwerkelijke array
foreach ($pproject in $projects) {
    # Dit werkt nu gegarandeerd en toont de pure namen
    $pproject.name
}

$json = & ".\build\c\codebase-memory-mcp.exe" cli --json get_architecture '{"project":"C-Users-peter-Source-Repos-Everest-codebase-memory-mcp-private-test-calnav"}'| Where-Object { $_ -match '^\{' }
$json = & ".\build\c\codebase-memory-mcp.exe" cli --json get_architecture '{"project":"test-calnav"}'| Where-Object { $_ -match '^\{' }
$($json | convertfrom-Json ).structuredContent | set-clipboard

$Json = & ".\build\c\codebase-memory-mcp.exe" cli --json index_repository '{"repo_path":"C:\\Users\\peter\\Source\\Repos\\Everest\\codebase-memory-mcp\\private\\test-calnav", "name":"test-calnav"}'
$($json | convertfrom-Json ).structuredContent.text

### ==  start the daemon niet vergeten om weer te stoppen
.\build\c\codebase-memory-mcp.exe daemon start
.\build\c\codebase-memory-mcp.exe daemon stop
.\build\c\codebase-memory-mcp.exe cli --help
$Json = .\build\c\codebase-memory-mcp.exe cli query_graph --help
$Json = .\build\c\codebase-memory-mcp.exe cli --json query_graph '{"project":"test-calnav"}'

$JsonPayLoad = '{"project":"test-calnav","query":"*"}'
$JsonPayLoad | & $codebaseMemoryexeFilename cli query_graph --json

$JsonPayLoad =  '{"project":"test-calnav","aspects":["file_tree"]}'
$JsonPayLoad | & $codebaseMemoryexeFilename cli get_architecture --json

$JsonPayLoad = '{"project":"test-calnav"}'
$Json = $JsonPayLoad | & $codebaseMemoryexeFilename cli get_graph_schema --json

$nodeLabels = $($($Json | convertfrom-json ).structuredContent).node_labels
$nodeLabels[1].properties 

$nodeLabels = $($($Json | convertfrom-json ).structuredContent).edge    
$nodeLabels[1].properties 

## .\build\c\codebase-memory-mcp.exe daemon stop
$JsonPayLoad = '{"project":"test-calnav","query":"50000"}'
$JSON = $JsonPayLoad | & $codebaseMemoryexeFilename cli --json search_graph
$JSON = .\build\c\codebase-memory-mcp.exe cli --json search_graph '{"project":"test-calnav","query":"Section"}'
$JSON = .\build\c\codebase-memory-mcp.exe cli --json get_graph_schema '{"project":"test-calnav"}'
$JSON = .\build\c\codebase-memory-mcp.exe cli --json get_architecture '{"project":"test-calnav","aspects":["file_tree"]}'
$JSON = .\build\c\codebase-memory-mcp.exe cli --json query_graph '{"project":"test-calnav","query":"Section"}'

##Nu de exmples van de grammer maar eerst testen: 
$Json = & ".\build\c\codebase-memory-mcp.exe" cli --json index_repository '{"repo_path":"C:\\Users\\peter\\Source\\Repos\\Everest\\tree-sitter-cal\\examples", "name":"Exmple-calnav"}'
$Json | set-clipboard


$JsonPayLoad = '{"project":"test-calnav","query":"Section"}'
$JSON = $JsonPayLoad | & $codebaseMemoryexeFilename cli --json trace_call_path
$JSON = $JsonPayLoad | & $codebaseMemoryexeFilename cli  --help


