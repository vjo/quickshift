#!/bin/bash

# --- Configuration ---
CONVERSION_SCRIPT_PATH="./quickshift-convert.sh"

# Load User Configuration
CONFIG_FILE="${HOME}/.quickshiftrc"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

if [ -z "$WATCH_FOLDER" ]; then
    echo "[QUICKSHIFT_WATCHER] Error: WATCH_FOLDER is not set."
    echo "Please create ~/.quickshiftrc and set WATCH_FOLDER=\"/path/to/watch\""
    exit 1
fi
# --- End Configuration ---

echo "===================================="
echo "[QUICKSHIFT_WATCHER] Starting at $(date)"
echo "[QUICKSHIFT_WATCHER] Watching folder: $WATCH_FOLDER"

# Determine `fswatch` path
if command -v fswatch >/dev/null 2>&1; then
    FSWATCH_PATH=$(command -v fswatch)
else
    echo "[QUICKSHIFT_WATCHER] fswatch not found. Please install fswatch (e.g., brew install fswatch)."
    exit 1
fi

if [ ! -d "$WATCH_FOLDER" ]; then
    echo "[QUICKSHIFT_WATCHER] Error: Watch folder '$WATCH_FOLDER' does not exist."
    exit 1
fi

if [ ! -x "$CONVERSION_SCRIPT_PATH" ]; then
    echo "[QUICKSHIFT_WATCHER] Error: Conversion script '$CONVERSION_SCRIPT_PATH' is not executable or does not exist."
    exit 1
fi

# Use `fswatch` to monitor the folder and only match `.mov` files
"$FSWATCH_PATH" -0 -r \
    --event Created \
    --event MovedTo \
    --event Renamed \
    --exclude='.*' \
    --include='\.mov$' \
    "$WATCH_FOLDER" | while IFS= read -r -d $'\0' file_path; do
        # Loops to read each file path provided by `fswatch`
        echo "[QUICKSHIFT_WATCHER] $(date): Detected event for: $file_path"
        # Run the conversion script in the background to avoid blocking `fswatch`
        ( "$CONVERSION_SCRIPT_PATH" "$file_path" ) &
    done

echo "[QUICKSHIFT_WATCHER] Exiting at $(date)"
echo "===================================="
