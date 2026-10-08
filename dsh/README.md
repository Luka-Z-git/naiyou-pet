# 奶邮 · DeepSeek Harness v2.1.0

支持 Windows 桌面版，已在 DeepSeek Harness 0.2.0-rc.2 核对插件接口。

## 安装

1. 安装并打开一次 DeepSeek Harness 桌面版，生成 `desktop` 配置。
2. 下载本 ZIP 并完整解压。
3. 双击 `install.cmd`，无需管理员权限。安装器自动寻找当前用户或 Program Files 中的 DeepSeek Harness。
4. 从系统托盘**完整退出** DSH，再重新打开。只点主窗口的 × 通常会隐藏应用。

奶邮会出现在桌面右下方，切换应用或最小化 Harness 后仍显示。原始 ZIP 解压目录可以删除，插件已复制到 `%LOCALAPPDATA%\DSH\Pets\naiyou\plugin`。

如果 Harness 安装在自定义位置：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -HarnessInstallDir "D:\Apps\DeepSeek Harness"
```

可添加 `-DryRun` 先显示目标位置。`-DshDataDir` 指定 DSH 数据根目录；`-DestinationDir` 指定插件的固定安装目录。正常安装遵循 `DSH_HOME`，否则使用 `%USERPROFILE%\.dsh`，只更新 `profiles/desktop` 中本宠物的依赖与启用项。

安装前会备份配置到 DSH 数据目录的 `naiyou-backups/`。原有插件、账号配置和其他启用项保留。软件版本变化可能需要相应的适配更新；没有安装器覆盖官方程序文件。

## 桌面使用

- 拖动奶邮或卡片的标题移动位置；双击奶邮或点击按钮打开 Harness。
- 状态卡显示会话标题以及思考、生成回复、工具调用、完成、取消或出错状态。
- 新的待批准请求把卡片变为橙色，并恢复收起/隐藏的奶邮，发出一次托盘通知和提示音。点击按钮回 Harness 批准。请求处理后提醒清除。Windows 通知设置可能影响托盘通知。
- 会话 Token 是模型服务报告的输入/输出累计值；输入包含缓存读取和写入。鼠标悬停查看缓存细分。没有统计时显示等待报告，通常在流式请求完成后更新。汇总采用 Harness 的 `tokenUsage` 投影，避免重复累加同一请求的中间和最终用量。
- 右键打开设置：显示详情、大小、暂停动画、提示音、隐藏、本次退出。托盘图标可以恢复隐藏的奶邮。

多个会话同时运行时，先展示待批准的会话，再展示最近活动的运行中会话。按钮打开 Harness 主窗口，可根据卡片标题找到对应会话。插件不替你批准任何请求。

偏好与当前状态保存在 `%LOCALAPPDATA%\DSH\Naiyou`。状态文件只传递会话标题、活动标签、批准标识与计数，不传递命令参数、文件内容或完整回复。显示动画不访问额外网络服务。Host 停止或插件停用后，桌面窗自动结束。

## 卸载

双击 `uninstall.cmd`，然后完整退出并重新打开 DSH。卸载移除奶邮的启用项和依赖，保留备份、固定插件目录与偏好。自定义数据根目录时，在 PowerShell 中给卸载脚本提供同样的 `-DshDataDir`。

本包也保留浏览器版 Harness 的窗口内宠物；Windows 桌面的提醒与 Token 卡片采用 WPF 浮窗。macOS/Linux 的桌面浮窗安装没有在本包中实现。
