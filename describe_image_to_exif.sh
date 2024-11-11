describe1_MobileVLM-3B-Q4_K_M() {
#ver. 2.2
    local image="$1"
    local description

    # Check if the image already has a Description
    local existing_description=$(exiftool -Description -s -s -s "$image")

    if [[ -n "$existing_description" ]]; then
        echo "File has Description: $existing_description"
    else
        time description=$(llava-cli --log-disable -c 0 --color --threads 4 --temp 0.2 --image "$image" -m /storage/emulated/0/LLMs/MobileVLM-3B-Q4_K_M.gguf --mmproj /storage/emulated/0/LLMs/MobileVLM-3B-mmproj-f16.gguf)
        
        # Write the description to the JPEG's comment
        exiftool -Description="$description" "$image"
        
        echo "New Description added. Checking it:"

    exiftool -Description "$image"
    fi

    termux-vibrate
}
