$ErrorActionPreference = 'Stop'
function Write-NaiyouJson([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path,($Value | ConvertTo-Json -Depth 64), [Text.UTF8Encoding]::new($false))
}
function Get-NaiyouDshRoot([string]$DataDir) {
    if ($DataDir) { return [IO.Path]::GetFullPath($DataDir) }
    if ($env:DSH_HOME) { return [IO.Path]::GetFullPath($env:DSH_HOME) }
    return Join-Path $env:USERPROFILE '.dsh'
}
function Find-NaiyouHarnessCli([string]$InstallDir) {
    if ($InstallDir) {
        $taskCli = Join-Path ([IO.Path]::GetFullPath($InstallDir)) 'resources\runtime\cli\bin\dsh.cmd'
        if (Test-Path -LiteralPath $taskCli) { return $taskCli }
        throw "没有在指定安装目录找到 DSH 命令：$InstallDir"
    }
    $taskSearchRoots = @((Join-Path $env:LOCALAPPDATA 'Programs'),$env:ProgramFiles,${env:ProgramFiles(x86)}) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    foreach ($taskSearchRoot in $taskSearchRoots) {
        foreach ($taskDir in @(Get-ChildItem -LiteralPath $taskSearchRoot -Directory -Filter 'DeepSeek*' | Sort-Object LastWriteTime -Descending)) {
            $taskCli=Join-Path $taskDir.FullName 'resources\runtime\cli\bin\dsh.cmd'
            if (Test-Path -LiteralPath $taskCli) { return $taskCli }
        }
    }
    $taskCommand=Get-Command dsh.cmd,dsh -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($taskCommand -and $taskCommand.Path) { return $taskCommand.Path }
    throw '没有找到 DeepSeek Harness。请先安装桌面版，或使用 -HarnessInstallDir 指定安装目录。'
}
function Invoke-NaiyouDsh([string]$Cli, [string]$DataDir, [string[]]$Arguments) {
    $taskPrevious=[Environment]::GetEnvironmentVariable('DSH_HOME','Process')
    try {
        [Environment]::SetEnvironmentVariable('DSH_HOME',$DataDir,'Process')
        & $Cli @Arguments
        if ($LASTEXITCODE -ne 0) { throw "DSH 命令失败，退出码：$LASTEXITCODE" }
    } finally { [Environment]::SetEnvironmentVariable('DSH_HOME',$taskPrevious,'Process') }
}
function Backup-NaiyouProfile([string]$Profile, [string]$BackupRoot) {
    $taskBackup=Join-Path $BackupRoot ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $taskBackup -Force | Out-Null
    foreach($taskFile in @('package.json','cordis.patch.yml','pnpm-lock.yaml','pnpm-workspace.yaml')) {
        $taskPath=Join-Path $Profile $taskFile
        if(Test-Path -LiteralPath $taskPath){Copy-Item -LiteralPath $taskPath -Destination (Join-Path $taskBackup $taskFile)}
    }
    return $taskBackup
}

