# Processes the audio file and generates subtitles
process_audio() {
    local file="$1"
    local base_filename=$(basename "$file")
    local base_filename_without_ext="${base_filename%.*}"
    local dir_name=$(dirname "$file")
    local full_path_without_ext="$dir_name/$base_filename_without_ext"

    echo "Filepath and additional args being passed to whisperx: $@"
    echo "   → file: $file"
    echo "   → full_path_without_ext: $full_path_without_ext"

    echo -n "🗃️  Input file duration: "
echo $(mediainfo --Inform='Audio;%Duration/String2%' "$file") | lolcat

    echo

    echo "Running whisperx with highlighted words, float32 precision (needed on Android), --threads 6, --model medium."
echo "(If that crashes Droid, because of the memory error, change to '--model small', provide language: '--language Polish' to avoid detection, restart Android, use outside machine e.g. GitHub Codespaces, via ssh call...)"
    echo -n "Add " 
echo -n "--highlight_words False --no_align" | lolcat
echo " to speed up."

    whisperx \
        --compute_type float32 \
        --print_progress True \
        --fp16 False \
        --threads 6 \
--model medium \
        --output_dir "$dir_name" \
        --highlight_words True \
        "$file" "${@:2}"

    python /storage/emulated/0/Documents/Android_Code_snippets/Scripts_python/convert_whisperx_confidence_scores_to_colors_srt.py "$full_path_without_ext.json"
    python /storage/emulated/0/Documents/Android_Code_snippets/Scripts_python/convert_whisperx_underlines_to_red.py "$full_path_without_ext.srt"

    echo "Saved subtitles to: $dir_name, and colorized it, too."
}


whisperx_me() {
echo "version 2.0.5"
    local file="$1"
    shift
    echo "Processing: \"$file\" $* ..."
    process_audio "$file" "$@"
}


whisperx_me_deb() {
    local file_path="$1"
    local dir_name=$(dirname "$file_path")
    local external_sd_path="$HOME/storage/external_SD"
    local temp_path="$PREFIX/tmp/whisperx"
    mkdir -p "$temp_path"

   echo

    echo "Received filepath: $file_path"

    if [[ "$file_path" == $external_sd_path* ]]; then
        echo "On 🔐 external SD, so copying to internal storage..."
        cp "$file_path" "$temp_path/"
        file_path="$temp_path/$(basename "$file_path")"
        echo "Result after copying:"
        ls -l "$file_path"
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "File $file_path not found, maybe still on 🔐 external SD."
        return 1
    fi
    
echo "Break now and add " 
echo "--highlight_words False --no_align" | lolcat
echo " to speed up."

    echo "Calling whisperxme in prooted Debian with: $file_path ${@:2} ..."
    proot-distro login debian --shared-tmp -- whisperxme "$file_path" "${@:2}"

    if [[ "$file_path" == $temp_path* ]]; then
        rm "$file_path"
        mv "$temp_path"/* "$dir_name/"
    fi

    echo "Opening the source 📺 $file_path ..."
    termux-open "$file_path"
    termux-toast -g bottom -b red "Whisperx finished"
    termux-vibrate
}
