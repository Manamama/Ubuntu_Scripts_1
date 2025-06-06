#!/bin/bash
echo "Recursive directory traversal and HTML generation - Ver. 3.3.3, Android"

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
    cd "$1" || { echo "Failed to change directory to '$1' "; exit 1; }

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
    shopt -s nullglob
    
    for image in "$1"/*.{jpg,jpeg,png,gif}; do
        if [[ -f "$image" ]]; then
            # Extract existing description using ExifTool
            existing_description=$(exiftool -Description -s "$image")
            
            # If no description exists, generate one
            if [[ -z "$existing_description" ]]; then
                echo -e "Generating description for \033[34m$image\033[0m..."  # Filename in blue
                # Generate a description using llava-cli
                time description=$(llava-cli --log-disable -c 0 --color --threads 4 --temp 0.2 --image "$image" -m /storage/emulated/0/LLMs/MobileVLM-3B-Q4_K_M.gguf --mmproj /storage/emulated/0/LLMs/MobileVLM-3B-mmproj-f16.gguf)
                # Write the new description to the image's metadata
                exiftool -overwrite_original -Description="$description" "$image"  
                echo -e "New description for \033[34m$image\033[0m is: \033[33m$description\033[0m"  # New description in yellow
                
                # Pronounce new description in background
                termux-open "$image" &
                #termux-tts-speak "$description" &
                export description_pol= $(trans -b en:pl "$description")
                echo "$description_pol"
                termux-tts-speak -l pol "$description_pol" 

               
                
            else
                echo -e "File \033[34m$image\033[0m already had this description: \033[32m$existing_description\033[0m"  # Existing description in green
                export description_pol="$(trans -b en:pl "$existing_description")"
                echo $description_pol
                termux-tts-speak -l pol "$description_pol"
                
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

        fi
    done

    # End HTML file
    echo "</body>" >> "$html_file" 
    echo "</html>" >> "$html_file"

    # Debugging output to confirm HTML file creation
    if [[ -f "$html_file" ]]; then
        echo "HTML file created: $html_file. We convert the HTML file to PDF..."

        # Change to the source directory as relative paths, for pandoc only
        cd "$(dirname "$html_file")" || exit

        # Convert HTML to PDF using pandoc
        pdf_file="${html_file}.pdf"
        pandoc -i "$html_file" -o "$pdf_file" --pdf-engine=weasyprint

        # Check if PDF conversion was successful
        if [[ -f "$pdf_file" ]]; then
            echo "PDF file created: $pdf_file."
            
            # Open the PDF file in viewer 
            termux-open "$pdf_file" &
        else
            echo "Failed to create PDF file from: $html_file."
        fi
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

