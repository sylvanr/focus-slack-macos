# focus-slack-macos

In my team, people experienced Slack going offline on macos, when slack is not the focused window. This could in theory be caused by background processes being limited by macos settings.

# Usage

On macOS, run the script `setup_focus_slack.sh` once.

## Disable

To disable the automatic focus:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.focus_slack.plist
rm ~/Library/LaunchAgents/com.user.focus_slack.plist
```
