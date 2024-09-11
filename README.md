# PowerShell-Screen-Recorder
## Capture the screen using ffmpeg

This repository includes a PowerShell script for capturing high-quality screen recordings with customizable options, using FFmpeg for advanced video processing.

## What it does

This PowerShell script allows you to:
1. Select a specific area of your screen for recording
2. Capture screenshots at a defined framerate
3. Optionally include cursor movement in the recording
4. Combine the captured images into a high-quality video using FFmpeg

## Features

- Capture screen recordings with adjustable framerate
- Customizable output folder and video name
- Cursor capture option
- Utilizes FFmpeg for powerful video encoding and processing

## About FFmpeg

FFmpeg is a leading multimedia framework able to decode, encode, transcode, mux, demux, stream, filter, and play pretty much any media format. This script uses FFmpeg to:
- Convert individual frame captures into a cohesive video
- Apply efficient video compression
- Ensure high-quality output with customizable parameters

## Requirements

- PowerShell 5.1 or later
- FFmpeg installed and accessible in the system PATH

## Usage

1. Ensure FFmpeg is installed and accessible
2. Run the script in PowerShell:
   ```powershell
   .\ScreenRecording2.ps1 -OutFolder "C:\temp\recording" -Framerate 30 -VideoName "my_recording.mp4"
3. Follow the on-screen instructions to select the recording area
   
