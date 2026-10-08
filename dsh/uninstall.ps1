param([string]$HarnessInstallDir, [string]$DshDataDir, [switch]$DryRun)
. (Join-Path $PSScriptRoot 'common.ps1')
$taskDshRoot=Get-NaiyouDshRoot $DshDataDir
$taskProfile=Join-Path $taskDshRoot 'profiles\desktop'
$taskManifestPath=Join-Path $taskProfile 'package.json'
if(-not(Test-Path -LiteralPath $taskManifestPath)){Write-Output '没有找到 DSH 桌面配置。';return}
$taskManifest=Get-Content -LiteralPath $taskManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if($DryRun){Write-Output "将从 $taskProfile 移除奶邮的启用项与依赖。";return}
$taskBackup=Backup-NaiyouProfile $taskProfile (Join-Path $taskDshRoot 'naiyou-backups')
if($taskManifest.dsh -and $taskManifest.dsh.profile -and $taskManifest.dsh.profile.PSObject.Properties['bundles']){
    $taskManifest.dsh.profile.bundles=@($taskManifest.dsh.profile.bundles | Where-Object {$_ -ne '@local/dsh-naiyou-pet'})
}
Write-NaiyouJson $taskManifestPath $taskManifest
try{
    $taskCli=Find-NaiyouHarnessCli $HarnessInstallDir
    Invoke-NaiyouDsh $taskCli $taskDshRoot @('plugin','--profile','desktop','remove','@local/dsh-naiyou-pet')
}catch{
    $taskManifest=Get-Content -LiteralPath $taskManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if($taskManifest.dependencies){$taskManifest.dependencies.PSObject.Properties.Remove('@local/dsh-naiyou-pet')}
    Write-NaiyouJson $taskManifestPath $taskManifest
    Write-Output ('已停用奶邮并移除依赖；DSH 包管理清理未完成：' + $_.Exception.Message)
}
Write-Output "奶邮已卸载。配置备份：$taskBackup"
Write-Output '请完整退出并重新打开 DSH。插件文件、偏好和备份保留在本机。'

