# Codex Touch Bar

[English](README.en.md) | 简体中文

在 MacBook Pro Touch Bar 上查看 Codex 额度，并快速切换最近的对话。基于 [Daytimeflow/codex-touchbar-usage](https://github.com/Daytimeflow/codex-touchbar-usage) 的二次开发版本。

![Touch Bar 显示重置卡、额度、倒计时和对话](assets/touchbar-conversations.png)

*使用示例数据生成的原生界面预览。实际显示宽度取决于设备及系统控制条。*

## 功能

- **重置卡**：显示可用数量。
- **额度**：以环形进度条和百分比显示主额度剩余量，低额度时变色。
- **倒计时**：显示距离主额度重置的剩余时间。
- **对话切换**：横向显示最近 50 条未归档的本机 Codex 桌面对话，滑动查看更多，点按标题打开对应对话。
- **状态提示**：蓝点代表根据近期事件推测的进行中，绿勾代表最近一次任务完成，灰点代表状态未知。蓝色描边表示最近从 Touch Bar 点按的对话。
- **前台显示**：Codex 位于前台时显示面板，切换到其他应用后恢复系统控制条。

对话状态来自本地会话事件，并非实时运行状态接口：长任务、异常退出或 Codex 更新可能导致状态未知或短暂不准确。当前不显示云端或已归档对话。对话跳转、会话格式及 Touch Bar 展示依赖内部行为，未来版本可能需要适配。

## 系统要求

- 带 Touch Bar 的 MacBook Pro，macOS 12 或更新版本。
- 已安装并登录 Codex 桌面应用；额度读取还需要本机 Codex CLI 登录状态（`~/.codex/auth.json`）。
- Xcode Command Line Tools 或完整 Xcode，用于从源码编译。

## 下载与安装

从 [GitHub Releases](https://github.com/github-bian/codex-touchbar-usage/releases/latest) 下载 `CodexTouchBarUsage-v0.1.0-universal.zip` 和对应的 `.sha256` 文件。该通用包支持 Apple Silicon 和 Intel；安装时无需编译。

1. 在下载目录运行 `shasum -a 256 -c CodexTouchBarUsage-v0.1.0-universal.zip.sha256`，确认校验通过。
2. 解压后双击 `Install.command`，根据终端提示完成安装；也可以在解压目录运行 `./install.sh`。
3. 打开 Codex 并将其置于前台。卸载时在解压目录运行 `./uninstall.sh`。

安装会替换已有的 CodexTouchBarHelper 及其 LaunchAgent，不会删除 Codex 登录信息和对话历史。安装包采用临时签名，**未经过 Apple 公证**；macOS 可能阻止运行，可在「系统设置 → 隐私与安全性」查看可用的允许选项。校验和只能检查文件完整性，不能验证发布者身份。

## 从源码安装

```bash
git clone https://github.com/github-bian/codex-touchbar-usage.git
cd codex-touchbar-usage
./scripts/install_touchbar_helper.sh
```

安装脚本会构建原生 Swift helper，安装至 `~/Applications/CodexTouchBarHelper.app`，并注册登录后启动的 LaunchAgent。安装后切换到 Codex，即可在 Touch Bar 上看到面板。上游发布的安装包不包含这些改动。

更新：

```bash
git pull
./scripts/install_touchbar_helper.sh
```

卸载：

```bash
./scripts/uninstall_touchbar_helper.sh
```

## 数据与隐私

额度和重置卡信息主要来自 Codex app-server 的 `account/rateLimits/read`，不可用时沿用上游的本地缓存及备用数据源。对话标题从本机 `~/.codex/state_5.sqlite` 只读获取，状态通过读取相应本地会话事件推测；点击标题通过 `codex://threads/<id>` 打开对话。对话内容不会被此功能上传。

本项目沿用上游额度读取与缓存逻辑，也会请求账户用量数据，但 Codex 面板不展示 Token 数量。缓存和日志位于 `~/.codex/touchbar-usage/`。请勿将 `~/.codex/auth.json`、会话记录或含个人信息的截图提交到公开仓库。

## 开发与排查

```bash
cd helper/CodexTouchBarHelper
swift test
```

在仓库根目录运行原生界面渲染检查：

```bash
./scripts/test_touchbar_ui.sh
```

查看运行状态和日志：

```bash
launchctl print gui/$(id -u)/com.local.codex-touchbar-helper
tail -f ~/.codex/touchbar-usage/helper.err.log
```

项目保留了上游的 ZCode 支持，详情见 [ZCode 说明](docs/zcode-usage.md)。

## 致谢与许可证

感谢 [Daytimeflow/codex-touchbar-usage](https://github.com/Daytimeflow/codex-touchbar-usage) 提供原项目。本项目使用 [MIT 许可证](LICENSE)，保留上游版权声明。

本项目为非官方社区作品，与 OpenAI 或 Codex 没有官方隶属、授权或背书关系。项目使用 macOS 私有 Touch Bar 接口，系统或应用更新可能影响其兼容性。
