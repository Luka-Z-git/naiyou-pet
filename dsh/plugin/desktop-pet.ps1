param(
    [Parameter(Mandatory=$true)][string]$StateFile,
    [Parameter(Mandatory=$true)][string]$SpriteFile,
    [string]$HarnessExe,
    [string]$PreferencesDir = (Join-Path $env:LOCALAPPDATA 'DSH\Naiyou'),
    [string]$PreviewOutput,
    [int]$AutoCloseSeconds = 0
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'launch-harness.ps1')
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
$taskHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($StateFile)))).Replace('-','')
$taskMutex = New-Object System.Threading.Mutex($false, ('Local\DSH-Naiyou-' + $taskHash.Substring(0,24)))
if (-not $taskMutex.WaitOne(0)) { $taskMutex.Dispose(); exit 0 }
New-Item -ItemType Directory -Path $PreferencesDir -Force | Out-Null
$script:prefsFile = Join-Path $PreferencesDir 'desktop-preferences.json'
$script:prefs = @{ x=$null; y=$null; size=88; compact=$false; sound=$true; paused=$false }
try {
    $saved = Get-Content -LiteralPath $script:prefsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($key in @('x','y','size','compact','sound','paused')) { if ($null -ne $saved.$key) { $script:prefs[$key] = $saved.$key } }
} catch {}
$script:prefs.size = [Math]::Max(64, [Math]::Min(128, [double]$script:prefs.size))
$script:state = $null
$script:seen = New-Object 'System.Collections.Generic.HashSet[string]'
$script:row = 0
$script:frame = 0
$script:lastRow = -1
$script:counts = @(6,8,8,4,5,8,6,6,6)
$script:closed = $false
$script:started = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$script:previewDone = $false
$script:previewKey = ''

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="奶邮 · DeepSeek Harness" Width="372" Height="175" WindowStyle="None" ResizeMode="NoResize"
 AllowsTransparency="True" Background="Transparent" Topmost="True" ShowInTaskbar="False" ShowActivated="False"
 FontFamily="Microsoft YaHei UI" UseLayoutRounding="True">
 <Grid x:Name="Root" Margin="5">
  <Grid.ColumnDefinitions><ColumnDefinition Width="102"/><ColumnDefinition Width="255"/></Grid.ColumnDefinitions>
  <StackPanel Grid.Column="0" VerticalAlignment="Bottom">
   <Image x:Name="Sprite" Width="88" Height="96" Stretch="Uniform" ToolTip="拖动奶邮；双击打开 Harness；右键设置"/>
   <Border Background="#EDFFFFFF" CornerRadius="12" Padding="8,3" HorizontalAlignment="Center">
    <TextBlock Text="奶邮" Foreground="#256479" FontWeight="SemiBold" FontSize="12"/>
   </Border>
  </StackPanel>
  <Border x:Name="Card" Grid.Column="1" Background="#F7FFFFFF" BorderBrush="#A9D9E4" BorderThickness="1" CornerRadius="14" Padding="12" VerticalAlignment="Center">
   <StackPanel>
    <TextBlock x:Name="TitleLabel" Text="DeepSeek Harness" FontSize="11" Foreground="#62818C" TextTrimming="CharacterEllipsis" Margin="0,0,0,5"/>
    <TextBlock x:Name="ActionLabel" Text="正在连接 Harness…" FontSize="13" FontWeight="SemiBold" Foreground="#24586B" TextWrapping="Wrap" MaxHeight="42"/>
    <TextBlock x:Name="TokenLabel" Text="Token · 等待服务报告用量" FontSize="11" Foreground="#577482" Margin="0,8,0,0"/>
    <TextBlock x:Name="BreakdownLabel" FontSize="10" Foreground="#6C8590" Margin="0,3,0,0"/>
    <Grid Margin="0,8,0,0">
     <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
     <Button x:Name="OpenButton" Content="打开 Harness ↗" HorizontalAlignment="Left" Padding="6,3" Background="#E8F3F7" BorderThickness="0" Foreground="#24637B" FontSize="11"/>
     <Button x:Name="CollapseButton" Grid.Column="1" Content="收起" Padding="6,3" Background="Transparent" BorderThickness="0" Foreground="#6C8590" FontSize="11"/>
    </Grid>
   </StackPanel>
  </Border>
 </Grid>
</Window>
'@
$script:window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach ($name in @('Root','Sprite','Card','TitleLabel','ActionLabel','TokenLabel','BreakdownLabel','OpenButton','CollapseButton')) { Set-Variable -Scope Script -Name $name -Value $script:window.FindName($name) }
$sheet = New-Object Windows.Media.Imaging.BitmapImage
$sheet.BeginInit(); $sheet.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$sheet.UriSource = New-Object Uri([IO.Path]::GetFullPath($SpriteFile)); $sheet.EndInit(); $sheet.Freeze()
if ($sheet.PixelWidth -ne 1536 -or $sheet.PixelHeight -ne 2288) { throw 'Invalid v2 sprite sheet dimensions.' }
$script:frames = @{}
for ($row=0; $row -lt 9; $row++) {
    $script:frames[$row] = @()
    for ($col=0; $col -lt $script:counts[$row]; $col++) {
        $crop = New-Object Windows.Media.Imaging.CroppedBitmap($sheet, (New-Object Windows.Int32Rect(($col*192),($row*208),192,208)))
        $crop.Freeze(); $script:frames[$row] += $crop
    }
}
$script:Sprite.Source = $script:frames[0][0]
$script:row = 0

function Save-Preferences {
    $script:prefs.x = $script:window.Left; $script:prefs.y = $script:window.Top
    $script:prefs | ConvertTo-Json | Set-Content -LiteralPath $script:prefsFile -Encoding UTF8
}
function Fit-Window {
    $script:Sprite.Width = $script:prefs.size
    $script:Sprite.Height = $script:prefs.size * 208 / 192
    $script:window.Width = if ($script:prefs.compact) { 116 } else { 372 }
    $script:Card.Visibility = if ($script:prefs.compact) { 'Collapsed' } else { 'Visible' }
    $script:window.Height = [Math]::Max(175, $script:Sprite.Height + 38)
    # Keep the small overlay inside the virtual desktop bounds.
    $minX = [Windows.SystemParameters]::VirtualScreenLeft
    $minY = [Windows.SystemParameters]::VirtualScreenTop
    $maxX = $minX + [Windows.SystemParameters]::VirtualScreenWidth - $script:window.Width
    $maxY = $minY + [Windows.SystemParameters]::VirtualScreenHeight - $script:window.Height
    $script:window.Left = [Math]::Max($minX, [Math]::Min($maxX, $script:window.Left))
    $script:window.Top = [Math]::Max($minY, [Math]::Min($maxY, $script:window.Top))
}
function Open-Harness {
    if (-not (Open-NaiyouHarness $HarnessExe)) { $script:ActionLabel.Text='没有找到 Harness 程序，请检查安装路径' }
}
function Show-Pet {
    $script:window.Show(); Fit-Window
}
$area = [Windows.SystemParameters]::WorkArea
$script:window.Left = if ($null -eq $script:prefs.x) { $area.Right - 392 } else { [double]$script:prefs.x }
$script:window.Top = if ($null -eq $script:prefs.y) { $area.Bottom - 205 } else { [double]$script:prefs.y }
Fit-Window
$script:OpenButton.Add_Click({ Open-Harness })
$script:CollapseButton.Add_Click({ $script:prefs.compact=$true; Fit-Window; Save-Preferences })
$script:Sprite.Add_MouseLeftButtonDown({
    param($sender,$e)
    if ($e.ClickCount -eq 2) { Open-Harness }
    else { $script:window.DragMove(); Fit-Window; Save-Preferences }
    $e.Handled=$true
})
$script:TitleLabel.Add_MouseLeftButtonDown({ $script:window.DragMove(); Fit-Window; Save-Preferences })

