#!/bin/bash
# docling_processor.sh
# Version 2.5.5
# Author: Gemini AI Agent
# Description: Processes PDFs, images, and URLs using Docling for OCR and Markdown conversion, with optional sound alerts and colored output.

source "$(dirname "$0")"/config.sh

# --- Dependency Checks ---
command -v exiftool >/dev/null || { echo "Error: exiftool is not installed. Please install it."; exit 1; }
command -v pdfcpu >/dev/null || { echo "Error: pdfcpu is not installed. Please install it."; exit 1; }
command -v qpdf >/dev/null || { echo "Error: qpdf is not installed. Please install it."; exit 1; }
command -v docling >/dev/null || { echo "Error: docling is not installed. Please install it."; exit 1; }
command -v ttok >/dev/null || { echo "Error: ttok is not installed. Please install it."; exit 1; }
command -v play >/dev/null || { echo "Error: play (sox) is not installed. Please install it."; exit 1; }
command -v lolcat >/dev/null || { echo "Error: lolcat is not installed. Please install it."; exit 1; }
command -v xdg-open >/dev/null || { echo "Error: xdg-open is not installed. Please install it."; exit 1; }

# Function to print word count
print_word_count() {
    #echo
    local in_file="$1"
    #echo ""
    
   
 
    # Count words and characters
    word_count=$(wc -w < "$in_file")  # Count words
    char_count=$(wc -c < "$in_file")  # Count characters

    # Count sentences using awk
    sentence_count=$(awk 'BEGIN {RS="[.!?]"; count=0} {count+=NF} END {print count}' "$in_file")

    # Output the results
    echo "Words: $word_count"
    echo "Characters: $char_count"
    echo "Sentences: $sentence_count"
    echo "Tokens: $(ttok < "$in_file" | lolcat) || echo "Warning: ttok failed to count tokens or lolcat failed.""
}

# Function to process PDF with docling
process_input_with_docling() {

# Print received arguments for debugging
#echo "Received arguments: "$@" "

   
    echo "Calling the docling program that way:" 
    # Print the exact command used
    
    echo -n -e "\033[94m"

    #echo -n "$0"
    echo -n "docling"
    echo -n " "
    echo -n "--output \"$output_dir\" -v --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode referenced  --artifacts-path=~/.cache/docling/models --enrich-picture-classes --num-threads 1000 "
    # --image-export-mode referenced
 
    for arg in "$@"; do
      if [[ "$arg" == *" "* ]]; then
        echo -n " \"$arg\" "
      else
        echo -n " $arg"
      fi
    done
    echo

    echo -e "\033[0m"  # Reset color to default


    # Call docling with the PDF file and any additional options
    # See discussion: https://github.com/DS4SD/docling/discussions/245
    # Experiment with: --ocr
    # Define the command as a string




    docling --output "$output_dir" -v --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode referenced --artifacts-path=~/.cache/docling/models --enrich-picture-classes --num-threads 1000  "$@"
    
    if [[ -f "$input_path" ]]; then
        echo
        echo "Head of the converted file:" "$md_file"
        echo -e "\033[94m"
        head "$md_file"
        echo -e "\033[0m"  # Reset color to default
        echo "Target document statistics:"
        print_word_count "$md_file"

    fi

    echo
    echo "It has taken us that much time to process all:"
}
 


# Main script logic starts here 

# Print received arguments for debugging
#echo "Received arguments: "$@" "

all_args=("$@")  # Store all original arguments as array, but do not use it! It somehow gets mangled then, not passed. 

#Global variable
input_path="$1"


