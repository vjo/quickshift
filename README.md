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

## Installation

- Clone this repository or download it
- Edit the configuration at the top of both script files
- Make sure the file are executable: `chmod +x quickshift-*.sh`
- Launch it with `./quickshift-watcher.sh`

## TODO

- [ ] Automatically launch the watcher using a `~/Library/LaunchAgents/*.plist` file.