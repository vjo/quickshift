#!/bin/bash

# --- Configuration ---
# Set to "true" to delete .mov after successful conversion.
DELETE_ORIGINAL_MOV=false
# --- End Configuration ---

FULL_FILE_PATH="$1"

echo "------------------------------------"
echo "[QUICKSHIFT_CONVERT] Starting at $(date) for file: $FULL_FILE_PATH"

if [[ -z "$FULL_FILE_PATH" ]]; then
    echo "[QUICKSHIFT_CONVERT] No file path provided. Exiting."
    exit 1
fi

# Small delay to help ensure the file is fully written before processing
# QuickTime usually closes files promptly after recording.
sleep 5

if [ ! -f "$FULL_FILE_PATH" ]; then
    echo "[QUICKSHIFT_CONVERT] File not found (or is not a regular file) after sleep: $FULL_FILE_PATH"
    exit 0
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
filename_no_ext="${filename_with_ext%.*}"
dir_path=$(dirname "$FULL_FILE_PATH")

if [ "$extension" == "mov" ]; then
    output_file="${dir_path}/${filename_no_ext}.mp4"

    # Check if output file already exists and is newer; if so, skip
    if [ -f "$output_file" ] && [ "$output_file" -nt "$FULL_FILE_PATH" ]; then
        echo "[QUICKSHIFT_CONVERT] Output file $output_file already exists and is newer. Skipping."
        exit 0
    fi

    echo "[QUICKSHIFT_CONVERT] Attempting to convert '$FULL_FILE_PATH' to '$output_file'"

    # Run conversion with ffmpeg
    "$FFMPEG_PATH" -hide_banner -loglevel error -i "$FULL_FILE_PATH" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -pix_fmt yuv420p -movflags +faststart -y "$output_file"

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
