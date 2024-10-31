
function easyocr_pdf_to_txt () 
{ 
#ver 1.2
    date;
    SECONDS=0;
    echo You can use all the languages below or more:;
    echo "Use : -l LANG[+LANG] to specify";
    echo;
    local pdf_path="$1";
    local tmp_dir="$TMPDIR/pdf_to_images_$(date +"%Y%m%d_%H%M%S")";
    local output_dir="$(dirname "$pdf_path")";
    local base_name_filename="$(basename "$pdf_path" .pdf)";
    echo "Output directory: $output_dir";
    echo PDF info:;
    file "$pdf_path";
    mkdir -p "$tmp_dir";
    
    # Convert PDF pages to JPEG images
    pdftoppm -jpeg "$pdf_path" "$tmp_dir/page";
    
    local num_images=$(ls -1 "$tmp_dir"/*.jpg | wc -l);
    echo "Number of temp images created: $num_images";
    echo;

    # Process each image with EasyOCR
    for img_file in "$tmp_dir"/*.jpg; do
        local base_name="$(basename "$img_file")";
        local output_txt_file="$tmp_dir/${base_name%.jpg}.txt"  # Define output text file name
        echo Processing via easyocr: $img_file, with $2 $3 $4...;

        # Run EasyOCR and redirect output to the specified text file
        easyocr --detail 0 --paragraph True -f "$img_file" > "$output_txt_file" $2 $3 $4;
        
        # Check if the output file was created successfully
        if [ -f "$output_txt_file" ]; then
            echo "Successfully created text file: $output_txt_file";
        else
            echo "Error creating text file for: $img_file";
        fi
    done;

    # Combine all text files into one final output file
    cat "$tmp_dir/"*.txt > "$output_dir/$base_name_filename.txt";
    
    echo;
    if [ -f "$output_dir/$base_name_filename.txt" ]; then
        echo "Time taken to join text files: $SECONDS seconds";
        echo;
        echo "Statistics - number of characters (wc -c) and filename:";
        wc -c "$output_dir/$base_name_filename.txt";
        echo -e "Tokens (ttok): \e[34m $(cat "$output_dir/$base_name_filename.txt" | ttok)\e[0m";
        echo;
    else
        echo "Error: Final output file $output_dir/$base_name_filename.txt not found.";
    fi;
    
    rm -r "$tmp_dir"
}

