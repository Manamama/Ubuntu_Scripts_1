#!/bin/bash
echo "Recursive directory traversal and HTML generation - Ver. 2.6"

# Check if directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

DIR="$1"
 

function traverse() {
    local dir="$1"
    echo "Processing subfolders and folder: $dir ... "  # Print the current directory

    # Create a new HTML file for the current directory
    local html_file="$dir/$(basename "$dir").html"  # Create an HTML file named after the directory

    # Start building HTML content
    echo "<!DOCTYPE html>" > "$html_file"
    echo "<html lang='en'>" >> "$html_file"
    echo "<head>" >> "$html_file"
    echo "<meta charset='UTF-8'>" >> "$html_file"
    echo "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" >> "$html_file"
    echo "<title>Images in $(basename "$dir")</title>" >> "$html_file"
    echo "<style>" >> "$html_file"
    echo "body { display: flex; flex-wrap: wrap; }" >> "$html_file"
    echo ".container { display: flex; width: 100%; }" >> "$html_file"
    echo ".thumbnail {   margin: 10px; display: flex}" >> "$html_file"
    echo ".thumbnail img { width: auto; height: 350px; display: flex}" >> "$html_file"
    echo ".description { font-size: 1.5em; padding-top: 10px; }" >> "$html_file"
    echo "</style>" >> "$html_file"
    echo "</head>" >> "$html_file"
    echo "<body>" >> "$html_file"
    echo "<h1>Images in $(basename "$dir")</h1>" >> "$html_file"

    # Loop through each image file in the current directory
    shopt -s nullglob
    for image in "$dir"/*.{jpg,jpeg,png,gif}; do
        if [[ -f "$image" ]]; then
            # Extract existing description using ExifTool
            existing_description=$(exiftool -Description -s -s -s "$image")
            
            # If no description exists, generate one
            if [[ -z "$existing_description" ]]; then
                echo -e "Generating description for \033[34m$image\033[0m..."  # Filename in blue
                # Generate a description using llava-cli
                description=$(llava-cli --log-disable -c 0 --color --threads 4 --temp 0.2 --image "$image" -m /mnt/HP_P7_Data/Temp/GPT4All_DBs/MobileVLM-3B-Q5_K_M.gguf --mmproj /mnt/HP_P7_Data/Temp/GPT4All_DBs/MobileVLM-3B-mmproj-f16.gguf)
                # Write the new description to the image's metadata
                exiftool -overwrite_original -Description="$description" "$image"  
                echo -e "New description for \033[34m$image\033[0m is: \033[33m$description\033[0m"  # New description in yellow
                
                # Pronounce new description (ensure this works correctly)
                (tts --text "$description") & 
                mpv tts_output.wav 

            else
                echo -e "File \033[34m$image\033[0m had already a description: \033[32m$existing_description\033[0m"  # Existing description in green
                description="$existing_description"
            fi

            echo ""  # Just an empty line for clarity in terminal output
            
            # Add thumbnail and description to HTML
            echo "<div class='container'>" >> "$html_file"
            echo "<div class='thumbnail'><img src='$image' alt='$(basename "$image")'></div>" >> "$html_file"
            echo "<div class='description'><strong>$(basename "$image")</strong><br>$description</div>" >> "$html_file"
            echo "</div>" >> "$html_file"

        fi
    done

    # End HTML file
    echo "</body>" >> "$html_file" 
    echo "</html>" >> "$html_file"

    # Debugging output to confirm HTML file creation
    if [[ -f "$html_file" ]]; then
        echo "HTML file created: $html_file."
        open "$html_file" &
    else
        echo "Failed to create HTML file: $html_file."
    fi

    # Loop through each subdirectory
    for subdir in "$dir"/*/; do
        [ -d "$subdir" ] || continue  # Check if it's a directory
        traverse "$subdir"  # Recurse into subdirectory
    done
}
# Call the function with the parent directory containing all subfolders
traverse "$DIR"
