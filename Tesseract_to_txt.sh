

function tesseract_to_txt() {
    echo Ver. 2.2.3
    date
    SECONDS=0
    tesseract --list-langs
    echo "Use : -l LANG[+LANG] to specify that language"
    echo

    input_path="$1"
        args="$2 $3 $4 $5"  # Capture the language argument
    temp_dir=$(mktemp -d)  # Create a temporary directory for interim .txt files
    echo "Temporary directory created at: $temp_dir"

    # Subfunction to process a single image file
    process_single_image() {
        local img_path="$1"
         echo "Processing image: $img_path via tesseract to : $temp_dir/$(basename "$img_path").txt with arguments: $args ..."
        tesseract "$img_path" "$temp_dir/$(basename "$img_path")" $args
        #ll "$temp_dir/$(basename "$img_path").txt"
 

        # Check if the file size is greater than zero
        if [ -s "$temp_dir/$(basename "$img_path").txt" ]; then
            echo "Output filesize and filename: "
            wc -c "$temp_dir/$(basename "$img_path").txt"
            
        else
            echo "No output created for $img_path as the file size is zero."
        fi
    }

    # Check if the input is a directory or a file
    if [ -d "$input_path" ]; then
        echo "Input is a directory: $input_path"
        
        # Loop through all .jpg and .png files in the directory
        shopt -s nullglob  # Enable nullglob to avoid literal pattern matching
        for img_path in "$input_path"/*.{jpg,png}; do
            if [ -f "$img_path" ]; then  # Check if the file exists
                process_single_image "$img_path"
            else
                echo "No image files found in the directory."
            fi
        done

        # Merge all resulting .txt files into one final output file
        output_file="${input_path##*/}.txt"  # Get folder name for output filename
        cat "$temp_dir/"*.txt > "$input_path/$output_file"
        echo "Merged output saved to: $input_path/$output_file"
        echo "Number of tokens:" 
        cat "$input_path/$output_file" | ttok  | lolcat

    elif [ -f "$input_path" ]; then  # If it's a single file
        output_dir="$(dirname "$input_path")"
        echo "Image name: $input_path"
        echo "Output folder: $output_dir"

        process_single_image "$input_path"
        cp "$temp_dir/$(basename "$img_path").txt" output_dir

    else
        echo "Error: Input path is neither a file nor a directory."
    fi

    echo "Time taken to OCR these files:" 
    echo "$SECONDS seconds" | lolcat
}
