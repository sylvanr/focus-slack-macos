#!/bin/bash

# Default values
UPDATE_RATE=300
USERNAME=$(whoami)
SCRIPT_DIR="$HOME"
SCRIPT_NAME="focus_slack.sh"
LOG_NAME="focus_slack.log"

# Help function
show_help() {
    cat << EOF
Usage: $0 [options]

This script sets up a macOS LaunchAgent to focus Slack every N seconds.

Options:
  --update-rate=N        Interval in seconds to run the script (default: 300)
  --script-dir="path"    Directory to create the focus_slack.sh script (default: $HOME)
  -h, --help             Show this help message
EOF
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --update-rate=*)
            UPDATE_RATE="${1#*=}"
            shift
            ;;
        --script-dir=*)
            SCRIPT_DIR="${1#*=}"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Full paths
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
PLIST_PATH="/Users/$USERNAME/Library/LaunchAgents/com.user.focus_slack.plist"
LOG_PATH="$SCRIPT_DIR/$LOG_NAME"

# Step 1: Create the focus_slack.sh script
mkdir -p "$SCRIPT_DIR"
cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Get the name of the currently focused app
prev_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

# Check if Slack is running
slack_running=$(osascript -e 'tell application "System Events" to (name of processes) contains "Slack"')

if [ "$slack_running" = "false" ]; then
  echo "Slack is not running. Launching Slack..."
  open -a "Slack"
  sleep 2
else
  echo "Slack is already running."
fi

# Focus Slack
osascript -e 'tell application "Slack" to activate'

# Refocus the previously active app
osascript -e "tell application \"$prev_app\" to activate"

echo "Returned focus to $prev_app"
EOF

chmod +x "$SCRIPT_PATH"

mkdir -p "/Users/$USERNAME/Library/LaunchAgents"
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.focus_slack</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_PATH</string>
    </array>

    <key>StartInterval</key>
    <integer>$UPDATE_RATE</integer>

    <key>StandardOutPath</key>
    <string>$LOG_PATH</string>

    <key>StandardErrorPath</key>
    <string>$LOG_PATH</string>

    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

echo "LaunchAgent loaded. Current status:"
launchctl list | grep focus_slack || echo "Focus Slack LaunchAgent is not running yet."

echo "Running script once to test script manually..."
launchctl start com.user.focus_slack

echo "Setup complete. Script path: $SCRIPT_PATH, Log path: $LOG_PATH, Update rate: $UPDATE_RATE seconds."