$menu = New-Object Windows.Controls.ContextMenu
function Add-MenuItem([string]$label, [scriptblock]$handler) {
    $item = New-Object Windows.Controls.MenuItem
    $item.Header = $label; $item.Add_Click($handler); [void]$menu.Items.Add($item)
}
Add-MenuItem '打开 Harness' { Open-Harness }
Add-MenuItem '显示 / 收起详情' { $script:prefs.compact = -not $script:prefs.compact; Fit-Window; Save-Preferences }
Add-MenuItem '小 · 64' { $script:prefs.size=64; Fit-Window; Save-Preferences }
Add-MenuItem '中 · 88' { $script:prefs.size=88; Fit-Window; Save-Preferences }
Add-MenuItem '大 · 120' { $script:prefs.size=120; Fit-Window; Save-Preferences }
Add-MenuItem '暂停 / 恢复动画' { $script:prefs.paused = -not $script:prefs.paused; Save-Preferences }
Add-MenuItem '开启 / 关闭批准提示音' { $script:prefs.sound = -not $script:prefs.sound; Save-Preferences }
Add-MenuItem '暂时隐藏（托盘可恢复）' { $script:window.Hide() }
Add-MenuItem '本次退出奶邮' { $script:window.Close() }
$script:window.ContextMenu=$menu

$script:tray = New-Object Windows.Forms.NotifyIcon
$script:tray.Icon = [Drawing.SystemIcons]::Information
$script:tray.Text = '奶邮 · DeepSeek Harness'
$script:tray.Visible = $true
$trayMenu = New-Object Windows.Forms.ContextMenuStrip
$trayShow = $trayMenu.Items.Add('显示奶邮'); $trayShow.Add_Click({ Show-Pet })
$trayOpen = $trayMenu.Items.Add('打开 Harness'); $trayOpen.Add_Click({ Open-Harness })
$trayExit = $trayMenu.Items.Add('本次退出奶邮'); $trayExit.Add_Click({ $script:window.Close() })
$script:tray.ContextMenuStrip=$trayMenu
$script:tray.Add_Click({ param($s,$e) if ($e.Button -eq [Windows.Forms.MouseButtons]::Left) { Show-Pet } })
$script:tray.Add_BalloonTipClicked({ Open-Harness })

