$env:MSYSTEM='UCRT64'; $env:CHERE_INVOKING='1';
$env:RUST_BACKTRACE=1;
$script = 'source /etc/profile; '
# Native Windows Node must win over MSYS2's mingw node (/ucrt64/bin/node):
# napi-rs addons (@tailwindcss/oxide via graph-ui) panic with
# "Node-API symbol has not been loaded" under the mingw build.
$script = $script + 'export PATH="/c/Program Files/nodejs:$PATH"; '
$script = $script + 'cd /c/Users/peter/Source/Repos/Everest/codebase-memory-mcp; '
$script = $script + 'CC=clang CXX=clang++ '
$Response = Read-Host "Do you want to build incrmentally? (y/n)"
if ($Response -eq 'y') {
    $script = $script + 'scripts/build-incremental.sh'
} else {
    $script = $script + 'scripts/build.sh'
}
$Response = Read-Host "Do you want to build with GUI? (y/n)"
if ($Response -eq 'y') {
    $withui = ' --with-ui '
} else {
    $withui = ''
}
$currentVersion = '0.47.02'
$response = Read-Host "Do you want to build with version $currentVersion? (y/n)"
if ($response -eq 'y') {
    $version = " --version dev.$currentVersion "
} else {
    $version = ''
}

$script = $script + $withui + $version
$response = Read-Host "Will run this script: $script
Do you want to continue? (y/n)"
if ($response -ne 'y') {
    Write-Host "Aborting the build."
    exit
}

# Stop the running daemon first — Windows locks a running exe, so the linker
# would otherwise fail with "cannot open output file ...: Permission denied".
$exe = 'C:\Users\peter\Source\Repos\Everest\codebase-memory-mcp\build\c\codebase-memory-mcp.exe'
if (Test-Path $exe) {
    Write-Host "Stopping daemon (graceful)..."
    & $exe daemon stop 2>$null
    Start-Sleep -Seconds 2
}
# Fallback: force-kill any leftover processes still holding the exe locked.
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $exe } |
    ForEach-Object {
        Write-Host "Force-stopping leftover process $($_.Id)..."
        Stop-Process -Id $_.Id -Force
    }

 & "C:\msys64\usr\bin\bash.exe" -lc $script
