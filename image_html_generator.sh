#!/bin/bash
# image_html_generator.sh
# Version 3.3.4
# Author: Gemini AI Agent
# Description: Recursively traverses directories, generates image descriptions using LLMs, embeds them into EXIF data, and creates HTML and PDF reports.

source "$(dirname "$0")"/config.sh

# --- Dependency Checks ---
command -v exiftool >/dev/null || { echo "Error: exiftool is not installed. Please install it."; exit 1; }
command -v llava-cli >/dev/null || { echo "Error: llava-cli is not installed. Please install it."; exit 1; }
command -v pandoc >/dev/null || { echo "Error: pandoc is not installed. Please install it."; exit 1; }
command -v termux-open >/dev/null || { echo "Error: termux-open is not installed. Please install it."; exit 1; }
command -v trans >/dev/null || { echo "Error: trans (translate-shell) is not installed. Please install it."; exit 1; }

# Check if directory argument is provided
VERBOSE=false

# Check if directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory> [--verbose]"
    exit 1
fi

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            # Assume the first non-flag argument is the directory
            if [ -z "$input_dir" ]; then
                input_dir="$arg"
            fi
            shift
            ;;
    esac
done

# Validate input directory after parsing arguments
if [ -z "$input_dir" ]; then
    echo "Error: No directory provided."
    echo "Usage: $0 <directory> [--verbose]"
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

    $VERBOSE && echo "Processing subfolders and folder: $1 ... " # Print the current directory

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
            existing_description=$(exiftool -Description -s "$image") || { echo "Error: exiftool failed to read description for $image. Continuing without existing description."; existing_description=""; }
            
            # If no description exists, generate one
            if [[ -z "$existing_description" ]]; then
                echo -e "Generating description for \033[34m$image\033[0m..."  # Filename in blue
                # Generate a description using llava-cli
                time description=$(llava-cli --log-disable -c 0 --color --threads 4 --temp 0.2 --image "$image" -m "$LLAVA_MODEL_PATH" --mmproj "$LLAVA_MMPROJ_PATH") || { echo "Error: llava-cli failed for $image. Skipping."; continue; }
                # Write the new description to the image's metadata
                exiftool -overwrite_original -Description="$description" "$image" || { echo "Error: exiftool failed to write description for $image. Skipping."; continue; }  
                echo -e "New description for \033[34m$image\033[0m is: \033[33m$description\033[0m"  # New description in yellow
                
                # Pronounce new description in background
                termux-open "$image" &>/dev/null || echo "Warning: Could not open $image for display."
                #termux-tts-speak "$description" &
                export description_pol= $(trans -b en:pl "$description") || { echo "Warning: Translation failed for \"$description\". Using original description."; export description_pol="$description"; }
                echo "$description_pol"
                termux-tts-speak -l pol "$description_pol" 

               
                
            else
                echo -e "File \033[34m$image\033[0m already had this description: \033[32m$existing_description\033[0m"  # Existing description in green
                export description_pol="$(trans -b en:pl "$existing_description")" || { echo "Warning: Translation failed for \"$existing_description\". Using original description."; export description_pol="$existing_description"; }
                echo $description_pol
                termux-tts-speak -l pol "$description_pol"
                
                #description_pol="$existing_description"
            fi

            # Use printf to encode filename directly within echo, so-called "percent encoding" for e.g. `don't ... ` filenames:
    safe_filename=$(printf '%s
' "$(basename "$image")" | sed 's/ /%20/g; s/:/%3A/g; s/&/%26/g; s/+/%2B/g; s/?/%3F/g; s/#/%23/g; s/'\''/%27/g')

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
        $VERBOSE && echo "HTML file created: $html_file. Attempting to convert to PDF..."

        # Change to the source directory as relative paths, for pandoc only
        cd "$(dirname "$html_file")" || { echo "Error: Failed to change directory to $(dirname "$html_file") for PDF conversion."; exit 1; }

        # Convert HTML to PDF using pandoc
        pdf_file="${html_file}.pdf"
        pandoc -i "$html_file" -o "$pdf_file" --pdf-engine=weasyprint

        # Check if PDF conversion was successful
        if [[ -f "$pdf_file" ]]; then
            echo "PDF file created: $pdf_file."
            
            # Open the PDF file in viewer 
            termux-open "$pdf_file" &>/dev/null || echo "Warning: Could not open $pdf_file for display."
        else
            echo "Error: Failed to create PDF file from $html_file using pandoc."
        fi
    else
        echo "Failed to create HTML file: $html_file."
    fi

    # Loop through each subdirectory
    for subdir in "$current_dir"/*/; do
        [ -d "$subdir" ] || continue  # Check if it's a directory
        traverse "$subdir"  # Recurse into subdirectory
    done
}

    # Call the function with the parent directory containing all subfolders
    traverse "$input_dir"

    # Return to the starting directory
    cd "$start_dir" || { echo "Error: Failed to return to starting directory"; exit 1; }

    $VERBOSE && echo "Finished recursion. Returned to starting directory: $start_dir"

