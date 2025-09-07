#!/usr/bin/env bash

whisperx_codespace_url(){
    set -euo pipefail

    if [[ $# -lt 1 ]]; then
        echo "❌ Usage: $0 <youtube_url> [extra_args...]"
        exit 1
    fi

    url="$1"
    shift
    extra_args="$@"

    echo "📥 Input YouTube URL:"
    echo "$url"
    echo "🔧 Extra WhisperX Args: '$extra_args'"
    echo

    # ================= Step 1: Detect Codespace =================
    echo "🔍 Detecting GitHub Codespace..."
    CODESPACE_NAME=$(gh codespace list --json name,state | jq -r '.[] | .name' | head -n1)
    if [[ -z "$CODESPACE_NAME" ]]; then
        echo "❌ FATAL: No Codespace found"
        exit 1
    fi
    echo "✅ Codespace detected: $CODESPACE_NAME"
    echo

    # ================= Step 2: Ensure remote Downloads directory =================
    echo "📁 Ensuring remote Downloads directory..."
    gh codespace ssh -c "$CODESPACE_NAME" "mkdir -p ~/Downloads"

    # ================= Step 3: Download with yt-dlp =================
    echo "🎬 Downloading audio with yt-dlp on remote..."
    # extract best audio, store in ~/Downloads, get clean filename
    remote_audio=$(gh codespace ssh -c "$CODESPACE_NAME" \
        "cd ~/Downloads && yt-dlp -f 'bestaudio' --no-playlist --extract-audio --audio-format mp3 --restrict-filenames  --trim-filenames 20 --print after_move:filepath '$url'")

    if [[ -z "$remote_audio" ]]; then
        echo "❌ FATAL: yt-dlp did not return a file path"
        exit 1
    fi

    echo "✅ Downloaded: $remote_audio"
    filename_no_ext=$(basename "$remote_audio" .mp3)
    remote_srt="~/Downloads/${filename_no_ext}.srt"
echo
echo "The remote file name should look like this: $remote_srt"

    # ================= Step 4: Check/install WhisperX =================
    echo "🔍 Checking WhisperX..."
    if ! gh codespace ssh -c "$CODESPACE_NAME" "command -v whisperx >/dev/null"; then
        echo "⚠️ WhisperX not found, installing..."
        gh codespace ssh -c "$CODESPACE_NAME" "pip install -U --user whisperx"
        echo "✅ WhisperX installed"
    fi

    # ================= Step 5: Run WhisperX =================
    echo "🤖 Running WhisperX transcription..."
  #  run_cmd="whisperx --compute_type float32 --model medium '$remote_audio'  --output_dir ~/Downloads --highlight_words True --print_progress True $extra_args"



#We resigned from highlighting words as it shall be faster.

run_cmd="whisperx --compute_type float32 --model medium '$remote_audio' --output_dir ~/Downloads  --print_progress True $extra_args"

   time gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd"

#echo "🔊 Playing notification sound..."


: '
if ! termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3" 2>/dev/null; then
    echo "⚠️ Notification sound not played (audio file missing?)" 
fi

# termux-media-player play /storage/5951-9E0F/Audio/Funny_Sounds/proximity_bash.mp3

'
#This is for a watch that may be connected via BLE to the notifications shown by Termux API: 
termux-notification -c " OK: ${filename_no_ext}.srt" --title "WhisperX " --vibrate 500,1000,200

# if you watch does not allow notification from this Twrmux API program, then you can trick it via sending an SMS or via sending an email and so on.

# if you BT bind your watch with your phone and use the audio sink of the watch then the below shall play on the watch:


termux-tts-speak "Transcription from URL has  finished."


echo "✅ Notifications sent" 
echo

    # ================= Step 6: Return only text =================
    echo "📜 Fetching transcription text: '$remote_srt'..."   

 gh codespace ssh -c "$CODESPACE_NAME" "cat $remote_srt" 


}

time whisperx_codespace_url "$@"
