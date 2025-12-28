#!/bin/bash

# --- Configuration ---
# Defaults
DELETE_ORIGINAL_MOV=false
PRESET="medium"
CRF_VALUE=23

# Load User Configuration
CONFIG_FILE="${HOME}/.quickshiftrc"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi
# --- End Configuration ---

FULL_FILE_PATH="$1"

echo "------------------------------------"
echo "[QUICKSHIFT_CONVERT] Starting at $(date) for file: $FULL_FILE_PATH"

if [[ -z "$FULL_FILE_PATH" ]]; then
    echo "[QUICKSHIFT_CONVERT] No file path provided. Exiting."
    exit 1
fi

# Robust file stability check: Wait until file size stops changing
echo "[QUICKSHIFT_CONVERT] Checking file stability for: $FULL_FILE_PATH"

prev_size=-1
stability_counter=0
# Max wait: ~60s
max_checks=30

for ((i=0; i<max_checks; i++)); do
    if [ ! -f "$FULL_FILE_PATH" ]; then
         echo "[QUICKSHIFT_CONVERT] File vanished during check: $FULL_FILE_PATH"
         exit 0
    fi

    # portable way to get size
    curr_size=$(wc -c < "$FULL_FILE_PATH")
    
    if [ "$prev_size" -eq "$curr_size" ] && [ "$curr_size" -gt 0 ]; then
        ((stability_counter++))
    else
        stability_counter=0
    fi

    # If size has been stable for 3 consecutive checks (approx 6 seconds)
    if [ "$stability_counter" -ge 3 ]; then
        echo "[QUICKSHIFT_CONVERT] File size stable ($curr_size bytes). Proceeding."
        break
    fi

    prev_size=$curr_size
    sleep 2
done

if [ "$stability_counter" -lt 3 ]; then
    echo "[QUICKSHIFT_CONVERT] Warning: Timeout waiting for file stability or file is empty. Proceeding..."
fi

# Determine ffmpeg path
if command -v ffmpeg >/dev/null 2>&1; then
    FFMPEG_PATH=$(command -v ffmpeg)
else
    echo "[QUICKSHIFT_CONVERT] ffmpeg not found. Please install ffmpeg (e.g., brew install ffmpeg)."
    exit 1
fi

filename_with_ext=$(basename "$FULL_FILE_PATH")
extension="${filename_with_ext##*.}"
extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
filename_no_ext="${filename_with_ext%.*}"
dir_path=$(dirname "$FULL_FILE_PATH")

if [ "$extension_lower" == "mov" ]; then
    output_file="${dir_path}/${filename_no_ext}.mp4"

    # Check if output file already exists and is newer; if so, skip
    if [ -f "$output_file" ] && [ "$output_file" -nt "$FULL_FILE_PATH" ]; then
        echo "[QUICKSHIFT_CONVERT] Output file $output_file already exists and is newer. Skipping."
        exit 0
    fi

    echo "[QUICKSHIFT_CONVERT] Attempting to convert '$FULL_FILE_PATH' to '$output_file'"

    # Create a lock file to prevent simultaneous processing of the same file
    LOCK_DIR="/tmp/quickshift_locks"
    mkdir -p "$LOCK_DIR"
    LOCK_FILE="${LOCK_DIR}/${filename_no_ext}.lock"

    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        echo "[QUICKSHIFT_CONVERT] Lock file exists for '$filename_no_ext'. Conversion in progress or stale lock: skipping."
        exit 0
    fi

    # Remove lock file on exit
    trap 'rm -rf "$LOCK_FILE"' EXIT

    # Run conversion with ffmpeg
    "$FFMPEG_PATH" -hide_banner -loglevel error -i "$FULL_FILE_PATH" -c:v libx264 -crf "$CRF_VALUE" -preset "$PRESET" -c:a aac -b:a 128k -pix_fmt yuv420p -movflags +faststart -y "$output_file"

    if [ $? -eq 0 ]; then
        if [ "$DELETE_ORIGINAL_MOV" = true ]; then
            rm "$FULL_FILE_PATH"
        fi
    else
        echo "[QUICKSHIFT_CONVERT] Error converting '$FULL_FILE_PATH'. FFmpeg exit code: $?"
    fi
else
    echo "[QUICKSHIFT_CONVERT] File '$FULL_FILE_PATH' is not a .mov file. Skipping."
fi

echo "[QUICKSHIFT_CONVERT] Finished at $(date)"
echo "------------------------------------"
