Codex Touch Bar — Universal (Apple Silicon / Intel)

Shows reset cards, remaining quota, reset countdown and recent Codex desktop
conversations in the Touch Bar. macOS 12 or later is required.

Install:
  1. Double-click Install.command and follow the Terminal output.
  2. Focus Codex to display the Touch Bar panel.

Alternatively, open Terminal in this folder and run ./install.sh.
The installer replaces any existing CodexTouchBarHelper installation and its
LaunchAgent. It does not delete Codex login information or session history.

Uninstall: run ./uninstall.sh in Terminal.

This build is ad-hoc signed and is not Apple-notarized. macOS may block the
app or installer. Verify the archive against the published SHA-256 checksum;
if blocked, check System Settings > Privacy & Security for the available
approval options. A checksum does not verify the publisher's identity.

The helper is installed to ~/Applications/CodexTouchBarHelper.app and starts
at login through ~/Library/LaunchAgents/com.local.codex-touchbar-helper.plist.

Project: https://github.com/github-bian/codex-touchbar-usage
Based on: https://github.com/Daytimeflow/codex-touchbar-usage
