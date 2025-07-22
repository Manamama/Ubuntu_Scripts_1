# See https://github.com/OHF-Voice/piper1-gpl/issues/7 and https://gist.github.com/Manamama/5a76b442feeb35a96b42343d06dcee6c/edit
# This one is for Ubuntu, but could be made universal finally pacem some DIR and modularization principle



piperme () 
{
    # --- Dependency Checks ---
    command -v piper >/dev/null || { echo "Error: 'piper' executable not found in PATH. Please install Piper TTS."; return 1; }
    command -v aplay >/dev/null || { echo "Error: 'aplay' executable not found in PATH. Please install alsa-utils."; return 1; }
    command -v sox >/dev/null || { echo "Warning: 'sox' (for play) not found. Playback might not work as expected."; }

    echo "piperme: Using piper TTS to voice text via sox. Version 2.1.4 (debugging pipe section)";
    local voice_model_dir="$HOME/.cache/piper";
    local lang="en";
    local input_text="";
    local input_file="";
    local voice_base="";

    # Display usage if no arguments are provided
    if [[ "$#" -eq 0 ]]; then
        echo "Usage: piperme [-pl|-en] <text_to_speak> | -f <file_to_speak>";
        echo "  -pl: Use Polish voice (pl_PL-darkman-medium)";
        echo "  -en: Use English voice (en_US-libritts-high, default)";
        echo "  <text_to_speak>: The text to synthesize.";
        echo "  -f <file_to_speak>: Path to a file containing text to synthesize.";
        echo "Example: piperme -en \"Hello, how are you?\"";
        echo "Example: piperme -pl -f my_polish_text.txt";
        return 0;
    fi;

    # Parse language argument
    if [[ "$1" == "-pl" ]]; then
        lang="pl";
        shift;
    elif [[ "$1" == "-en" ]]; then
        lang="en";
        shift;
    fi;

    # Set voice model based on language
    if [[ "$lang" == "pl" ]]; then
        voice_base="pl_PL-darkman-medium";
    else
        voice_base="en_US-libritts-high";
    fi;

    echo;
    echo "Model used: $voice_base";
    echo;

    # Playback options for sox's play command
    local play_opts="-r 22050 -c 1 -e signed -b 16 -t raw -";

    local stdin_cmd="";
    # Handle input: file or direct text
    if [[ "$1" == "-f" ]]; then
        shift;
        if [[ -z "$1" ]]; then
            echo "Error: Missing filename after -f." 1>&2;
            return 1;
        fi;
        if [[ ! -f "$1" ]]; then
            echo "Error: File '$1' not found." 1>&2;
            return 1;
        fi;
        stdin_cmd="cat \"$1\"";
    else
        if [[ -z "$1" ]]; then
            echo "Error: Please provide text or use -f <file>." 1>&2;
            return 1;
        fi;
        input_text="$*";
        stdin_cmd="echo \"$input_text\"";
    fi;

    # Check for existence of ONNX model files
    local model_file="$voice_model_dir/$voice_base.onnx";
    local config_file="$voice_model_dir/$voice_base.onnx.json"; # Still check for json config

    if [[ ! -f "$model_file" ]] || [[ ! -f "$config_file" ]]; then
        echo "Error: Voice model files for '$voice_base' missing in '$voice_model_dir'." 1>&2;
        return 1;
    fi;

    # Construct the piper command
    # The new piper CLI expects model name and PIPER_VOICE_PATH env var
    local piper_executable=$(command -v piper);
    if [[ -z "$piper_executable" ]]; then
        echo "Error: 'piper' executable not found in PATH. Please ensure Piper TTS is installed and in your system's PATH." 1>&2;
        return 1;
    fi;
    local piper_cmd_full="$stdin_cmd | $piper_cmd | aplay -f S16_LE -r 22050 -c 1";
    # Execute the command
    time eval "$piper_cmd_full"
}
