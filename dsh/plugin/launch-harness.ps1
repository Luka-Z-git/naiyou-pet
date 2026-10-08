function Open-NaiyouHarness([string]$HarnessExecutable) {
    if (-not $HarnessExecutable -or -not (Test-Path -LiteralPath $HarnessExecutable)) {
        $taskAppsRoot = Join-Path $env:LOCALAPPDATA 'Programs'
        $HarnessExecutable = $null
        if (Test-Path -LiteralPath $taskAppsRoot) {
            foreach ($taskDirectory in @(Get-ChildItem -LiteralPath $taskAppsRoot -Directory -Filter 'DeepSeek*' | Sort-Object LastWriteTime -Descending)) {
                $taskCandidate = Join-Path $taskDirectory.FullName 'DeepSeek Harness.exe'
                if (Test-Path -LiteralPath $taskCandidate) { $HarnessExecutable=$taskCandidate; break }
            }
        }
    }
    if (-not $HarnessExecutable) { return $false }
    # The Harness host runs Electron in Node mode; a desktop launch must clear this inherited flag.
    $taskNodeMode = [Environment]::GetEnvironmentVariable('ELECTRON_RUN_AS_NODE','Process')
    try {
        [Environment]::SetEnvironmentVariable('ELECTRON_RUN_AS_NODE',$null,'Process')
        Start-Process -FilePath $HarnessExecutable | Out-Null
    } finally { [Environment]::SetEnvironmentVariable('ELECTRON_RUN_AS_NODE',$taskNodeMode,'Process') }
    return $true
}

