# 验证与兼容

- Codex：原生 v2 元数据、PNG 尺寸和安装目录已按桌面客户端 26.1002.6548 的加载实现核对。离线安装器在独立临时数据目录验证安装、重复安装、备份、卸载和保留其他文件。没有改变当前账户的宠物选择。
- Codex 的 HTTPS 图片安装链接参数按官方文档核对。仓库尚未上传时，无法完成该公开图片 URL 的在线安装验证。
- DSH：基于已验证的 0.2.0-rc.2 插件。会话和 Token 状态逻辑包含回归测试；安装/卸载在独立 DSH 数据目录验证，检查保留原有配置、安装文件齐全与路径包含空格/中文的情况。
- v2.1.0 提供固定目录安装、自动寻找 Harness，以及从 Node 模式的 Host 环境正确打开桌面应用的修正。浮窗仍只面向 Windows。Unix Codex 脚本提供给 macOS/Linux；仅 Windows 实机验证，不承诺所有客户端版本一致。
- GitHub 源码包与两个安装 ZIP 采用文件白名单构建。没有复制账号配置、会话、日志、私人路径或原宠物库的 ID。

维护者可以运行 `python scripts/build_release.py`、`node --test tests/activity.test.mjs` 和 `tests/portable-installers.ps1` 复核。GitHub Actions 不需要任何平台账号或 API Key。
