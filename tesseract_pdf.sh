tesseract_pdf_to_txt () 
{ 
    date;
    SECONDS=0;
    echo You can use all the languages below or more:;
    tesseract --list-langs;
    echo "Use : -l LANG[+LANG] to specify";
    echo;
    local pdf_path="$1";
    local tmp_dir="$TMPDIR/pdf_to_images";
    local output_dir="$(dirname "$pdf_path")";
    local base_name_filename="$(basename "$pdf_path" .pdf)";
    echo "Output directory: $output_dir";
    echo PDF info:;
    file "$pdf_path";
    mkdir -p "$tmp_dir";
    pdftoppm -jpeg "$pdf_path" "$tmp_dir/page";
    local num_images=$(ls -1 "$tmp_dir"/*.jpg | wc -l);
    echo "Number of temp images created: $num_images";
    echo;
    for img_file in "$tmp_dir"/*.jpg;
    do
        local base_name="$(basename "$img_file")";
        echo Processing via tesseract: $img_file, with $2 $3 $4...;
        tesseract "$img_file" "$tmp_dir/$base_name" $2 $3 $4;
    done;
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
