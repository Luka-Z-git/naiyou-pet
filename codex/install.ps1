param([string]$CodexDataDir, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
if (-not $CodexDataDir) {
    $CodexDataDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
}
$taskRoot = [IO.Path]::GetFullPath($CodexDataDir)
$taskTarget = Join-Path $taskRoot 'pets\naiyou-community'
$taskSource = Join-Path $PSScriptRoot 'pet'
$taskMarker = Join-Path $taskTarget '.naiyou-package'
$taskMeta = Get-Content -LiteralPath (Join-Path $taskSource 'pet.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($taskMeta.spriteVersionNumber -ne 2 -or $taskMeta.spritesheetPath -ne 'spritesheet.png') { throw 'Unexpected pet manifest.' }
$taskImage = [IO.File]::ReadAllBytes((Join-Path $taskSource 'spritesheet.png'))
if ($taskImage.Length -lt 24 -or [BitConverter]::ToString($taskImage[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') { throw 'Invalid sprite PNG.' }
$taskWidth = [BitConverter]::ToUInt32([byte[]]@($taskImage[19],$taskImage[18],$taskImage[17],$taskImage[16]),0)
$taskHeight = [BitConverter]::ToUInt32([byte[]]@($taskImage[23],$taskImage[22],$taskImage[21],$taskImage[20]),0)
if ($taskWidth -ne 1536 -or $taskHeight -ne 2288) { throw 'Expected a 1536 x 2288 v2 sprite sheet.' }
if (Test-Path -LiteralPath $taskTarget) {
    if (-not (Test-Path -LiteralPath $taskMarker) -or (Get-Content -LiteralPath $taskMarker -Raw).Trim() -ne 'naiyou-codex-v1') {
        throw "目录已存在且不属于本安装包，未覆盖：$taskTarget"
    }
}
if ($DryRun) { Write-Output "将安装到：$taskTarget"; return }
if (Test-Path -LiteralPath $taskTarget) {
    $taskBackup = Join-Path $taskRoot ('naiyou-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $taskBackup -Force | Out-Null
    foreach ($taskFile in @('pet.json','spritesheet.png','.naiyou-package')) {
        $taskOld = Join-Path $taskTarget $taskFile
        if (Test-Path -LiteralPath $taskOld) { Copy-Item -LiteralPath $taskOld -Destination (Join-Path $taskBackup $taskFile) }
    }
    Write-Output "原奶邮已备份：$taskBackup"
}
New-Item -ItemType Directory -Path $taskTarget -Force | Out-Null
foreach ($taskFile in @('pet.json','spritesheet.png')) { Copy-Item -LiteralPath (Join-Path $taskSource $taskFile) -Destination (Join-Path $taskTarget $taskFile) -Force }
[IO.File]::WriteAllText($taskMarker,'naiyou-codex-v1', [Text.UTF8Encoding]::new($false))
Write-Output "奶邮已安装：$taskTarget"
Write-Output '打开 Codex 的宠物设置，点击刷新，再选择奶邮；如果没有出现，请重新打开应用。'

