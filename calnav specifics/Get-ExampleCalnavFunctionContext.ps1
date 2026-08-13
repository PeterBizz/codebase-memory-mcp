$ErrorActionPreference = 'Stop'

$Exe = ".\build\c\codebase-memory-mcp.exe"
$Project = 'Example-calnav'
$ProjectRoot = 'C:\Users\peter\Source\Repos\Everest\tree-sitter-cal\examples'

function Invoke-CbmJsonObject {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string] $Payload
    )

    $result = $Payload | & $Exe cli --json $Command
    if (-not $result) {
        return $null
    }

    if ($result -is [string]) {
        try {
            $result = $result | ConvertFrom-Json
        }
        catch {
            return $null
        }
    }

    if ($result.PSObject.Properties.Match('structuredContent').Count -gt 0 -and $result.structuredContent) {
        return $result.structuredContent
    }

    if ($result.PSObject.Properties.Match('content').Count -gt 0 -and $result.content) {
        $text = $result.content | ForEach-Object { $_.text } | Where-Object { $_ }
        if ($text) {
            $first = $text | Select-Object -First 1
            try {
                return ($first | ConvertFrom-Json)
            }
            catch {
                return [pscustomobject]@{ text = $first }
            }
        }
    }

    return $result
}

function Get-CbmResultText {
    param(
        [Parameter(Mandatory)] $Result
    )

    if ($null -eq $Result) {
        return $null
    }

    if ($Result.PSObject.Properties.Match('text').Count -gt 0 -and $Result.text) {
        return $Result.text
    }

    if ($Result.PSObject.Properties.Match('content').Count -gt 0 -and $Result.content) {
        $text = $Result.content | ForEach-Object { $_.text } | Where-Object { $_ }
        if ($text) {
            return ($text | Select-Object -First 1)
        }
    }

    return $null
}

function Get-CbmPayload {
    param(
        [Parameter(Mandatory)] [hashtable] $Data
    )

    ($Data | ConvertTo-Json -Compress)
}

function Get-FunctionRows {
    $payload = Get-CbmPayload -Data @{
        project = $Project
        label   = 'Function'
        fields  = @('signature')
        limit   = 500
        format  = 'json'
    }

    $result = Invoke-CbmJsonObject -Command 'search_graph' -Payload $payload
    if (-not $result) {
        return @()
    }

    if ($result.PSObject.Properties.Match('groups').Count -eq 0) {
        return @()
    }

    $rows = @()
    foreach ($group in $result.groups) {
        $file = $group.file
        foreach ($row in $group.rows) {
            $range = $row[2]
            $start = [int]($range -split '-')[0]
            $end = [int]($range -split '-')[1]
            $rows += [pscustomobject]@{
                QualifiedName = "$($group.qn_prefix).$($row[0])"
                Name          = $row[0]
                File          = $file
                StartLine     = $start
                EndLine       = $end
                CallsIn       = [int]$row[3]
                CallsOut      = [int]$row[4]
                Signature     = if ($row.Count -gt 5) { $row[5] } else { $null }
            }
        }
    }

    return $rows
}

function Get-CallerMap {
    $payload = Get-CbmPayload -Data @{
        project = $Project
        query   = 'MATCH (caller:Function)-[:CALLS]->(callee:Function) RETURN callee.qualified_name AS callee, collect(caller.qualified_name) AS callers'
    }

    $result = Invoke-CbmJsonObject -Command 'query_graph' -Payload $payload
    $map = @{}
    $text = Get-CbmResultText -Result $result
    if (-not $text) {
        return $map
    }

    foreach ($line in ($text -split "`n")) {
        if ($line -match '^\s*(?<callee>\S+)\s+(?<callers>.+)$' -and $line -notmatch '^rows:|^total:|^hint:') {
            $callee = $Matches.callee
            $callers = $Matches.callers -split '\s*;\s*|\s*,\s*' | Where-Object { $_ -and $_ -ne '[]' }
            $map[$callee] = @($callers)
        }
    }

    return $map
}

function Get-ObjectInfo {
    param(
        [Parameter(Mandatory)] [string] $RelativeFile
    )

    $fullPath = Join-Path $ProjectRoot $RelativeFile
    $header = Get-Content -Path $fullPath -TotalCount 8
    $objectLine = $header | Where-Object { $_ -match '^OBJECT\s+' } | Select-Object -First 1

    $objectType = $null
    $objectId = $null
    $objectName = $null
    if ($objectLine -match '^OBJECT\s+(?<type>\w+)\s+(?<id>\d+)\s+(?<name>.+)$') {
        $objectType = $Matches.type
        $objectId = $Matches.id
        $objectName = $Matches.name.Trim()
    }

    [pscustomobject]@{
        ObjectType      = $objectType
        ObjectId        = $objectId
        ObjectName      = $objectName
        ObjectContext   = if ($objectType) { "$objectType $objectId $objectName" } else { $null }
        MainTableObject = if ($objectType -eq 'Table') { "$objectType $objectId $objectName" } else { $null }
    }
}

function Get-FunctionSignatureText {
    param(
        [string] $Signature,
        [string] $RelativeFile,
        [int] $StartLine
    )

    if ($Signature) {
        return $Signature.Trim()
    }

    $line = (Get-Content -Path (Join-Path $ProjectRoot $RelativeFile) -TotalCount $StartLine)[$StartLine - 1]
    return $line.Trim()
}

function Test-FunctionIsLocal {
    param(
        [string] $RelativeFile,
        [int] $StartLine
    )

    $line = (Get-Content -Path (Join-Path $ProjectRoot $RelativeFile) -TotalCount $StartLine)[$StartLine - 1]
    return $line -match '^\s*LOCAL\s+PROCEDURE\b'
}

$callerMap = Get-CallerMap
$functionRows = Get-FunctionRows

$report = foreach ($func in $functionRows) {
    $objectInfo = Get-ObjectInfo -RelativeFile $func.File
    $signatureText = Get-FunctionSignatureText -Signature $func.Signature -RelativeFile $func.File -StartLine $func.StartLine
    $local = Test-FunctionIsLocal -RelativeFile $func.File -StartLine $func.StartLine
    $callers = if ($callerMap.ContainsKey($func.QualifiedName)) { @($callerMap[$func.QualifiedName]) } else { @() }
    $callerList = @($callers)

    [pscustomobject]@{
        Function         = $func.Name
        QualifiedName    = $func.QualifiedName
        Object           = $objectInfo.ObjectContext
        MainTableObject  = $objectInfo.MainTableObject
        Local            = $local
        Parameters       = if ($signatureText -match '\((?<params>.*)\)') { $Matches.params.Trim() } else { $null }
        Callers          = if ($callerList.Count -gt 0) { $callerList -join '; ' } else { '<none>' }
        CallerCount      = $callerList.Count
        File             = $func.File
        Lines            = "$($func.StartLine)-$($func.EndLine)"
    }
}

$report | Sort-Object Object, Function | Format-Table -AutoSize
