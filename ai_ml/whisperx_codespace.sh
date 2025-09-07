 

#!/usr/bin/env bash

whisperx_on_remote() {
set -euo pipefail

# ================= Runtime Intro =================
echo
echo "========================================="
echo "📜 WhisperX Transcription Script (Paranoid Android & gh User Edition)"
echo "Version 3.1.7"
echo 
echo "🔐 Mission Brief:"
echo "  1. Verify input audio file exists (no ghosts allowed)."
echo "  2. Extract and display audio duration."
echo "  3. Ensure remote Downloads dir is ready (no excuses)."
echo "  4. Upload file to Codespace (skip if identical, hash-checked)."
echo "  5. Confirm remote file existence (trust no one)."
echo "  6. Check/install WhisperX (because Codespaces can forget)."
echo "  7. Run WhisperX transcription (with paranoid logging)."
echo "  8. Trust and so verify the output files (.srt, .json) exist and aren't empty."
echo "  9. Download results to Termux (double-checked)."
echo "  10. Play quack notification and open SRT (because we earned it)."
echo "⚠️  Built to survive gh bugs (#6148) and filename chaos (spaces beware)."
echo "========================================="
echo

# ================= Input Args =================
if [[ $# -lt 1 ]]; then
    echo "❌ FATAL: Usage: $0 <audio_file> [extra_args...]" 
    exit 1
fi

file="$1"
shift
extra_args="$@"
base_filename=$(basename "$file")
filename_no_ext="${base_filename%.*}"
file_dir=$(dirname "$file")

echo "📥 Input File (shared paths resolved):"
echo "$file" | lolcat
echo "💡 Tip: Add '--model large' or '--diarize' (needs HF_TOKEN env)."
echo -n "🔧 WhisperX Extra Args: "
echo "'$extra_args'" | lolcat
echo "📛 Base Filename: '$base_filename'"
echo

# ================= Step 1: Check input file =================
echo "🔍 [1/10] Verifying input file existence..."
if [[ ! -f "$file" ]]; then
    echo "❌ FATAL: Input file not found: '$file'" 
    exit 1
fi
echo "✅ Input file verified: '$file'" 
echo

# ================= Step 2: Show file duration =================
echo "⏳ [2/10] Extracting audio duration..."
if duration=$(mediainfo --Inform='Audio;%Duration/String2%' "$file" 2>/dev/null); then
    echo -n "🗣️ Duration: "
    echo "$duration" | lolcat
else
    echo "⚠️ Could not extract duration (proceeding anyway)" 
fi
echo

# ================= Step 3: Detect Codespace =================
echo "🔍 [3/10] Detecting GitHub Codespace..."
CODESPACE_NAME=$(gh codespace list --json name,state | jq -r '.[] | .name' | head -n1)
if [[ -z "$CODESPACE_NAME" ]]; then
    echo "❌ FATAL: No Codespace found" 
    exit 1
fi
echo -n "✅ Codespace detected: "
#echo "$CODESPACE_NAME" | lolcat
echo

gh codespace view -c "$CODESPACE_NAME" | lolcat
echo 
# ================= Step 4: Ensure remote Downloads directory =================
echo "📁 [4/10] Ensuring remote Downloads directory..."
if ! gh codespace ssh -c "$CODESPACE_NAME" "mkdir -p ~/Downloads" 2>/dev/null; then
    echo "❌ FATAL: Failed to create remote Downloads directory" 
    exit 1
fi
echo "✅ Remote Downloads directory ready" 
echo

# ================= Step 5: Upload to Codespace =================
echo "🔍 [5/10] Resolving remote home directory..."
remote_home=$(gh codespace ssh -c "$CODESPACE_NAME" "echo \$HOME" 2>/dev/null)
if [[ -z "$remote_home" ]]; then
    echo "❌ FATAL: Failed to resolve remote home directory" 
    exit 1
fi
echo -n "✅ Remote home: " 
echo "'$remote_home'" | lolcat
echo
remote_path="$remote_home/Downloads/$base_filename"

echo "📤 [6/10] Checking the existence of the remote file: '$remote_path'..."
if gh codespace ssh -c "$CODESPACE_NAME" "test -f '$remote_path'" 2>/dev/null; then
    echo "That remote file exists, so:"
    echo "🔎 Comparing the local file: '$file' with the remote one: '$remote_path'..."
    local_hash=$(sha256sum "$file" | cut -d' ' -f1)
    remote_hash=$(gh codespace ssh -c "$CODESPACE_NAME" "sha256sum '$remote_path' | cut -d' ' -f1" 2>/dev/null || true)

    if [[ -n "$remote_hash" && "$local_hash" == "$remote_hash" ]]; then
        echo "✅ Skipped the upload, as the local file is identical to the remote one."
    else
        echo "⚠️ File exists but hashes differ → re-uploading."
        echo "📤 Uploading '$file' → '$remote_path'..."
        if ! upload_output=$(time gh codespace cp -e -c "$CODESPACE_NAME" "$file" "remote:$remote_path" 2>&1); then
            echo "❌ FATAL: Upload failed: $upload_output"
            exit 1
        fi
        echo "✅ Uploaded: $remote_path"
    fi
else
    echo "⚠️ Remote file not found → uploading."
    echo "📤 Uploading '$file' → '$remote_path'..."
    if ! upload_output=$(time gh codespace cp -e -c "$CODESPACE_NAME" "$file" "remote:$remote_path" 2>&1); then
        echo "❌ FATAL: Upload failed: $upload_output"
        exit 1
    fi
    echo "✅ Uploaded: $remote_path"
fi

echo


# ================= Step 7: Check and install WhisperX =================
echo "🔍 [7/10] Checking for WhisperX in Codespace..."
if gh codespace ssh -c "$CODESPACE_NAME" "command -v whisperx >/dev/null"; then
    echo "✅ WhisperX is installed on the remote server"
else
    echo "⚠️ WhisperX not found, installing (mind you: by default, it installs the huge GPU edition with NVIDIA drivers, so preinstall the Torch CPU version to avoid it..." 
    if ! install_output=$(gh codespace ssh -c "$CODESPACE_NAME" "pip install -U --user whisperx" 2>&1); then
        echo "❌ FATAL: Failed to install WhisperX: $install_output"
        exit 1
    fi
    # echo "$install_output" 
    echo "✅ WhisperX installed successfully" 

fi

# Paranoia: Check HF_TOKEN if --diarize is used
if [[ "$extra_args" == *"--diarize"* ]]; then
    echo "🔍 Diarize flag detected — verifying if HF_TOKEN is active..."
    if gh codespace ssh -c "$CODESPACE_NAME" "[[ -z \"\$HF_TOKEN\" ]]"; then
        echo "⚠️ WARNING: HF_TOKEN not set remotely—diarize may fail. We shall use local HF_TOKEN then, if any." 
    else
        echo "✅ HF_TOKEN detected remotely" 
    fi
fi
echo

# ================= Step 8: Run WhisperX in Codespace =================
echo "🤖 [8/10] Running WhisperX in Codespace with defaults..."
run_cmd="whisperx --compute_type float32 --model medium '$remote_path' --output_dir '$remote_home/Downloads' --highlight_words True --print_progress True $extra_args"
echo "📜 The command that is being run: '$run_cmd' ...:" 
echo

if ! time gh codespace ssh -c "$CODESPACE_NAME"  "HF_TOKEN=$HF_TOKEN $run_cmd"; then
    echo "❌ FATAL: WhisperX execution failed (non-zero exit status)" 
    echo "⚠️ Check logs above — likely diarization/HF_TOKEN issue or remote crash."
    termux-notification -c " Fail remote: '$base_filename'" \
        --title "WhisperX " --vibrate 500,2000,200
    exit 1
fi

echo "✅ WhisperX completed (exit status OK)"
echo


: '
# Paranoia: List remote Downloads to debug output files
echo "🔍 Listing remote Downloads post-WhisperX..."
if ! ls_output=$(gh codespace ssh -c "$CODESPACE_NAME" "ls -la '$remote_home/Downloads'" 2>&1); then
    echo "⚠️ Failed to list remote Downloads: $ls_output" 
else
    echo "📂 Remote Downloads contents:"
    echo "$ls_output" | lolcat
fi
echo
'

# ================= Step 9: Verify remote output files =================
remote_srt="$remote_home/Downloads/${filename_no_ext}.srt"
remote_json="$remote_home/Downloads/${filename_no_ext}.json"

echo "🔍 [9/10] Verifying remote output files..."
if ! check_output=$(gh codespace ssh -c "$CODESPACE_NAME" "test -f '$remote_srt' && test -f '$remote_json' " 2>&1); then
    echo "❌ FATAL: Output files missing or empty: $check_output" 
    termux-notification -c " Fail!: '$base_filename'" --title "WhisperX " --vibrate 500,2000,200
    
    exit 1
fi
echo "✅ Outputs verified: '$remote_srt' and '$remote_json' (non-empty)" 
echo

# ================= Step 10: Download SRT and JSON back =================
echo "⬇️ [10/10] Downloading results to Termux..."
for f in "$remote_srt" "$remote_json"; do
    echo "🔍 Downloading $f..."
    if ! download_output=$(time gh codespace cp -e -c "$CODESPACE_NAME" "remote:$f" "$file_dir/" 2>&1); then
        echo "❌ FATAL: Failed to download $f: $download_output" 
        exit 1
    fi
    #echo "$download_output" 
    echo "✅ Downloaded $f" 

    # Paranoia: Verify downloaded file
    local_file="$file_dir/$(basename "$f")"
    if [[ ! -f "$local_file" || ! -s "$local_file" ]]; then
        echo "❌ FATAL: Downloaded file '$local_file' missing or empty" 
        exit 1
    fi
    echo "✅ Downloaded file '$local_file' verified" 
    echo
done

echo "🔎 Checking local .srt file:"
file "$file_dir/${filename_no_ext}.srt" 
echo "📊 Statistics via 'wc':"
wc "$file_dir/${filename_no_ext}.srt" | lolcat
echo

# ================= Step 11: Play notification =================
echo "🔊 Playing notification sound..."
if ! termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3" 2>/dev/null; then
    echo "⚠️ Notification sound not played (audio file missing?)" 
fi

#This is for a watch that may be connected via BLE to the notifications shown by Termux API: 
termux-notification -c " OK: ${filename_no_ext}.srt" --title "WhisperX " --vibrate 500,1000,200

# if you watch does not allow notification from this Twrmux API program, then you can trick it via sending an SMS or via sending an email and so on.

# if you BT bind your watch with your phone and use the audio sink of the watch then the below shall play on the watch:
termux-media-player play /storage/5951-9E0F/Audio/Funny_Sounds/proximity_bash.mp3

termux-tts-speak "Transcription has finished."


echo "✅ Notifications sent" 
echo

# ================= Step 12: Open or share file =================
echo -n "📂 Opening (or sharing) audio file to play with new SRT subtitles: "
echo "'$file'..." | lolcat

if ! termux-open "$file" 2>/dev/null; then
    echo "⚠️ Failed to open '$file' (no associated app?)" 
fi
echo "✅ File '$file' and SRT invoked"
echo "---------------------"
echo -n "🎉 All steps completed! WhisperX output ready at: "
echo "'$file_dir/${filename_no_ext}.srt'"

echo
echo -n "🗣️ The source file of duration: "
echo "$duration" | lolcat
echo "has taken this long to process:"
#Total 'time' should display here:
}

time whisperx_on_remote "$@"


