#!/usr/bin/env bash
set -euo pipefail

# ================= Runtime Intro =================
echo "=============================================================="
echo "📜 WhisperX Transcription Script (Paranoid Edition)"
echo
echo "This script will:"
echo "  1. Check that the input audio file exists."
echo "  2. Show its duration."
echo "  3. Upload the file into Codespace."
echo "  4. Verify that the file exists remotely."
echo "  5. Run WhisperX transcription on it."
echo "  6. Verify that outputs (.json and .srt) are created."
echo "  7. Download resulting files back to Termux."
echo "  8. Play a notification sound and open the SRT file."
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
echo -n "You may add: '--model high' and '--diarize' there. Extra arguments for WhisperX: "
echo " $extra_args" | lolcat
echo "Base filename: $base_filename"
echo

# ================= Step 1: Check input file =================
echo "🔍 Checking input file existence..."
if [[ ! -f "$file" ]]; then
    echo "❌ Input file not found: '$file' "
    exit 1
fi
echo "✅ Input file exists: '$file' "
echo

# ================= Step 2: Show file duration =================
echo "⏳ Determining audio duration..."
if duration=$(mediainfo --Inform='Audio;%Duration/String2%' "$file" 2>/dev/null); then
    echo -n "🗃️  Input file duration: "
    echo "$duration" | lolcat
else
    echo "⚠️  Could not determine duration"
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

# ================= Step 4: Upload to Codespace =================
echo "⬆️  Uploading '$file' to Codespace..."
if time gh codespace cp -e -c "$CODESPACE_NAME" "$file" "remote:~/Downloads/" | lolcat ; then
    echo "✅ Upload complete: ~/Downloads/$base_filename"
else
    echo "❌ Upload failed"
    exit 1
fi
echo

# ================= Step 5: Verify remote file existence =================
echo "🔍 Verifying remote file existence..."
if gh codespace ssh -c "$CODESPACE_NAME" "test -f \"\$HOME/Downloads/$base_filename\""; then
    echo "✅ Remote file exists: \"~/Downloads/$base_filename\" "
else
    echo "❌ Remote file missing, cannot continue"
    exit 1
fi
echo

# ================= Step 6: Run WhisperX in Codespace =================
echo "🤖 Running WhisperX. Default is medium quality, higlighting of words, and no diarize, unless you specified these,   inside Codespace..."
run_cmd="whisperx --compute_type float32 --model medium \"\$HOME/Downloads/$base_filename\" --output_dir \$HOME/Downloads/ --highlight_words True --print_progress True  $extra_args"
echo "📜 Command: $run_cmd"

if time gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd"; then
    echo "✅ WhisperX completed successfully inside Codespace"
else
    echo "❌ WhisperX run failed inside Codespace"
    exit 1
fi
echo

# ================= Step 7: Verify remote output files =================
remote_srt="\$HOME/Downloads/${filename_no_ext}.srt"
remote_json="\$HOME/Downloads/${filename_no_ext}.json"

echo "🔍 Checking remote output files..."
if gh codespace ssh -c "$CODESPACE_NAME" "test -f \"$remote_srt\" && test -f \"$remote_json\" "; then
    echo "✅ Both .srt and .json exist remotely"
else
    echo "❌ Output files missing remotely"
    exit 1
fi
echo

# # ================= Step 8: Download SRT and JSON back =================
echo "⬇️  Downloading resulting files back to Termux..."
remote_srt="remote:~/Downloads/${filename_no_ext}.srt"
remote_json="remote:~/Downloads/${filename_no_ext}.json"

for f in "$remote_srt" "$remote_json"; do
    echo "🔍 Downloading ${f#remote:}..."
    if time gh codespace cp -e -c "$CODESPACE_NAME" "$f" "$file_dir/"; then
        echo "✅ Downloaded ${f#remote:}"
echo
    else
        
echo "❌ Failed to download ${f#remote:}"
    fi
done

echo "But let us check also local version of the .srt file:"
file "$file_dir/${filename_no_ext}.srt"
echo "Statistics via 'wc':"
wc "$file_dir/${filename_no_ext}.srt" | lolcat
echo

# ================= Step 9: Play notification  =================
echo "🔔 Playing notification sound..."
termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3"
echo "✅ Notification sound played"



# Done
# ---------------------------

echo -n "📂 Opening (or sharing) audio file: " 
echo "'$file'..." | lolcat
# this version sharing sometimes works better somehow with some apps:
#termux-share "$file"
termux-open "$file"

echo "✅ File '$file', with the corresponding newly whisperx created SRT file, has been invoked."
echo "---------------------"
echo -n "🎉 All the steps completed successfully. WhisperX output is ready e.g. here: " 
 echo " '$file_dir/${filename_no_ext}.srt'  " | lolcat
