#!/bin/bash
# This script describes an image using llama-mtmd-cli and MobileVLM-3B, then embeds the description in the image's EXIF metadata. 

# Check if an image file is provided
if [ -z "$1" ]; then
    echo "Error: No image file provided. Usage: $0 <image_path>"
    exit 1
fi
image="$1"

# Model paths and configuration
location="/media/zezen/HP_P7_Data/Temp/AI_models"
model_name="MobileVLM-3B-Q5_K_M"
llm_model_path="$location/MobileVLM-3B-Q5_K_M.gguf"
mmproj_model_path="$location/MobileVLM-3B-mmproj-f16.gguf"
command="llama-mtmd-cli --chat-template deepseek --temp 0.1 "

# Verify model files exist
if [ ! -f "$llm_model_path" ] || [ ! -f "$mmproj_model_path" ]; then
    echo "Error: Model file ($llm_model_path) or mmproj file ($mmproj_model_path) not found."
    exit 1
fi

# Verify image file exists
if [ ! -f "$image" ]; then
    echo "Error: Image file ($image) not found."
    exit 1
fi

echo "Describe image with a VLM, version 2.9.1"

# Display mmproj file info
file "$mmproj_model_path"

# Check if the image already has a Description
existing_description=$(exiftool -Description -s -s -s "$image")
if [ -n "$existing_description" ]; then
    echo "File has Description: $existing_description"
    echo "Use: 'exiftool -Description= -EnhanceParams= "$image" ' to clear it up."
    exit 0
fi

echo "The original file has no description. Working on creating it..."

# Debug: Print the command
echo "$command -m $llm_model_path --mmproj $mmproj_model_path --image \"$image\" -p \"Describe this image in detail\""

# Run llama-mtmd-cli and extract description
time description=$($command  -m "$llm_model_path" --mmproj "$mmproj_model_path" --image "$image" -p "Describe this image in exhaustive detail" 2>/dev/null  | awk 'BEGIN{RS=""} /image decoded \(batch 1\/1\)/{getline; print; exit}')

# Check if description was generated
if [ -z "$description" ]; then
    echo "Error: Failed to generate description."
    echo "Debug: Raw output from llama-mtmd-cli:"
    $command --threads 10 --temp 0.1 -m "$llm_model_path" --mmproj "$mmproj_model_path" --image "$image" -p "Describe this image in exhaustive detail"
    exit 1
fi
: '
echo -n "Description: "
echo "$description" | lolcat

echo "Stopped working on it ..."
'

# Write description and model name to EXIF metadata
exiftool -Description="$description" -EnhanceParams="$model_name" "$image" -overwrite_original


echo "New Description added. Checking it:"
exiftool -Description -EnhanceParams "$image" | lolcat
