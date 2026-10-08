# 奶邮 · Codex 原生宠物包 v1.0.0

使用 Codex 的原生自定义宠物加载方式，不需要安装 DSH 插件。

## Windows

1. 下载 ZIP 并解压，确保 `install.cmd` 与 `pet/` 在同一目录。
2. 双击 `install.cmd`，无需管理员权限。
3. 打开 Codex 的宠物设置，在自定义宠物区域点击刷新，选择“奶邮”。如果列表没有更新，重新打开应用。

默认安装到 `%USERPROFILE%\.codex\pets\naiyou-community`。设置了 `CODEX_HOME` 时使用该目录。也可指定数据目录：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -CodexDataDir "D:\CodexData"
```

先查看安装目标但不写入：为上面的命令添加 `-DryRun`。

## macOS / Linux

```sh
sh install.sh
```

默认安装到 `~/.codex/pets/naiyou-community`，遵循 `CODEX_HOME`。可传入自定义 Codex 数据目录：`sh install.sh /path/to/codex-home`。重启或刷新宠物列表后选择奶邮。

使用远程主机或 WSL 时，请从宠物设置的“打开文件夹”确认当前主机的数据目录，把 `pet/` 中的 `pet.json` 和 `spritesheet.png` 放入该目录下的新文件夹。该包针对支持 v2 自定义宠物的桌面客户端；在只显示云端宠物的界面中，本机目录安装不会直接创建云端宠物记录。

## 卸载或更新

Windows 双击 `uninstall.cmd`；macOS/Linux 执行 `sh uninstall.sh`。卸载只移除本安装器管理的奶邮文件。更新可重新运行安装器；先前版本会备份到 Codex 数据目录的 `naiyou-backups/`。

安装后可以删除下载目录。脚本不会替换当前选中的宠物；在宠物设置中选择即可。

## GitHub 图片安装链接

仓库发布后执行：

```sh
python make-install-link.py OWNER/REPOSITORY
```

默认图片路径为合并仓库中的 `codex/pet/spritesheet.png`。如果把此 Codex 包独立上传到仓库根目录，添加 `--image-path pet/spritesheet.png`。也可以打开 `install.html` 填写仓库信息。

链接会进入官方安装界面，使用 `spriteVersionNumber=2`：[官方说明](https://learn.chatgpt.com/docs/app/commands#pets)。离线加载格式根据桌面客户端的 `pet.json` 加载实现核对：`displayName`、`description`、`spriteVersionNumber`、`spritesheetPath`。

本包只提供原生宠物素材与安装方式；浮窗、动画状态和提醒由 Codex 自身控制。DSH 的自定义活动/Token 状态卡属于另一个平台包。
