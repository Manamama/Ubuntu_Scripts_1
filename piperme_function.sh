# See https://github.com/OHF-Voice/piper1-gpl/issues/7 and https://gist.github.com/Manamama/5a76b442feeb35a96b42343d06dcee6c/edit
# This one is for Ubuntu, but could be made universal finally pacem some DIRT and modularization principles



piperme () 
{
    echo "piperme: Using piper TTS to voice text. Version 3.0.1 (DIRT logic)"

    local voice_model_dir="$HOME/.cache/piper"
    local lang_code="en"    # Default language
    local input_text=""
    local stdin_cmd=""
    local outfile="$PREFIX/tmp/piper_audio.wav"

    # Fallback if PREFIX/tmp does not exist
    if [[ ! -d "$PREFIX/tmp" ]]; then
        outfile="/tmp/piper_audio.wav"
    fi

    # --- Usage ---
    if [[ "$#" -eq 0 ]]; then
        echo "Usage: piperme [-l <lang>] <text_to_speak> | -f <file_to_speak>"
        echo "  -l <lang>: Language code (default: en)."
        echo "  <text_to_speak>: The text to synthesize."
        echo "  -f <file_to_speak>: Path to a file containing text to synthesize."
        echo "Example: piperme -l en \"Hello, how are you?\""
        echo "Example: piperme -l pl -f my_polish_text.txt"
        return 0
    fi

    # --- Parse args ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l)
                shift
                if [[ -z "$1" ]]; then
                    echo "Error: Missing language code after -l." 1>&2
                    return 1
                fi
                lang_code="$1"
                shift
                ;;
            -f)
                shift
                if [[ -z "$1" ]]; then
                    echo "Error: Missing filename after -f." 1>&2
                    return 1
                fi
                if [[ ! -f "$1" ]]; then
                    echo "Error: File '$1' not found." 1>&2
                    return 1
                fi
                stdin_cmd="cat \"$1\""
                shift
                ;;
            *)
                input_text="$*"
                stdin_cmd="echo \"$input_text\""
                break
                ;;
        esac
    done

    if [[ -z "$stdin_cmd" ]]; then
        echo "Error: No input text or file specified." 1>&2
        return 1
    fi

    # --- Build dictionary of available models ---
    declare -A model_dict
    while IFS= read -r file; do
        base=$(basename "$file" .onnx)
        if [[ "$base" == *medium* ]]; then
            # Extract 2-letter lang code (first part before '_' or '-')
            short_lang=$(echo "$base" | cut -d'_' -f1 | cut -d'-' -f1)
            # Only keep the first medium model found per language
            if [[ -z "${model_dict[$short_lang]}" ]]; then
                model_dict[$short_lang]="$base"
            fi
        fi
    done < <(find "$voice_model_dir" -maxdepth 1 -type f -name "*.onnx" 2>/dev/null)

    # --- Select model ---
    voice_base="${model_dict[$lang_code]}"
    if [[ -z "$voice_base" ]]; then
        echo "Error: No medium model found for language '$lang_code' in $voice_model_dir" 1>&2
        return 1
    fi

    model_file="$voice_model_dir/$voice_base.onnx"

    echo
    echo "Selected language: $lang_code"
    echo "Model used: $voice_base"
    echo

    # --- Check Piper ---
    local piper_executable
    piper_executable=$(command -v piper)
    if [[ -z "$piper_executable" ]]; then
        echo "Error: 'piper' executable not found in PATH." 1>&2
        return 1
    fi

    # --- Run Piper ---
    local piper_cmd="$piper_executable -m \"$model_file\" -f \"$outfile\""
    time eval "$stdin_cmd | $piper_cmd"

    # --- Playback ---
    echo "Playing it..."
    if command -v play-audio >/dev/null 2>&1; then
        play-audio "$outfile"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "$outfile"
    elif command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit "$outfile"
    else
        echo "Audio file generated at: $outfile"
        echo "No supported playback command found (play-audio, open, or ffplay)."
    fi
}

