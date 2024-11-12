#!/bin/bash

# Check if directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

DIR="$1"
BASENAME=$(basename "$DIR")
OUTPUT="$DIR/${BASENAME}_gallery.html"
echo "Gallery creation from images in folder, version 2.2. About to save these to: $OUTPUT"
# Start HTML content
HTML_CONTENT="<html lang='en'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>Image Gallery</title>
<style>
body { display: flex; flex-wrap: wrap; }
.container { display: flex; width: 100%; }
.thumbnail { width: 250px; height: 250px; margin: 10px; }
.thumbnail img { width: 100%; height: auto; }
.description { font-size: 1.5em; padding-top: 10px; }
</style>
</head>
<body>"

#overflow: hidden

# Initialize timer
SECONDS=0

# Iterate over all image files in the directory
shopt -s nullglob
for image in "$DIR"/*.{jpg,jpeg,png,gif}; do
    if [ -e "$image" ]; then
        # Extract existing description using ExifTool
        existing_description=$(exiftool -Description -s -s -s "$image")
        
        # If no description exists, generate one using llava-cli
        if [[ -z "$existing_description" ]]; then
            echo "Generating description for $image..."
            description=$(llava-cli --log-disable -c 0 --color --threads 4 --temp 0.2 --image "$image" -m /mnt/HP_P7_Data/Temp/GPT4All_DBs/MobileVLM-3B-Q5_K_M.gguf --mmproj /mnt/HP_P7_Data/Temp/GPT4All_DBs/MobileVLM-3B-mmproj-f16.gguf)
            # Write the new description to the image's metadata
            exiftool -Description="$description" "$image"
            echo "Checking if file $image had this added as Description (should not be empty): $(exiftool -Description -s -s -s "$image")"
            
        else
            description="$existing_description"
            echo "File $image has this existing Description: $description"
        fi
        
        filename=$(basename "$image")
        
        # Append thumbnail and description to HTML content
        HTML_CONTENT+="<div class='container'>
<div class='thumbnail'><img src='$image' alt='$filename'></div>
<div class='description'><strong>$filename</strong><br>$description</div>
</div>"
    fi
done

# End HTML content and write to output file
HTML_CONTENT+="</body></html>"
echo "$HTML_CONTENT" > "$OUTPUT"

# Print execution time
echo "Gallery created: $OUTPUT"
echo "Processing took $SECONDS seconds."
open "$OUTPUT"
