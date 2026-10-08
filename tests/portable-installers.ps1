$ErrorActionPreference='Stop'
$taskRepo=Split-Path -Parent $PSScriptRoot
$taskTempBase=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$taskTemp=Join-Path $taskTempBase ('naiyou-test-' + [Guid]::NewGuid().ToString('N'))
$taskWork=Join-Path $taskTemp '测试 user with spaces'
$taskPS=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
New-Item -ItemType Directory -Path $taskWork -Force | Out-Null
function Assert-Naiyou($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Run-NaiyouScript([string]$Path,[string[]]$ScriptArguments){
    & $taskPS -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArguments
    if($LASTEXITCODE -ne 0){throw "Failed: $Path"}
}
function Put-NaiyouJson([string]$Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false))}
try{
    $taskCodex=Join-Path $taskWork 'codex data'
    $taskInstall=Join-Path $taskRepo 'codex\install.ps1'
    $taskUninstall=Join-Path $taskRepo 'codex\uninstall.ps1'
    Run-NaiyouScript $taskInstall @('-CodexDataDir',$taskCodex,'-DryRun')
    Assert-Naiyou (-not(Test-Path -LiteralPath $taskCodex)) 'DryRun wrote files.'
    Run-NaiyouScript $taskInstall @('-CodexDataDir',$taskCodex)
    Run-NaiyouScript $taskInstall @('-CodexDataDir',$taskCodex)
    $taskPet=Join-Path $taskCodex 'pets\naiyou-community'
    $taskPetJson=Get-Content -LiteralPath (Join-Path $taskPet 'pet.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Naiyou ($taskPetJson.spriteVersionNumber -eq 2) 'Incorrect Codex version.'
    Assert-Naiyou ($taskPetJson.displayName -eq '奶邮') 'Chinese pet name corrupted.'
    $taskBytes=[IO.File]::ReadAllBytes((Join-Path $taskPet 'pet.json'))
    Assert-Naiyou ($taskBytes[0] -eq 123) 'Manifest contains a UTF8 BOM.'
    Assert-Naiyou ((Get-FileHash -LiteralPath (Join-Path $taskPet 'spritesheet.png')).Hash -eq (Get-FileHash -LiteralPath (Join-Path $taskRepo 'codex\pet\spritesheet.png')).Hash) 'Sprite changed.'
    [IO.File]::WriteAllText((Join-Path $taskPet 'keep.txt'),'preserve')
    Run-NaiyouScript $taskUninstall @('-CodexDataDir',$taskCodex)
    Assert-Naiyou (Test-Path -LiteralPath (Join-Path $taskPet 'keep.txt')) 'Uninstaller removed unrelated files.'
    Assert-Naiyou (-not(Test-Path -LiteralPath (Join-Path $taskPet 'pet.json'))) 'Uninstall left active pet.'
    $taskConflict=Join-Path $taskWork 'conflict'
    New-Item -ItemType Directory -Path (Join-Path $taskConflict 'pets\naiyou-community') -Force|Out-Null
    $taskPriorPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        & $taskPS -NoProfile -ExecutionPolicy Bypass -File $taskInstall -CodexDataDir $taskConflict 2>$null | Out-Null
        $taskConflictExit=$LASTEXITCODE
    } finally { $ErrorActionPreference=$taskPriorPreference }
    Assert-Naiyou ($taskConflictExit -ne 0) 'Installer overwrote an unowned directory.'
    Write-Output 'PASS: Codex offline install/update/uninstall, Unicode paths, manifest encoding, backups, and ownership'

    # A small CLI fixture reproduces an incomplete local package cache without depending on a DSH account.
    $taskHarness=Join-Path $taskWork 'Harness app'
    $taskBin=Join-Path $taskHarness 'resources\runtime\cli\bin'
    New-Item -ItemType Directory -Path $taskBin -Force|Out-Null
    [IO.File]::WriteAllText((Join-Path $taskBin 'dsh.cmd'),"@echo off`r`nnode `"%~dp0shim.js`" %*`r`nexit /b %errorlevel%`r`n",[Text.UTF8Encoding]::new($false))
    $taskShim=@'
const fs=require('node:fs'),path=require('node:path');
const args=process.argv.slice(2),profile=path.join(process.env.DSH_HOME,'profiles/desktop');
const file=path.join(profile,'package.json'),manifest=JSON.parse(fs.readFileSync(file,'utf8'));
if(args[0]!=='plugin'||args[1]!=='--profile'||args[2]!=='desktop')throw Error('unexpected CLI arguments');
if(args[3]==='add'){
  if(args[4]!=='--offline'||!args[5].startsWith('file:'))throw Error('expected offline local install');
  manifest.dependencies['@local/dsh-naiyou-pet']=args[5];
  const installed=path.join(profile,'node_modules/@local/dsh-naiyou-pet');fs.mkdirSync(installed,{recursive:true});
  fs.copyFileSync(path.join(args[5].slice(5),'package.json'),path.join(installed,'package.json'));
}else if(args[3]==='remove'){delete manifest.dependencies['@local/dsh-naiyou-pet'];}
else throw Error('unexpected CLI action');
fs.writeFileSync(file,JSON.stringify(manifest));
'@
    [IO.File]::WriteAllText((Join-Path $taskBin 'shim.js'),$taskShim,[Text.UTF8Encoding]::new($false))
    $taskDsh=Join-Path $taskWork 'dsh data'
    $taskProfile=Join-Path $taskDsh 'profiles\desktop'
    New-Item -ItemType Directory -Path $taskProfile -Force|Out-Null
    $taskManifestPath=Join-Path $taskProfile 'package.json'
    Put-NaiyouJson $taskManifestPath @{name='fixture';private=$true;dependencies=@{'existing-plugin'='file:preserve'};dsh=@{profile=@{bundles=@('@deepseek-ai/dsh-base','existing-plugin')}};custom=@{keep='unchanged'}}
    [IO.File]::WriteAllText((Join-Path $taskProfile 'cordis.patch.yml'),'[]')
    $taskDestination=Join-Path $taskWork 'stable plugin'
    $taskArgs=@('-HarnessInstallDir',$taskHarness,'-DshDataDir',$taskDsh,'-DestinationDir',$taskDestination)
    Run-NaiyouScript (Join-Path $taskRepo 'dsh\install.ps1') ($taskArgs+@('-DryRun'))
    Assert-Naiyou (-not(Test-Path -LiteralPath $taskDestination)) 'DSH dry run copied plugin.'
    Run-NaiyouScript (Join-Path $taskRepo 'dsh\install.ps1') $taskArgs
    Run-NaiyouScript (Join-Path $taskRepo 'dsh\install.ps1') $taskArgs
    $taskActual=Get-Content -LiteralPath $taskManifestPath -Raw -Encoding UTF8|ConvertFrom-Json
    Assert-Naiyou ($taskActual.custom.keep -eq 'unchanged') 'DSH custom config lost.'
    Assert-Naiyou ($taskActual.dependencies.'existing-plugin' -eq 'file:preserve') 'Other dependency lost.'
    Assert-Naiyou ($taskActual.dsh.profile.bundles -contains 'existing-plugin') 'Other bundle lost.'
    Assert-Naiyou (@($taskActual.dsh.profile.bundles|Where-Object{$_ -eq '@local/dsh-naiyou-pet'}).Count -eq 1) 'Duplicate pet bundle.'
    $taskPkg=Get-Content -LiteralPath (Join-Path $taskDestination 'package.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($taskFile in @('package.json')+@($taskPkg.files)){
        Assert-Naiyou ((Get-FileHash -LiteralPath (Join-Path $taskDestination $taskFile)).Hash -eq (Get-FileHash -LiteralPath (Join-Path $taskProfile ('node_modules\@local\dsh-naiyou-pet\'+$taskFile))).Hash) 'Incomplete package cache.'
    }
    Run-NaiyouScript (Join-Path $taskRepo 'dsh\uninstall.ps1') @('-HarnessInstallDir',$taskHarness,'-DshDataDir',$taskDsh)
    $taskActual=Get-Content -LiteralPath $taskManifestPath -Raw -Encoding UTF8|ConvertFrom-Json
    Assert-Naiyou ($taskActual.dsh.profile.bundles -notcontains '@local/dsh-naiyou-pet') 'Uninstall left pet enabled.'
    Assert-Naiyou ($taskActual.dependencies.'existing-plugin' -eq 'file:preserve') 'Uninstall changed other dependency.'
    Assert-Naiyou (-not $taskActual.dependencies.PSObject.Properties['@local/dsh-naiyou-pet']) 'Uninstall left dependency.'
    Write-Output 'PASS: DSH install/update/uninstall, partial cache repair, configuration preservation, stable paths, and offline arguments'

    . (Join-Path $taskRepo 'dsh\plugin\launch-harness.ps1')
    $taskFakeExe=Join-Path $taskHarness 'DeepSeek Harness.exe'
    [IO.File]::WriteAllText($taskFakeExe,'fixture')
    function Start-Process {param([string]$FilePath);$script:capturedPath=$FilePath;$script:capturedMode=[Environment]::GetEnvironmentVariable('ELECTRON_RUN_AS_NODE','Process')}
    $taskPriorMode=[Environment]::GetEnvironmentVariable('ELECTRON_RUN_AS_NODE','Process')
    try{
        [Environment]::SetEnvironmentVariable('ELECTRON_RUN_AS_NODE','1','Process')
        $taskOpened=Open-NaiyouHarness $taskFakeExe
        Assert-Naiyou $taskOpened 'Harness launch was not attempted.'
        Assert-Naiyou ($script:capturedPath -eq $taskFakeExe) 'Wrong executable path.'
        Assert-Naiyou (-not $script:capturedMode) 'Electron Node mode leaked into desktop launch.'
        Assert-Naiyou ([Environment]::GetEnvironmentVariable('ELECTRON_RUN_AS_NODE','Process') -eq '1') 'Environment not restored.'
    }finally{[Environment]::SetEnvironmentVariable('ELECTRON_RUN_AS_NODE',$taskPriorMode,'Process');Remove-Item Function:\Start-Process}
    Write-Output 'PASS: desktop launch clears and restores inherited Electron Node mode'
}finally{
    $taskFinal=[IO.Path]::GetFullPath($taskTemp)
    $taskAllowed=$taskTempBase.TrimEnd('\')+'\'
    if($taskFinal.StartsWith($taskAllowed,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $taskFinal) -match '^naiyou-test-[0-9a-f]{32}$'){
        Remove-Item -LiteralPath $taskFinal -Recurse -Force
    }else{throw 'Unexpected cleanup target.'}
}
