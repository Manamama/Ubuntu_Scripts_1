#!/bin/bash
echo "Recursive directory traversal and HTML generation - Ver. 3.6.4, Ubuntu"
#You need to install this: https://github.com/haotian-liu/LLaVA for "llava-cli" or this: https://github.com/ggerganov/llama.cpp for "llama-llava-cli" 

# llama-llava-cli -m <llava-v1.5-7b/ggml-model-q5_k.gguf> --mmproj <llava-v1.5-7b/mmproj-model-f16.gguf> --image <path/to/an/image.jpg> --image <path/to/another/image.jpg> [--temp 0.1] [-p "describe the image in detail."]


location="/media/zezen/HP_P7_Data/Temp/AI_models"
        
        

llm_model_path="$location/gemma-3-12b-it-Q2_K_L.gguf"
llm_model_path="$location/MobileVLM-3B-Q5_K_M.gguf"


#Changed in year 2025, for this MobileVLM model:
command="llama-mtmd-cli --chat-template deepseek"



mmproj_model_path="$location/google_gemma-3-12b-it-mmproj-f16.gguf"
mmproj_model_path="$location/MobileVLM-3B-mmproj-f16.gguf"


#llama-llava-cli -c 0 --threads 24 --temp 0.2 -m /media/zezen/Dysk_Użytkownika/CG_Czytelnik/Matapata/LLMs/mobilevlm-3b.Q4_K_M.gguf --mmproj /media/zezen/Dysk_Użytkownika/CG_Czytelnik/Matapata/LLMs/MobileVLM-3B-mmproj-f16.gguf --image "/home/zezen/Pictures/Test6/800px-Inmaculada_Concepción_de_Aranjuez.jpg"  | sed -n '/encode_image_with_clip: image encoded in/{n;p;:a;n;p;ba}' | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' 


#echo Test mmproj_model_path: $mmproj_model_path 
#exit



# Check if directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

start_dir=$(pwd)

# Function to sanitize filenames for HTML
sanitize_filename() {
    local filename="$1"
    # Use printf to escape special characters for HTML
    printf '%s\n' "$filename" | sed 's/ /%20/g; s/:/%3A/g; s/&/%26/g; s/+/%2B/g; s/?/%3F/g; s/#/%23/g; s/%/%25/g'
}


        
        

