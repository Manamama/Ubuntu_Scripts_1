#!/bin/bash

# Local file in Termux
file="/storage/emulated/0/Movies/2025-06-13 19.16.29.ogg"

# Detect active Codespace (adjust if multiple)
CODESPACE_NAME=$(gh codespace list --json name,state | jq -r '.[] | select(.state=="Available") | .name' | head -n1)

# Show input file duration
echo -e "🗃️  Input file duration: \e[34m$(mediainfo --Inform="Audio;%Duration/String2%" "$file")\e[0m";



gh codespace cp -e -c "$CODESPACE_NAME" "$file" "remote:~/Downloads/"


# Run WhisperX inside Codespace
time gh codespace ssh -c "$CODESPACE_NAME"    " time whisperx \                                                                   --compute_type float32 \
  '~/Downloads/2025-06-13 19.16.29.ogg' \                                                                --output_dir '~/Downloads/' \
  --print_progress True "



 # --highlight_words False  --no_align"

# Copy the resulting SRT file back to Termux
time gh codespace -e cp -c "$CODESPACE_NAME:/workspaces/codespaces-jupyter/Downloads/2025-06-13 19.16.29.srt" "/storage/emulated/0/Movies/"

# Play a notification sound
termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3"

# Open the SRT file
open "/storage/emulated/0/Movies/2025-06-13 19.16.29.srt"



"time whisperx \                                                                   --compute_type float32 \
  '~/Downloads/2025-06-13 19.16.29.ogg' \                                                                --output_dir '~/Downloads/' \
  --print_progress True "