function Update-State {
    try {
        $next = [IO.File]::ReadAllText($StateFile, [Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($next.version -ne 2) { return }
        $script:state = $next
    } catch {
        if ($null -eq $script:state) {
            if ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:started -gt 45000) { $script:window.Close() }
            return
        }
        $next=$script:state
    }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    if (-not $next.connected) { $script:window.Close(); return }
    if ($next.ownerPid -gt 0 -and -not (Get-Process -Id $next.ownerPid -ErrorAction SilentlyContinue)) { $script:window.Close(); return }
    if ($now - $next.updatedAt -gt 15000) {
        $script:ActionLabel.Text='Harness 连接已中断'
        $script:TokenLabel.Text='Token · 暂停更新'; $script:BreakdownLabel.Text=''
        $script:row=7
        if ($now - $next.updatedAt -gt 45000) { $script:window.Close() }
        return
    }
    $script:TitleLabel.Text=$next.title
    $script:TitleLabel.ToolTip=$next.title
    $script:ActionLabel.Text=$next.action
    $script:ActionLabel.ToolTip=$next.action
    $script:row = switch ($next.phase) { 'approval' {7} 'thinking' {5} 'writing' {6} 'tool' {6} 'done' {8} 'error' {7} default {0} }
    if ($next.phase -eq 'approval') {
        $script:Card.BorderBrush=[Windows.Media.BrushConverter]::new().ConvertFromString('#F2B453')
        $script:Card.Background=[Windows.Media.BrushConverter]::new().ConvertFromString('#FFFFF7E5')
        $script:OpenButton.Content='去 Harness 批准 ↗'
    } else {
        $script:Card.BorderBrush=[Windows.Media.BrushConverter]::new().ConvertFromString('#A9D9E4')
        $script:Card.Background=[Windows.Media.BrushConverter]::new().ConvertFromString('#F7FFFFFF')
        $script:OpenButton.Content='打开 Harness ↗'
    }
    if ($null -ne $next.tokens) {
        $script:TokenLabel.Text=('会话 Token  {0:N0}' -f [double]$next.tokens.total)
        $script:BreakdownLabel.Text=('输入 {0:N0} · 输出 {1:N0}' -f [double]$next.tokens.input,[double]$next.tokens.output)
        $tip=('服务报告用量；流式请求结束时更新。输入包含缓存。缓存读取 {0:N0}；缓存写入 {1:N0}。' -f [double]$next.tokens.cacheRead,[double]$next.tokens.cacheWrite)
        $script:TokenLabel.ToolTip=$tip; $script:BreakdownLabel.ToolTip=$tip
    } else {
        $script:TokenLabel.Text='Token · 等待服务报告用量'; $script:BreakdownLabel.Text=''
    }
    $newPending=@($next.pending | Where-Object { $script:seen.Add($_.sessionId + ':' + $_.id) })
    if ($newPending.Count -gt 0) {
        # A pending request also restores a collapsed/hidden pet without stealing keyboard focus.
        $script:prefs.compact=$false; Show-Pet
        $script:tray.BalloonTipTitle='奶邮：Harness 需要你批准'
        $script:tray.BalloonTipText=$next.title + "`n" + $next.action
        $script:tray.BalloonTipIcon=[Windows.Forms.ToolTipIcon]::Warning
        $script:tray.ShowBalloonTip(8000)
        if ($script:prefs.sound) { [System.Media.SystemSounds]::Exclamation.Play() }
    }
}
$script:animation = New-Object Windows.Threading.DispatcherTimer
$script:animation.Interval=[TimeSpan]::FromMilliseconds(140)
$script:animation.Add_Tick({
    if ($script:window.IsVisible -and -not $script:prefs.paused) {
        if ($script:lastRow -ne $script:row) { $script:frame=0; $script:lastRow=$script:row }
        $script:Sprite.Source=$script:frames[$script:row][$script:frame % $script:counts[$script:row]]
        $script:frame++
    }
})
$script:poll = New-Object Windows.Threading.DispatcherTimer
$script:poll.Interval=[TimeSpan]::FromMilliseconds(350)
$script:poll.Add_Tick({
    try {
        Update-State
        $currentPreviewKey = if ($script:state) { $script:state.phase + '|' + $script:state.title + '|' + $script:TokenLabel.Text } else { '' }
        if ($PreviewOutput -and (-not $script:previewDone -or $script:previewKey -ne $currentPreviewKey) -and $script:state -and -not $script:closed) {
            $script:window.UpdateLayout()
            $bitmap=New-Object Windows.Media.Imaging.RenderTargetBitmap([int]$script:Root.ActualWidth,[int]$script:Root.ActualHeight,96,96,[Windows.Media.PixelFormats]::Pbgra32)
            $bitmap.Render($script:Root)
            $encoder=New-Object Windows.Media.Imaging.PngBitmapEncoder
            $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
            $stream=[IO.File]::Create($PreviewOutput); try { $encoder.Save($stream) } finally { $stream.Dispose() }
            $diagnostics=@{ topmost=$script:window.Topmost; showActivated=$script:window.ShowActivated; taskbar=$script:window.ShowInTaskbar; transparent=$script:window.AllowsTransparency; action=$script:ActionLabel.Text; tokens=$script:TokenLabel.Text; inputOutput=$script:BreakdownLabel.Text; approvalNotifications=$script:seen.Count; width=$script:window.Width; height=$script:window.Height; imageWidth=$script:Sprite.ActualWidth; imageHeight=$script:Sprite.ActualHeight }
            $diagnostics | ConvertTo-Json | Set-Content -LiteralPath ($PreviewOutput + '.json') -Encoding UTF8
            $script:previewDone=$true
            $script:previewKey=$currentPreviewKey
        }
        if ($AutoCloseSeconds -gt 0 -and ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:started) -ge ($AutoCloseSeconds*1000)) { $script:window.Close() }
    } catch { Write-Warning ('奶邮：' + $_.Exception.Message) }
})
$script:window.Add_Closed({ $script:closed=$true; $script:poll.Stop(); $script:animation.Stop(); $script:tray.Visible=$false; $script:tray.Dispose(); Save-Preferences })
try {
    $script:animation.Start(); $script:poll.Start()
    $taskApp = New-Object Windows.Application
    $taskApp.ShutdownMode = [Windows.ShutdownMode]::OnMainWindowClose
    [void]$taskApp.Run($script:window)
} catch {
    $_.Exception.ToString() | Set-Content -LiteralPath (Join-Path $PreferencesDir 'last-error.log') -Encoding UTF8
    throw
} finally {
    $script:poll.Stop(); $script:animation.Stop()
    if (-not $script:closed) { $script:tray.Visible=$false; $script:tray.Dispose() }
    $taskMutex.ReleaseMutex(); $taskMutex.Dispose()
}