function traverse() {

    # Change to the new directory
    #cd "$1" || { echo "Failed to change directory to '$1' "; exit 1; }

    echo "Processing subfolders and folder: $1 ... " # Print the current directory

    # Create a new HTML file for the current directory
    local html_file="$1/$(basename "$1").html"  # Create an HTML file named after the directory

    # Start building HTML content
    echo "<!DOCTYPE html>" > "$html_file"
    echo "<html lang='en'>" >> "$html_file"
    echo "<head>" >> "$html_file"
    echo "<meta charset='UTF-8'>" >> "$html_file"
    echo "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" >> "$html_file"
    echo "<title>Images in $(basename "$1") folder, full path: \"$1\"</title>" >> "$html_file"
    echo "<style>" >> "$html_file"
    echo "body { display: flex; flex-wrap: wrap; }" >> "$html_file"
    echo ".container { display: flex; width: 100%; }" >> "$html_file"
    echo ".thumbnail { margin: 10px; display: flex; }" >> "$html_file"
    echo ".thumbnail img { width: auto; height: 350px; display: flex; }" >> "$html_file"
    echo ".description { font-size: 1.5em; padding-top: 10px; }" >> "$html_file"
    echo "</style>" >> "$html_file"
    echo "</head>" >> "$html_file"
    echo "<body>" >> "$html_file"
    echo "<h1>Images in the folder: \"$(basename "$1")\", the full path: \"$1\"</h1>" >> "$html_file"

    # Loop through each image file in the current directory
    #Legacy: shopt -s nullglob # Avoid unmatched globs being treated as literal strings

    
    # Use find to match image files with the correct extensions
    find "$1" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | while IFS= read -r image; do
        # Extract existing description using ExifTool
        existing_description=$(exiftool -Description -s "$image")
        description=$existing_description
        
                
            # If no description exists, generate one
            if [[ -z "$existing_description" ]]; then
                echo -e "Generating description for: \033[34m$image\033[0m..."  # Filename in blue
                                
                # Generate a description using llava-cli
                #Use: --threads 24 to increase CPU usage
                #echo $llm_model_path ... 
                #llama-llava-cli -c 0  --temp 0.0 -m $llm_model_path --mmproj $mmproj_model_path --image "$image" -p "Provide a full description." 
                #echo "Now, as description:"
                echo llama-gemma3-cli --threads 10 --temp 0.1 -m $llm_model_path --mmproj $mmproj_model_path --image "$image"
                echo 
                #llama-gemma3-cli -c 0 --threads 10 --temp 0.1 -m $llm_model_path --mmproj $mmproj_model_path --image "$image" -p "Provide a full description." 
                #$command -c 0 --threads 10 --temp 0.1 -m $llm_model_path --mmproj $mmproj_model_path --image "$image" -p "Provide a full description." --log-file "/tmp/discarded_llava_log.txt" 2>/dev/null | sed -n '/encode_image_with_clip: image encoded in/{n;p;:a;n;p;ba}' | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
                time description=$($command  --threads 10 --temp 0.1 -m $llm_model_path --mmproj $mmproj_model_path --image "$image" -p "Provide a full description." --log-file "/tmp/discarded_llava_log.txt" 2>/dev/null | sed -n '/encode_image_with_clip: image encoded in/{n;p;:a;n;p;ba}' | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                eog -w  "$image" &  
                
                # Write the new description to the image's metadata
                exiftool -overwrite_original -Description="$description" "$image"  
                echo -e "New description for \033[34m$image\033[0m is: \033[33m$description\033[0m"  # New description in yellow
                
                # Pronounce new description in background
                #termux-open "$image" &
                #xdg-open "$image" &
                #Speak in English
                #termux-tts-speak "$description" &
                #Translation to Polish
                #export description_pol="$(trans -b en:pl "$description")"
                #
                #echo $description_pol
                #termux-tts-speak -l pol "$description_pol"

               
                
            else
                echo -e "File \033[34m$image\033[0m already had this description: \033[32m$existing_description\033[0m"  # Existing description in green
                description=$existing_description

                #export description_pol="$(trans -b en:pl "$existing_description")"
                #echo $description_pol
                #termux-tts-speak -l pol "$description_pol"
                
                #description_pol="$existing_description"
            fi

            echo ""  # Just an empty line for clarity in terminal output
            
            # Use printf to encode filename directly within echo, so-called "percent encoding" for e.g. `don't ... ` filenames:
            safe_filename=$(printf '%s\n' "$(basename "$image")" | sed 's/ /%20/g; s/:/%3A/g; s/&/%26/g; s/+/%2B/g; s/?/%3F/g; s/#/%23/g; s/'\''/%27/g')

            # Add thumbnail and description to HTML using encoded filename
            echo "<div class='container'>" >> "$html_file"
            echo "<div class='thumbnail'><a href='$safe_filename' target='_blank'><img src='$safe_filename' alt='$(basename "$image")'></a></div>" >> "$html_file"
            echo "<div class='description'><strong>$(basename "$image")</strong><br>$description</div>" >> "$html_file"
            echo "</div>" >> "$html_file"

        #fi
    done

    # End HTML file
    echo "</body>" >> "$html_file" 
    echo "</html>" >> "$html_file"

    # Debugging output to confirm HTML file creation
    if [[ -f "$html_file" ]]; then
        echo "HTML file created: $html_file. ."
        open "$html_file" &
	: '
	echo "We convert the HTML file to PDF.."
        # Change to the source directory as relative paths, for pandoc only
        cd "$(dirname "$html_file")" || exit

        # Convert HTML to PDF using pandoc
        pdf_file="${html_file}.pdf"
        pandoc -i "$html_file" -o "$pdf_file" --pdf-engine=weasyprint

        # Check if PDF conversion was successful
        if [[ -f "$pdf_file" ]]; then
            echo "PDF file created: $pdf_file."
            
            # Open the PDF file in viewer 
            open "$pdf_file" &
        else
            echo "Failed to create PDF file from: $html_file."
        fi
        '
    else
        echo "Failed to create HTML file: $html_file."
    fi

    # Loop through each subdirectory
    for subdir in "$1"/*/; do
        [ -d "$subdir" ] || continue  # Check if it's a directory
        traverse "$subdir"  # Recurse into subdirectory
    done
}

# Call the function with the parent directory containing all subfolders

dir="$1"
traverse "$dir"

# Return to the starting directory
cd "$start_dir" || { echo "Failed to return to starting directory"; exit 1; }

echo "Finished recursion. Returned to starting directory: $start_dir"

