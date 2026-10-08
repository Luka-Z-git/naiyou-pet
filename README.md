# 奶邮 · Naiyou Pet

干甘滴蜡虾？！陪你学习、写代码，也帮你留意任务进展。

本项目提供 **Codex 原生宠物包**和 **DeepSeek Harness（DSH）Windows 桌面宠物包**，两种版本使用同一套奶邮动画素材。

## 下载

进入本仓库的 **Releases** 页面，下载对应平台的安装包：

| 平台 | 安装包 | 主要功能 |
| --- | --- | --- |
| Codex | `naiyou-codex-v1.0.0.zip` | 原生宠物动画，跟随 Codex 的宠物界面使用 |
| DeepSeek Harness · Windows | `naiyou-dsh-v2.1.0.zip` | 桌面置顶、批准提醒、任务状态、Token 用量 |

使用安装包无需另装 Python 或 Node.js。Codex 和 DeepSeek Harness 软件需自行安装。

## Codex 安装

**Windows**

1. 解压 Codex 安装包。
2. 双击 `install.cmd`。
3. 打开 Codex 的宠物设置，刷新自定义宠物列表，选择“奶邮”。如果列表没有更新，重新打开 Codex。

**macOS / Linux**

在解压目录打开终端，运行：

```sh
sh install.sh
```

随后刷新宠物列表并选择奶邮。需要支持 v2 自定义宠物的 Codex 桌面客户端；macOS/Linux 脚本尚未在对应系统实机验证。

卸载：Windows 双击 `uninstall.cmd`；macOS/Linux 运行 `sh uninstall.sh`。

自定义安装目录、远程主机与图片安装链接，见 [Codex 完整说明](codex/README.md)。

## DSH 安装

1. 安装并打开一次 DeepSeek Harness 桌面版。
2. 解压 DSH 安装包，双击 `install.cmd`。
3. 从系统托盘完整退出 DSH，再重新打开。

安装器会自动寻找 Harness，将插件复制到固定目录，并备份安装前的配置。安装后可以删除下载的解压目录。

### 奶邮能做什么

- **桌面陪伴**：置顶显示，切换应用或最小化 DSH 后仍可看见；支持拖动、调整大小、隐藏和暂停动画。
- **批准提醒**：遇到待批准请求时显示橙色提示卡，并发出托盘通知和提示音；点击按钮可返回 Harness 处理请求。
- **任务进展**：显示会话标题，以及思考、生成回复、工具调用、完成、取消或出错状态。
- **Token 用量**：显示模型服务报告的输入、输出和缓存统计；通常在请求完成后更新，没有报告时显示等待统计。

奶邮不会自动批准请求。多个会话同时运行时，优先显示等待批准的会话。Windows 通知设置可能影响托盘提醒。

卸载：双击 `uninstall.cmd`，完整退出并重新打开 DSH。

当前桌面浮窗支持 Windows，已按 DeepSeek Harness `0.2.0-rc.2` 核对插件接口。自定义路径与更多设置见 [DSH 完整说明](dsh/README.md)。

## 更新与隐私

- 下载新版本并重新运行安装器即可更新；安装器会备份先前的文件或配置。
- 发布包不包含作者的账号配置、聊天记录、API Key 或个人安装路径。
- DSH 状态显示不传递命令参数、文件内容或完整回复；动画显示不访问额外网络服务。
- Codex 版的动画状态和提醒由 Codex 自身控制；DSH 版提供本项目的活动与 Token 状态卡。

## 构建与验证

维护者需要 Python 3 和 Node.js。在仓库根目录运行：

```sh
python scripts/build_release.py
node --test tests/activity.test.mjs
```

构建结果位于 `dist/`，包含两个平台安装包、源码包和 SHA-256 校验值。Windows 安装器检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/portable-installers.ps1
```

测试使用独立目录；兼容范围和验证情况见 [VALIDATION.md](VALIDATION.md)。仓库附 GitHub Actions 工作流。

## 许可证

代码采用 [MIT 许可证](LICENSE)。奶邮动画素材随项目提供，用于安装、使用和分享本宠物包，见 [ASSETS.md](ASSETS.md)。
