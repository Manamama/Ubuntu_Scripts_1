#!/bin/bash
# Merged script to describe a single image or recursively describe images in folders.
# Generates EXIF metadata and an HTML report for folders.
# Version 4.1.0

# --- CONFIGURATION ---
location="/media/zezen/HP_P7_Data/Temp/AI_models"


model_name="MobileVLM-3B-Q5_K_M.gguf"

mmproj_model_path="$location/MobileVLM-3B-mmproj-f16.gguf"


model_name="llava_multimodal/llava-v1.5-7b-Q4_K_multimodal.gguf"

mmproj_model_path="$location/llava_multimodal/llava-v1.5-7b-mmproj-f16.gguf"
#Can you use llava-v1.5-7b-mmproj-f16.gguf with smaller Llama GGUF variants (e.g., 3B or 5B) without quality loss? No, not reliably. The mmproj is bespoke to LLaVA-v1.5-7B’s architecture—specifically its 7B Llama backbone with a hidden size of 4096 and a projector output dimension matched to that. Smaller Llama GGUF files (e.g., 3B or 5B) have different hidden sizes (typically 3200 or 3584), mismatched vocabulary embeddings, and altered layer norms. Forcing the mmproj onto a 3B GGUF (e.g., Llama-3-3B-Q4_K_M) causes dimension mismatches in llama.cpp’s multimodal pipeline—expect crashes or NaN outputs unless you re-quantize or pad the model, which risks breaking alignment.LLaVA-7B on VQAv2 scores 78% accuracy; a 3B variant drops to ~65%, even with the same mmproj, due to weaker language reasoning

llm_model_path="$location/$model_name"



# The threads is needed here, otherwise half threads available is used: 
command="llama-mtmd-cli --chat-template deepseek --temp 0.1 --threads 8 --prio -1"
#Think of daemonize it, as server, for batch processing, as it takes 40 seconds to offload and onload to RAM and Swap. 
story_context="None yet, that is first image in series..." 
# --- IMAGE PROCESSING FUNCTION ---
# Takes one argument: the path to the image to process.
process_image() {
    local image_path="$1"

    # Verify model files exist
    if [ ! -f "$llm_model_path" ] || [ ! -f "$mmproj_model_path" ]; then
        echo "Error: Model file ($llm_model_path) or mmproj file ($mmproj_model_path) not found."
        return 1
    fi

    # Verify image file exists
    if [ ! -f "$image_path" ]; then
        echo "Error: Image file ($image_path) not found."
        return 1
    fi

    echo "---"
    echo "Processing: $image_path"

    # Check if the image already has a Description
    local existing_description
    existing_description=$(exiftool -Description -s3 "$image_path")
    if [ -n "$existing_description" ]; then
        echo -n "File has Description: "
        echo "$existing_description" | lolcat
        echo "Use: ' exiftool -Description= -EnhanceParams= \"$image_path\" ' to clear it up."
        return 0
    fi

    echo "The original file has no description. Working on creating it..."
    
    # Debug: Print the command
    #echo "Debug CMD: $command -m $llm_model_path --mmproj $mmproj_model_path --image \"$image_path\" -p \"Describe this image in detail\""

    # Run llama-mtmd-cli and extract description
    
    #prompt="Context (previous video frame): $story_context. \n\n Now, do describe the current image, which is the next frame of that video, in detail"
    #echo $prompt
#echo
    prompt="Describe the image in detail"
echo $command -m "$llm_model_path" --mmproj "$mmproj_model_path" --image "$image_path" -p  "$(printf '%s' "$prompt")"
    local description
time description=$($command -m "$llm_model_path" --mmproj "$mmproj_model_path" --image "$image_path" -p  "$(printf '%s' "$prompt")" 2>/dev/null  | awk 'BEGIN{RS=""} /image decoded \(batch 1\/1\)/{getline; print; exit}')

    # Check if description was generated
    if [ -z "$description" ]; then
        echo "Error: Failed to generate description for $image_path."
        return 1
    fi
   story_context="$description"
    # Write description and model name to EXIF metadata
    exiftool -Description="$description" -EnhanceParams="$model_name" "$image_path" -overwrite_original >/dev/null 2>&1

    echo "New Description added. Checking it:"
    exiftool -Description -EnhanceParams "$image_path" | lolcat
}

# --- DIRECTORY TRAVERSAL & HTML REPORTING ---
traverse() {
    local dir_path="$1"
    echo "---"
    echo "Processing directory for HTML report: $dir_path"

    local html_file="$dir_path/$(basename "$dir_path").html"
    echo "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>Images in $(basename "$dir_path")</title><style>body { font-family: sans-serif; display: flex; flex-wrap: wrap; } .container { display: flex; width: 100%; margin: 10px; border-bottom: 1px solid #ccc; padding-bottom: 10px; align-items: center; } .thumbnail img { width: auto; height: 350px; margin-right: 20px; } .description { font-size: 1.2em; }</style></head><body><h1>Images in: \"$dir_path\"</h1>" > "$html_file"

    # --- SORTED IMAGE LOOP ---
    find "$dir_path" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
      | sort -V | while IFS= read -r image; do
        process_image "$image"

        local description
        description=$(exiftool -Description -s3 "$image")

        local safe_filename
        safe_filename=$(printf '%s\n' "$(basename "$image")" | sed "s/'/%27/g; s/ /%20/g")

        echo "<div class='container'><div class='thumbnail'><a href='$safe_filename' target='_blank'><img src='$safe_filename' alt='$(basename "$image")'></a></div><div class='description'><strong>$(basename "$image")</strong><br>$description</div></div>" >> "$html_file"
    done

    echo "</body></html>" >> "$html_file"
    echo -n "HTML report created: " 
    echo "$html_file" | lolcat

    find "$dir_path" -mindepth 1 -type d | while IFS= read -r subdir; do
        traverse "$subdir"
    done
}

# --- MAIN LOGIC ---
INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <file_or_directory_path>"
    exit 1
fi

# Final check on model files before starting
if [ ! -f "$llm_model_path" ] || [ ! -f "$mmproj_model_path" ]; then
    echo "Error: Global check failed. Model file ($llm_model_path) or mmproj file ($mmproj_model_path) not found."
    exit 1
fi
echo "Describe image with a VLM, version 4.2.1, better mmproj GGUF"
#Check if the model is righ: 
#llama-gguf "$mmproj_model_path"


if [ -f "$INPUT" ]; then
    echo "Input is a single file."
    process_image "$INPUT"
elif [ -d "$INPUT" ]; then
    echo "Input is a directory."
    start_dir=$(pwd)
    traverse "$INPUT"
    cd "$start_dir" || exit
    echo "Finished recursion. Opening the result ... "
    open "$html_file"
else
    echo "Error: '$INPUT' is not a valid file or directory."
    exit 1
fi