echo 
echo "OCR via docling, streamlined, n 2.5.4 | author ManamaMa"
echo -e "Usage: \033[94m$(basename $0) <input-file> | <input-folder> | <input-URL> [options] \033[0m"
echo "Most useful options:"
echo "  --no-ocr                 
Skip OCR processing of bitmaps for faster performance."
echo "  --ocr-engine (easyocr|tesseract| ...) 
The OCR engine to use. Tesseract is much faster and sometimes more precise. Make sure you have these engines and Tesseract's OCR models installed in the OS, via 'pip install', 'apt install'."
echo "  --ocr-lang <lang-code>   
Specify recognition languages (a two-letter code for EasyOCR, but see https://www.jaided.ai/easyocr/ for more; or mostly three-letter codes for Tesseract, use 'tesseract --list-langs' to see them). If you do not specify the right codes, you may see cryptic errors: 'RuntimeError: Failed to init API, possibly an invalid tessdata path'"
echo "  --table-mode (fast | accurate)"
echo "  --image-export-mode (placeholder | embedded | referenced) 
With 'placeholder', only the position of the image is marked in the output, but it is then incompatible with "--enrich-picture-classes". In the embedded mode, the image is embedded as base64 encoded string. In 'referenced' mode, the image is exported in PNG format and referenced from the main exported document."
echo "  --num-threads                 
How many CPU threads it shall use (the more the faster performance), we are using all, just in case - you can lower these."
echo "The added options are: '--output {the folder of the source file} --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode referenced  --num-threads 1000 '. "
# --image-export-mode placeholder clashes with --enrich-picture-classes
echo "Use 'docling --help' or visit: https://ds4sd.github.io/docling/cli/ and https://docling-project.github.io/docling/usage/enrichments/#picture-description to learn more. "
echo
echo "Tip: if djvu files, use this to convert these to TIFFs first: 'for file in *.djvu; do ddjvu -format=tiff "$file" "${file%.djvu}.tiff"; done' "

: '
if [[ ! -f "$input_path" ]]; then
    echo -e "\033[96mError: Input file '$input_path' does not exist.\033[0m"
    exit 1
fi
'



# Check if input file is provided
if [[ -z "$input_path" ]]; then
    echo "Please provide an input file or folder."
    exit 1
fi



# timestamp:
echo -n -e "\033[94m" # Blue
date
echo -n -e "\033[00m" # Reguar


echo "Starting the work ..."
echo



# Check if it is a file
if [[ -f "$input_path" ]]; then
    echo -e "The first argument: \033[94m$input_path\033[00m is a \033[96mregular file\033[0m."

    echo
    echo "Source document statistics:"

        
    echo -n -e "\033[94m"

    exiftool "$input_path" || { echo "\033[96mError running exiftool for $input_path. Exiting.\033[0m"; exit 1; }
    
     echo -e "\033[0m"  # Reset color to default
   
    # Determine the extension of the input file
    extension="${input_path##*.}"

    # Check if the extension is valid (not empty)
    if [[ "$extension" == "$input_path" ]]; then
        echo -e "\033[96mWarning: The input file has no extension.\033[0m"
        exit
    fi
    if [[ "$extension" == "pdf" ]]; then


        # Check for PDF corruption using pdfcpu
        echo -n -e "\033[0m"
        pdfcpu info "$input_path" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
        output_path=$input_path"_fixed.pdf"
            echo "Error: PDF corruption detected in $input_path. Attempting to fix via qpdf..."
            echo -n -e "\033[94m" # Blue
            echo "qpdf --empty --normalize-content=y --recompress-flate --compress-streams=y --object-streams=generate --decode-level=all --pages \"$input_path\" 1-z -- \"$output_path\""
            echo -n -e "\033[0m" # Normal

            # Run qpdf to fix the PDF
            qpdf --empty --normalize-content=y --recompress-flate --compress-streams=y --object-streams=generate --decode-level=all --pages "$input_path" 1-z -- "$output_path" || { echo "Error: qpdf failed to fix PDF for $input_path. Exiting."; exit 1; }
            
            # Update input path to the new cleaned file
            input_path="$output_path"
        fi

        # Display info from the repaired or original PDF
        echo "Info from the 'pdfcpu' tool:"
        echo -n -e "\033[94m" # Blue
        pdfcpu info "$input_path"
        echo -n -e "\033[0m"

    fi


    # Set output_dir based on the original input file's path
    output_dir="$(dirname "$input_path")"



    : '
    # We can try that one: 
    # For images only, not PDFs, resize them:
    echo "Original : $original_height"
    if [ "$original_height" -gt 2500 ]; then
        output_file="${input_path%.*}_resized.${extension}"
    echo Dimensions too large, especially for tesseract. If it fails, use: 
       echo -n -e "\033[94m"

    echo convert "$input_path" -resize x2500 -colorspace Gray "$output_path"
       echo -n -e "\033[0m"
       echo "Or:"
          echo -n -e "\033[94m"
    echo unpaper "$input_path" "$output_path" 

       echo -n -e "\033[0m"
    See: https://github.com/unpaper/unpaper/blob/main/doc/basic-concepts.md , etc. 

    #Mess here for now:
        # convert -resize x1500 -colorspace Gray -density 600  ...    
        convert ...  -colorspace Gray -define png:compression-level=0  
        
        
    fi
    '

    : '
    #n of resizing:
    # Check if the original height is greater than 2500 pixels
    if [ "$original_height" -gt 2500 ]; then
        # Create the output filename by appending "resized" before the extension
        output_file="${input_path%.*}_resized.${extension}"

        # Resize the image to a height of 2500 pixels, convert to grayscale, and maintain density
        convert "$input_path" -resize x2500 -colorspace Gray "$output_path"

        echo "Resized image '-resize x2500 -colorspace Gray ' saved as: $output_path"
        
        # Update input_path to point to the resized image
        input_path="$output_path"
    else
        echo "Original height is not greater than 2500 pixels. No resizing performed."
    fi

    #input_path = $output_path 
    exiftool "$input_path" || { echo "Error running exiftool"; exit 1; }
    '


    echo
    # Construct the expected resulting Markdown filename based on the original input filename without the leading slash
    md_file="$(dirname "$input_path")/$(basename "${input_path%.*}").md"


    # Call docling to process the PDF and generate Markdown output in the specified output directory
    time process_input_with_docling "$@" || { echo "Error: docling failed to process $input_path. Exiting."; exit 1; }

    md_file_fixed="$(dirname "$input_path")/$(basename "${input_path%.*}")_Unicode_characters_fixed.md"
    
    echo -e "We are fixing the potential wrong Unicode escape sequences that have been left over by the OCR engine, via sed and printf, including fixing the string: '\c' to '\*' (another glitch in itself) and saving the result to: \033[94m$md_file_fixed\033[0m "
    #  to: '$md_file_fixed'
    #stops at the first '\c' string alas:

    echo -n -e "\033[94m" # Blue
    
    #echo    "printf '%b\n' "$(sed 's/\/uni/\\u/g'  "$md_file")" > "$md_file_fixed"
    echo -n -e "\033[0m" # Normal
    
    #We change: `\c` to `*c` and then `/uni` to `\u` and print it out to a file
    printf '%b\n' "$(sed 's/\\c/*c/g'  "$md_file" | sed 's/\/uni/\\u/g' )" > "$md_file_fixed" || { echo "Error: Failed to fix Unicode characters for $md_file. Exiting."; exit 1; } 
    
    #printf '%b\n' "$(sed 's/\/uni/\\u/g'  "$md_file")" > "$md_file_fixed" 
    
   #Or : 
    #printf '%b' $(cat "$md_file") > "$md_file_fixed"

    #open "$md_file"
    echo 
    echo -e "Finished. Opening the resulting .md file: \033[94m$md_file\033[00m" 

        #Create an alias for 'open' only if not set yet: 
    if ! type open > /dev/null 2>&1; then
        alias open='xdg-open'
    fi

    
    open "$md_file" &>/dev/null || echo "Warning: Could not open $md_file for display."
    #xdg-open "$md_file"  
    #Or, opening the fixed n:
    #xdg-open "$md_file_fixed"

    echo
    echo
    echo


# Check if it is a directory
elif [[ -d "$input_path" ]]; then
    output_dir="$input_path"/docling_OCR_results   

    echo -e "The first argument: \033[94m$input_path\033[0m is \033[96ma directory\033[0m. We are creating a subfolder in it: \033[96m$output_dir\033[00m to store the results."
    
    mkdir -p  "$output_dir" || { echo "Error: Failed to create directory $output_dir. Exiting."; exit 1; }
    
    # Count the number of files in the directory
    file_count=$(find "$input_path" -type f -print | wc -l)
    echo -e "We have this number of files: \033[94m${file_count}\033[0m in this folder. We shall process the image ones only from there." 

    # Call docling to process the PDF and generate Markdown output in the specified output directory
    time process_input_with_docling "$@"
    md_file="$input_path/docling_OCR_results_merged.txt"
    cat "$output_dir"/*.md >> "$md_file" || { echo "Error: Failed to merge markdown files into $md_file. Exiting."; exit 1; }
    echo -e "Finished. The resulting folder: \033[94m$output_dir\033[00m, and the collated file: \033[94m$md_file\033[00m " 
    echo -e "Opening: $md_file ..."

    open "$md_file" &>/dev/null || echo "Warning: Could not open $md_file for display."
    
else
    echo  -e "The first argument: \033[96m$input_path does not exist or is neither a file nor a directory, it may be an URL.\033[0m We are passing it on to docling as is... \033[0m"
    
# Call docling to process the PDF and generate Markdown output in the specified output directory
time process_input_with_docling "$@" || { echo "Error: docling failed to process $input_path. Exiting."; exit 1; }

fi

#echo "Tips: you may need to use below with some recalcitrant non-standard Unicode escape sequences left in the files: "
#echo "printf '%b' $(cat "$md_file") "


#Remove the soft hyphen and space:
# sed -i 's/\/uni00AD //g' $md_file
#Remove the soft hyphen and multiple spaces, maybe repeatedly:
# sed -i ':a;N;$!ba;s/\/uni00AD\n\n//g' $md_file
#The four hexagonal coding characters found after the string: '/uni' changed to the Unicode '\u' format that is used in Python, Java, 'cat -e' etc: 
# sed -e 's/\/uni \([0-9a-f]\{4\}\)/\\u\1/g' $md_file "

play "$SOUND_ALERT_PATH" || true # Play sound alert, ignore if 'play' not found

# timestamp:
echo -n -e "\033[94m" # Blue
date
echo -n -e "\033[94m" # Blue


echo
 
echo  

echo -e "\033[0m"  # Reset color to default
    
 
