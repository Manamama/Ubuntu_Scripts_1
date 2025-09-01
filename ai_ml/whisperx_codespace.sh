#!/usr/bin/env bash
set -euo pipefail

# ================= Runtime Intro =================
echo "=============================================================="
echo "📜 WhisperX Transcription Script (Paranoid Edition)"
echo
echo "This script will:"
echo "  1. Check that the input audio file exists."
echo "  2. Show its duration."
echo "  3. Ensure remote Downloads directory exists."
echo "  4. Upload the file to Codespace (skip if identical)."
echo "  5. Verify that the file exists remotely."
echo "  6. Check and install WhisperX if needed."
echo "  7. Run WhisperX transcription on the file."
echo "  8. Verify that outputs (.json and .srt) are created."
echo "  9. Download resulting files back to Termux."
echo "  10. Play a notification sound and open the SRT file."
echo "=============================================================="
echo

# ================= Input Args =================
if [[ $# -lt 1 ]]; then
    echo "❌ Usage: $0 <audio_file> [extra_args...]"
    exit 1
fi

file="$1"
shift
extra_args="$@"
base_filename=$(basename "$file")
filename_no_ext="${base_filename%.*}"
file_dir=$(dirname "$file")

echo "Input file (maybe shared, then path is changed): "
echo "$file" | lolcat
echo "You may add: '--model high' and '--diarize' there. Diarize requires your 'HF_TOKEN' env. Extra arguments for WhisperX: "
echo " $extra_args" | lolcat
echo "Base filename: '$base_filename'. "
echo

# ================= Step 1: Check input file =================
echo "🔍 Checking input file existence..."
if [[ ! -f "$file" ]]; then
    echo "❌ Input file not found: '$file'"
    exit 1
fi
echo "✅ Input file exists: '$file'"
echo

# ================= Step 2: Show file duration =================
echo "⏳ Determining audio duration..."
if duration=$(mediainfo --Inform='Audio;%Duration/String2%' "$file" 2>/dev/null); then
    echo -n "🗣️ Input file duration: "
    echo "$duration" | lolcat
else
    echo "⚠️ Could not determine duration"
fi
echo

# ================= Step 3: Detect Codespace =================
echo "🔍 Detecting available GitHub Codespace..."
CODESPACE_NAME=$(gh codespace list --json name,state | jq -r '.[] | .name' | head -n1)
if [[ -z "$CODESPACE_NAME" ]]; then
    echo "❌ No available Codespace found"
    exit 1
fi
echo -n "✅ Using Codespace: "
echo "$CODESPACE_NAME" | lolcat
echo

# ================= Step 4: Ensure remote Downloads directory =================
echo "📁 Ensuring remote Downloads directory exists..."
if gh codespace ssh -c "$CODESPACE_NAME" "mkdir -p Downloads" 2>/dev/null; then
    echo "✅ Remote Downloads directory ready"
else
    echo "❌ Failed to create remote Downloads directory"
    exit 1
fi
echo

# ================= Step 5: Upload to Codespace =================
remote_path="Downloads/$base_filename"
remote_path="$base_filename"

# Compare hashes
local_hash=$(sha256sum "$file" | cut -d' ' -f1)
remote_hash=$(gh codespace ssh -c "$CODESPACE_NAME" "test -f '$remote_path' && sha256sum '$remote_path' | cut -d' ' -f1" 2>/dev/null || true)

if [[ -n "$remote_hash" && "$local_hash" == "$remote_hash" ]]; then
    echo "✅ Skipped upload (as identical file: remote:$remote_path and local:$file)"
else
echo "📤 Uploading '$file' to Codespace..."

    if time gh codespace cp -c "$CODESPACE_NAME" "$file" "remote:$remote_path" | lolcat; then
        echo "✅ Uploaded to remote: $remote_path"
    else
        echo "❌ Upload failed"
        exit 1
    fi
fi
echo

# ================= Step 6: Verify remote file existence =================
echo "🔍 Verifying remote file existence..."
if gh codespace ssh -c "$CODESPACE_NAME" "test -f '$remote_path'"; then
    echo "✅ Remote file exists: $remote_path"
else
    echo "❌ Remote file missing, cannot continue"
    exit 1
fi
echo

# ================= Step 7: Check and install WhisperX =================
echo "🔍 Checking for WhisperX in Codespace..."
if gh codespace ssh -c "$CODESPACE_NAME" "command -v whisperx >/dev/null"; then
    echo "✅ WhisperX is installed"
else
    echo "⚠️ WhisperX not found, installing..."
    if gh codespace ssh -c "$CODESPACE_NAME" "pip install -U --user whisperx" 2>/dev/null; then
        echo "✅ WhisperX installed successfully"
    else
        echo "❌ Failed to install WhisperX"
        exit 1
    fi
fi
echo

# ================= Step 8: Run WhisperX in Codespace =================
echo "🤖 Running WhisperX in Codespace..."
run_cmd="whisperx --compute_type float32 --model medium '$remote_path' --output_dir Downloads --highlight_words True --print_progress True $extra_args"
echo "📜 Command: $run_cmd"

: '
if time gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd"; then
    echo "✅ WhisperX completed successfully"
else
    echo "❌ WhisperX run failed"
    termux-notification -c "Fail: $file_dir/${filename_no_ext}.srt" --title "WhisperX" --vibrate 500,1000,200
    exit 1
fi
'
echo

# ================= Step 9: Verify remote output files =================
remote_srt="Downloads/${filename_no_ext}.srt"
remote_json="Downloads/${filename_no_ext}.json"

echo "🔍 Checking remote output files..."
if gh codespace ssh -c "$CODESPACE_NAME" "test -f '$remote_srt' && test -f '$remote_json'"; then
    echo "✅ Both  '$remote_srt' && '$remote_json' exist remotely"
else
    echo "❌ Output files missing remotely"
    exit 1
fi
echo

# ================= Step 10: Download SRT and JSON back =================
echo "⬇️ Downloading resulting files back to Termux..."
for f in "$remote_srt" "$remote_json"; do
    echo "🔍 Downloading $f..."
    if time gh codespace cp -c "$CODESPACE_NAME" "remote:$f" "$file_dir/" | lolcat; then
        echo "✅ Downloaded ~/Downloads/${f#Downloads/}"
    else
        echo "❌ Failed to download ~/Downloads/${f#Downloads/}"
        exit 1
    fi
    echo
done


for f in "$remote_srt" "$remote_json"; do
    echo "🔍 Downloading ~/Downloads/${f#Downloads/}..."
    if time gh codespace cp -c - "$CODESPACE_NAME" "remote:$f" "$file_dir/" | lolcat; then
        echo "✅ Downloaded ~/Downloads/${f#Downloads/}"
    else
        echo "❌ Failed to download ~/Downloads/${f#Downloads/}"
        exit 1
    fi
    echo
done



echo "Checking local .srt file:"
file "$file_dir/${filename_no_ext}.srt" | lolcat
echo "Statistics via 'wc':"
wc "$file_dir/${filename_no_ext}.srt" | lolcat
echo

# ================= Step 11: Play notification =================
echo "🔊 Playing notification sound..."
termux-media-player play "Quack Quack-SoundBible.com-620056916.mp3" || echo "⚠️ Notification sound not played"
termux-notification -c "OK: $file_dir/${filename_no_ext}.srt" --title "WhisperX" --vibrate 500,1000,200
echo "✅ Notification sent"
echo

# ================= Step 12: Open or share file =================
echo -n "📂 Opening (or sharing) audio file: "
echo "'$file'..." | lolcat
termux-open "$file" || echo "⚠️ Failed to open '$file'"
echo "✅ File '$file' and its SRT file invoked"
echo "---------------------"
echo -n "🎉 All steps completed successfully. WhisperX output is ready: "
echo "'$file_dir/${filename_no_ext}.srt'" | lolcat