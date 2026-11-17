# Codex Touch Bar

English | [简体中文](README.md)

Turn your MacBook Pro Touch Bar into a compact Codex dashboard: check your quota and reset countdown at a glance, then tap to switch conversations. This project builds on [Daytimeflow/codex-touchbar-usage](https://github.com/Daytimeflow/codex-touchbar-usage).

![Touch Bar showing reset cards, quota, countdown, and conversations](assets/touchbar-conversations.png)

*Native UI preview rendered with sample data. Available width depends on the device and system control strip.*

## Features

- **Reset cards:** See the available count.
- **Quota:** View remaining primary quota as a percentage and circular progress indicator, with color changes at low levels.
- **Reset countdown:** A larger clock icon and clear digits show the time remaining until the primary quota resets.
- **Compact layout:** Quota and countdown spacing adapts to their text, leaving more room for conversation titles.
- **Conversation switching:** Browse the 50 most recent unarchived local Codex desktop conversations horizontally and tap a title to open it.
- **Status indicators:** A blue dot indicates activity inferred from recent events, a green dot indicates the last task completed, and a gray dot means the status is unknown. A silver cat-ear outline and teal paw mark the conversation most recently tapped in the Touch Bar.
- **Foreground awareness:** The panel appears when Codex is focused; system controls return when switching away.

Conversation status is inferred from local session events, not a live status API. Long-running or interrupted tasks and Codex updates can result in unknown or temporarily inaccurate indicators. Cloud and archived conversations are not currently listed. Navigation, session formats, and Touch Bar presentation rely on internal behavior and may need updates as the software changes.

## Requirements

- A MacBook Pro with Touch Bar and macOS 12 or later.
- The Codex desktop app, signed in. Quota retrieval also requires a local Codex CLI login (`~/.codex/auth.json`).
- Xcode Command Line Tools or full Xcode for source installation; prebuilt releases do not require a compiler.

## Download and install

Download `CodexTouchBarUsage-v0.2.1-universal.zip` and its `.sha256` file from [GitHub Releases](https://github.com/github-bian/codex-touchbar-usage/releases/latest). The universal build supports Apple Silicon and Intel and does not require a compiler to install.

1. In the download folder, run `shasum -a 256 -c CodexTouchBarUsage-v0.2.1-universal.zip.sha256` to check the archive.
2. Extract it and double-click `Install.command`, then follow the Terminal output; alternatively, run `./install.sh` from the extracted folder.
3. Open and focus Codex. To uninstall, run `./uninstall.sh` in the extracted folder.

Installation replaces an existing CodexTouchBarHelper and its LaunchAgent, but does not delete Codex credentials or conversation history. The app is ad-hoc signed and **not Apple-notarized**. If macOS blocks it, check System Settings → Privacy & Security for available approval options. A checksum checks integrity; it does not authenticate the publisher.

## Install from source

```bash
git clone https://github.com/github-bian/codex-touchbar-usage.git
cd codex-touchbar-usage
./scripts/install_touchbar_helper.sh
```

The installer builds a native Swift helper, installs it at `~/Applications/CodexTouchBarHelper.app`, and registers a LaunchAgent to start it at login. Focus Codex after installation to see the panel. Upstream releases do not contain these changes.

Update:

```bash
git pull
./scripts/install_touchbar_helper.sh
```

Uninstall:

```bash
./scripts/uninstall_touchbar_helper.sh
```

## Data and privacy

Quota and reset-card information primarily comes from the Codex app-server `account/rateLimits/read`, with the upstream cache and fallback data sources when unavailable. Conversation titles are read from the local `~/.codex/state_5.sqlite` database; status is inferred from local session events. Tapping a title opens `codex://threads/<id>`. This feature does not upload conversation contents.

The project retains upstream quota and caching behavior and also requests account usage data, although the Codex panel does not display token counts. Caches and logs are stored in `~/.codex/touchbar-usage/`. Do not commit `~/.codex/auth.json`, session records, or screenshots containing private information to a public repository.

## Development and troubleshooting

```bash
cd helper/CodexTouchBarHelper
swift test
```

Run the native UI rendering checks from the repository root:

```bash
./scripts/test_touchbar_ui.sh
```

Inspect the service and its logs:

```bash
launchctl print gui/$(id -u)/com.local.codex-touchbar-helper
tail -f ~/.codex/touchbar-usage/helper.err.log
```

Upstream ZCode support is retained; see the [ZCode documentation](docs/zcode-usage.md).

## Credits and license

Thanks to [Daytimeflow/codex-touchbar-usage](https://github.com/Daytimeflow/codex-touchbar-usage) for the original project. This project is distributed under the [MIT License](LICENSE), retaining the upstream copyright notice.

This is an unofficial community project and is not affiliated with, authorized by, or endorsed by OpenAI or Codex. It uses private macOS Touch Bar APIs, so compatibility may change with system or app updates.
