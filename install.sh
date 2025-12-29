#!/bin/bash

# Quickshift Installer
# Handles dependencies, configuration, and auto-start setup.

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   Quickshift Installer Setup         ${NC}"
echo -e "${GREEN}======================================${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dependency Check
echo -e "\n${YELLOW}[1/4] Checking dependencies...${NC}"

TOOLS=("ffmpeg" "fswatch")
MISSING_TOOLS=()

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}Error: The following tools are missing: ${MISSING_TOOLS[*]}${NC}"
    echo "Please install them before running this script."
    echo ""
    echo -e "Suggestion:\n  brew install ${MISSING_TOOLS[*]}"
    exit 1
else
    echo -e "${GREEN}All dependencies found.${NC}"
fi

# Set Permissions
echo -e "\n${YELLOW}[2/4] Setting permissions...${NC}"
chmod +x "${SCRIPT_DIR}/quickshift-watcher.sh"
chmod +x "${SCRIPT_DIR}/quickshift-convert.sh"
echo "Scripts made executable."

# Configuration
echo -e "\n${YELLOW}[3/4] Configuring...${NC}"
CONFIG_FILE="${HOME}/.quickshiftrc"

if [ -f "$CONFIG_FILE" ]; then
    echo "Configuration file found at $CONFIG_FILE"
else
    echo "No configuration found at $CONFIG_FILE"
    echo -e "${YELLOW}You must create this file to configure the watch folder.${NC}"
    echo ""
    echo "Here is a template you can copy:"
    echo "-------------------------------------------------------"
    cat <<EOL
# Quickshift Configuration
# [MANDATORY] Path to watch for new screen recordings
WATCH_FOLDER="${HOME}/Pictures/screencaptures"

# [OPTIONAL] Set to "true" to delete the original .mov file after conversion (Default: false)
# DELETE_ORIGINAL_MOV=true

# [OPTIONAL] Video Quality Settings (CRF: Lower is better quality, 18-28 is sane range) (Default: 23)
# CRF_VALUE=23

# [OPTIONAL] Encoding Preset (ultrafast, medium, veryslow) (Default: medium)
# PRESET="medium"
EOL
    echo "-------------------------------------------------------"
    echo "Please create ~/.quickshiftrc with your desired settings."
fi

# Auto-start (LaunchAgent)
echo -e "\n${YELLOW}[4/4] Setting up auto-start on login...${NC}"

PLIST_NAME="com.${USER}.quickshift"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
WATCHER_SCRIPT="${SCRIPT_DIR}/quickshift-watcher.sh"
LOG_PATH="/tmp/quickshift.log"

read -p "Do you want Quickshift to start automatically when you log in? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Unload existing if present
    if launchctl list | grep -q "$PLIST_NAME"; then
        launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
    fi

    # Create Plist
    cat > "$PLIST_PATH" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${WATCHER_SCRIPT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_PATH}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_PATH}</string>
    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>
</dict>
</plist>
EOL
    
    echo "Created LaunchAgent at $PLIST_PATH"
    
    # Load it
    launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
    echo -e "${GREEN}Quickshift is now running and monitored by macOS.${NC}"
    echo "Logs are available at: $LOG_PATH"
else
    echo "Skipping auto-start setup."
fi

echo -e "\n${GREEN}Installation Complete!${NC}"
