param([string]$HarnessInstallDir, [string]$DshDataDir, [string]$DestinationDir, [switch]$DryRun)
. (Join-Path $PSScriptRoot 'common.ps1')
$taskCli=Find-NaiyouHarnessCli $HarnessInstallDir
$taskDshRoot=Get-NaiyouDshRoot $DshDataDir
$taskProfile=Join-Path $taskDshRoot 'profiles\desktop'
$taskManifestPath=Join-Path $taskProfile 'package.json'
if(-not (Test-Path -LiteralPath $taskManifestPath)){throw '请先打开一次 DSH 桌面版，以生成 desktop 配置，然后再安装奶邮。'}
$taskDestination=if($DestinationDir){[IO.Path]::GetFullPath($DestinationDir)}else{Join-Path $env:LOCALAPPDATA 'DSH\Pets\naiyou\plugin'}
$taskSource=Join-Path $PSScriptRoot 'plugin'
$taskManifest=Get-Content -LiteralPath (Join-Path $taskSource 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if($taskManifest.name -ne '@local/dsh-naiyou-pet'){throw 'Unexpected plugin identity.'}
$taskFiles=@('package.json') + @($taskManifest.files)
foreach($taskFile in $taskFiles){if($taskFile -match '[\\/]' -or $taskFile -eq '..' -or -not(Test-Path -LiteralPath (Join-Path $taskSource $taskFile))){throw 'Unexpected or missing package file.'}}
if(Test-Path -LiteralPath (Join-Path $taskDestination 'package.json')) {
    $taskOld=Get-Content -LiteralPath (Join-Path $taskDestination 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if($taskOld.name -ne $taskManifest.name){throw '目标目录包含其他包，未覆盖。'}
}
if($DryRun){Write-Output "DSH：$taskCli";Write-Output "配置：$taskProfile";Write-Output "插件：$taskDestination";return}
$taskBackup=Backup-NaiyouProfile $taskProfile (Join-Path $taskDshRoot 'naiyou-backups')
New-Item -ItemType Directory -Path $taskDestination -Force | Out-Null
foreach($taskFile in $taskFiles){
    $taskFrom=Join-Path $taskSource $taskFile;$taskTo=Join-Path $taskDestination $taskFile
    if((-not(Test-Path -LiteralPath $taskTo)) -or (Get-FileHash -LiteralPath $taskFrom).Hash -ne (Get-FileHash -LiteralPath $taskTo).Hash){Copy-Item -LiteralPath $taskFrom -Destination $taskTo -Force}
}
try {
    Invoke-NaiyouDsh $taskCli $taskDshRoot @('plugin','--profile','desktop','add','--offline',('file:' + $taskDestination.Replace('\','/')))
    # Refresh the cached file list of this local package, including newly added files.
    $taskInstalled=Join-Path $taskProfile 'node_modules\@local\dsh-naiyou-pet'
    if(-not(Test-Path -LiteralPath $taskInstalled)){throw 'DSH did not materialize the plugin.'}
    foreach($taskFile in $taskFiles){
        $taskFrom=Join-Path $taskDestination $taskFile;$taskTo=Join-Path $taskInstalled $taskFile
        if((-not(Test-Path -LiteralPath $taskTo)) -or (Get-FileHash -LiteralPath $taskFrom).Hash -ne (Get-FileHash -LiteralPath $taskTo).Hash){Copy-Item -LiteralPath $taskFrom -Destination $taskTo -Force}
    }
    $taskProfileManifest=Get-Content -LiteralPath $taskManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if(-not $taskProfileManifest.dsh){$taskProfileManifest | Add-Member -NotePropertyName dsh -NotePropertyValue ([pscustomobject]@{})}
    if(-not $taskProfileManifest.dsh.profile){$taskProfileManifest.dsh | Add-Member -NotePropertyName profile -NotePropertyValue ([pscustomobject]@{})}
    if(-not $taskProfileManifest.dsh.profile.PSObject.Properties['bundles']){$taskProfileManifest.dsh.profile | Add-Member -NotePropertyName bundles -NotePropertyValue @()}
    if($taskProfileManifest.dsh.profile.bundles -notcontains $taskManifest.name){$taskProfileManifest.dsh.profile.bundles=@($taskProfileManifest.dsh.profile.bundles) + $taskManifest.name}
    Write-NaiyouJson $taskManifestPath $taskProfileManifest
} catch {throw "安装未完成；配置备份：$taskBackup。原因：$($_.Exception.Message)"}
Write-Output "奶邮已安装：$taskDestination"
Write-Output "配置备份：$taskBackup"
Write-Output '请从系统托盘完整退出 DSH，再重新打开。解压文件夹现在可以移动或删除，插件已复制到固定位置。'

