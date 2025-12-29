# quickshift

Automatically convert Quicktime screen-recordings to MP4.

## Background

As a software engineer, I often record my screen using QuickTime (`CMD+SHIFT+5`) to document a bug or provide explanation on a code review.\
However, QuickTime produces `.mov` files that are often large and can have compatibility issues.

For a long time, I have used the excellent [HandBrake](https://handbrake.fr/) to manually convert my screen recordings to `.mp4`.\
**This script aims to automate this task.**

## Prerequisites

This script utilizes [fswatch](https://emcrisostomo.github.io/fswatch/) to monitor the screen recording output directory and [ffmpeg](https://ffmpeg.org/) for video conversion.

Make sure, these are installed:
```shell
brew install ffmpeg fswatch
```

> **Tip:** You can change where macOS saves screen recordings by running:
> ```shell
> defaults write com.apple.screencapture location ~/Pictures/screencaptures
> killall SystemUIServer
> ```

## Installation

1.  Clone this repository or download it.
2.  Run the installer:
    ```shell
    ./install.sh
    ```
    This script will:
    *   Check/Install dependencies (`ffmpeg`, `fswatch`).
    *   Help you configure the watch folder.
    *   Set up auto-start on login (optional).

## Uninstallation

To remove Quickshift and stop the background watcher:

```shell
# 1. Unload and remove the auto-start agent
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.USER.quickshift.plist
rm ~/Library/LaunchAgents/com.USER.quickshift.plist

# 2. Remove configuration (Optional)
rm ~/.quickshiftrc

# 3. Delete the repository
rm -rf /path/to/quickshift
```

## Configuration

You can configure the scripts by creating a `~/.quickshiftrc` file in your home directory.

**Example `~/.quickshiftrc`:**
```bash
# [MANDATORY] Path to watch for new screen recordings
WATCH_FOLDER="${HOME}/Pictures/screencaptures"

# [OPTIONAL] Set to "true" to delete the original .mov file after conversion (Default: false)
# DELETE_ORIGINAL_MOV=true

# [OPTIONAL] Video Quality Settings (CRF: Lower is better quality, 18-28 is sane range) (Default: 23)
# CRF_VALUE=23

# [OPTIONAL] Encoding Preset (ultrafast, medium, veryslow) (Default: medium)
# PRESET="medium"
```