param([string]$CodexDataDir, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
if (-not $CodexDataDir) { $CodexDataDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' } }
$taskRoot = [IO.Path]::GetFullPath($CodexDataDir)
$taskTarget = [IO.Path]::GetFullPath((Join-Path $taskRoot 'pets\naiyou-community'))
$taskAllowed = [IO.Path]::GetFullPath((Join-Path $taskRoot 'pets')) + [IO.Path]::DirectorySeparatorChar
if (-not $taskTarget.StartsWith($taskAllowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected target directory.' }
$taskMarker = Join-Path $taskTarget '.naiyou-package'
if (-not (Test-Path -LiteralPath $taskMarker)) { Write-Output '没有找到本安装包安装的奶邮。'; return }
if ((Get-Content -LiteralPath $taskMarker -Raw).Trim() -ne 'naiyou-codex-v1') { throw '目录不属于本安装包。' }
if ($DryRun) { Write-Output "将卸载：$taskTarget"; return }
$taskBackup = Join-Path $taskRoot ('naiyou-backups\uninstall-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $taskBackup -Force | Out-Null
foreach ($taskFile in @('pet.json','spritesheet.png','.naiyou-package')) {
    $taskPath = Join-Path $taskTarget $taskFile
    if (Test-Path -LiteralPath $taskPath) { Copy-Item -LiteralPath $taskPath -Destination (Join-Path $taskBackup $taskFile); Remove-Item -LiteralPath $taskPath }
}
if (@(Get-ChildItem -LiteralPath $taskTarget -Force).Count -eq 0) { Remove-Item -LiteralPath $taskTarget }
Write-Output "奶邮已卸载，备份保留在：$taskBackup"
Write-Output '在 Codex 的宠物设置中刷新列表并选择其他宠物。'

