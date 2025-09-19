#!/usr/bin/env bash

    set -euo pipefail

echo "📜 WhisperX Transcription from URL (Paranoid Android & gh User Edition)"
echo "Version 1.3.5"

    if [[ $# -lt 1 ]]; then
        echo "❌ Usage: $0 <youtube_url> [extra_args...]"
        exit 1
    fi

    url="$1"
    shift
    extra_args="$@"

    echo -n "📥 Input YouTube URL: "
    echo "$url" | lolcat
    echo "🔧 Extra WhisperX Args: '$extra_args'"
    echo



echo -n "Checking the OS: " 

if [ -n "${TERMUX__HOME-}" ]; then
    echo  "📲  We are in Termux.  "
else
    echo  "We are not in Termux."
fi
echo

    # ================= Step 1: Detect Codespace =================
    echo -n "🔍 Detecting GitHub Codespace... : "
    CODESPACE_NAME=$(gh codespace list --json name,state | jq -r '.[] | .name' | head -n1)
    if [[ -z "$CODESPACE_NAME" ]]; then
        echo "❌ FATAL: No Codespace found"
        exit 1
    fi
    # echo -n "✅ Codespace detected:"
echo "$CODESPACE_NAME" | lolcat
    echo


: '
# Paranoia: Check HF_TOKEN if --diarize is used
#We skip it as we use the local HF_TOKEN here

if [[ "$extra_args" == *"--diarize"* ]]; then
    echo "🔍 Diarize flag detected — verifying if HF_TOKEN is set remotely..."
    if gh codespace ssh -c "$CODESPACE_NAME" "[[ -z \"\$HF_TOKEN\" ]]"; then
        echo "⚠️  WARNING: HF_TOKEN not set remotely — diarize may fail. We shall use local HF_TOKEN then, if any." 
    else
        echo "✅  HF_TOKEN detected remotely" 
    fi
fi

'

echo

    # ================= Step 2: Ensure remote Downloads directory =================
    echo "📁 Ensuring remote Downloads directory exists..."
    gh codespace ssh -c "$CODESPACE_NAME" "mkdir -p ~/Downloads"

    # ================= Step 3: Download with yt-dlp =================
    echo "🎬 Downloading the audio from the online media via 'yt-dlp --extract-audio' on the remote machine..."
    echo "Note: The tool uses the '--cookies-from-browser chrome' option. To create these cookies on the remote machine you need, in very short:"
    echo "1. Install e.g. 'google-chrome' application. 2. Run 'google-chrome  --remote-debugging-port=9222 https://youtube.com' 3. Forward that port in e.g. Visual Studio Code or via 'gh ports forward'. 4. Log in to your GitHub account to accept forwarding. 5. Log in to the new virgin Google Chrome browser window with your active Google Account (a throwaway one, for security). 6. Hope that this all works. " 
    # Extracts audio reliably because it downloads whatever format contains audio (even if embedded in video) and lets --extract-audio + --audio-format mp3 handle conversion, so no assumptions about separate audio streams are needed. Stores in ~/Downloads, get clean filename
    remote_audio=$(gh codespace ssh -c "$CODESPACE_NAME" \
    "cd ~/Downloads && yt-dlp --no-playlist --extract-audio --audio-format mp3 --cookies-from-browser chrome --restrict-filenames --trim-filenames 20 --print after_move:filepath '$url'")


    if [[ -z "$remote_audio" ]]; then
        echo "❌ FATAL: yt-dlp did not return a file path"
        exit 1
    fi



echo -n "✅ Downloaded: "
echo "$remote_audio" | lolcat


filename_no_ext=$(basename "$remote_audio" .mp3)

# here we were sanity checking the file size and the file name.
# run_cmd="ls -la $remote_audio    "
#echo Trying: $run_cmd :
# gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd" | lolcat

run_cmd="mediainfo --Inform='Audio;%Duration/String2%' $remote_audio "

# here we were testing the escape quotes for a while; in short do not use for file names: 
# echo Trying: $run_cmd :
# gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd" | lolcat

#echo " Extracting audio duration..."
if duration=$(gh codespace ssh -c "$CODESPACE_NAME" "$run_cmd" ); then
    echo -n "🗣️  Duration of the audio track: "
    echo "$duration" | lolcat
else
    echo "⚠️ Could not extract duration (proceeding anyway)" 
fi

    
    remote_srt="~/Downloads/${filename_no_ext}.srt"
remote_txt="~/Downloads/${filename_no_ext}.txt"

echo
#echo "The remote file name should look like this: $remote_srt"

    # ================= Step 4: Check/install WhisperX =================
    echo "🔍 Checking the presence of WhisperX..."
    if ! gh codespace ssh -c "$CODESPACE_NAME" "command -v whisperx >/dev/null"; then
        echo "⚠️ WhisperX not found, installing..."
        gh codespace ssh -c "$CODESPACE_NAME" "pip install -U --user whisperx"
        echo "✅ WhisperX installed"
    fi

    # ================= Step 5: Run WhisperX =================
    echo "🤖 ⏳ Running WhisperX transcription (lots of warnings shall be displayed, do ignore most of these)... :"

# ' --verbose False' supresses  the transcription progress information and we do not want it.
#  --highlight_words True,  the default value is false. This adds words underlining, which can be colorized later on, but increases the size significantly.

   run_cmd="whisperx --compute_type float32 --model medium '$remote_audio'  --output_dir ~/Downloads --print_progress True  $extra_args"



# activate the below, should we resigned from highlighting words as it shall be faster.

#run_cmd="whisperx --compute_type float32 --model medium '$remote_audio' --output_dir ~/Downloads  --print_progress True $extra_args"

   time gh codespace ssh -c "$CODESPACE_NAME" HF_TOKEN=$HF_TOKEN "$run_cmd"

# ================= Step 6: Return only text =================
    echo "📜 Fetching transcription text: '$remote_srt'..."   

 #gh codespace ssh -c "$CODESPACE_NAME" "cat $remote_srt" 

gh codespace ssh -c "$CODESPACE_NAME" "cat $remote_txt" | lolcat


# if you BT bind your watch with your phone and use the audio sink of the watch then the below shall play on the watch:




if [ -n "${TERMUX__HOME-}" ]; then

    #Termux, adapt paths: 
    echo "🔊 Playing notification sound..."
    if [[ ! -f "/storage/5951-9E0F/Audio/Funny_Sounds/proximity_bash.mp3" ]]; then  
        echo "⚠️ Notification sound not played (audio file missing?)" 
    else 
    termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/proximity_bash.mp3"

    fi

    termux-tts-speak "Transcription from URL has  finished."

    #This is for a watch that may be connected via BLE to the notifications shown by Termux API: 
    termux-notification -c " OK: ${filename_no_ext}.srt" --title "WhisperX " --vibrate 500,1000,200

else 


    #Ubuntu, adapt the paths: 
    if [[ ! -f "~/Music/Timer_and_sounds/ping_finished_whispering.wav
    " ]]; then  
        echo "⚠️ Notification sound not played (audio file missing?)" 
    else 



        aplay "~/Music/Timer_and_sounds/ping_finished_whispering.wav"
    fi

fi


#Same but for full Linux: 
#tts --text "Transcription from URL has  finished."


# if you watch does not allow notification from this Termux API program, then you can trick it via sending an SMS or via sending an email and so on.





echo
echo "✅ Notifications executed" 
echo

  

echo
echo -n "🗣️  The source file of duration: "
echo "$duration" | lolcat
echo " has taken this long to process:"
#Total 'time' should display here:


