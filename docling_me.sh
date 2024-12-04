#!/bin/bash

# Required Tools and Dependencies:
#
# This script requires the following tools to be installed on your system:
#
# 1. **Bash**: The script is written in Bash, so a compatible shell is required.
#
# 2. **ImageMagick**: Specifically, the `convert` command from ImageMagick is used to convert images to PDF format.
#    - Installation (Ubuntu/Debian): `sudo apt-get install imagemagick`
#
# 3. **ExifTool**: This tool is used to read metadata from the input file.
#    - Installation (Ubuntu/Debian): `sudo apt-get install exiftool`
#
# 4. **Docling**: This is the main tool used for processing PDFs and generating Markdown output.
#    - Ensure that Docling is installed and accessible in your PATH.
#
# 5. **ttok**: This command is used to tokenize the text output from the Markdown file. Ensure it is installed and available.
#    - Installation may vary; check the documentation for `ttok` for installation instructions.
#
# Note: Make sure all tools are properly configured and accessible in your system's PATH before running the script.



# Function to convert image to PDF and save in temp directory
convert_image_to_pdf() {
    local input_file="$1"
    local pdf_file="${TMPDIR:-/tmp}/${input_file##*/}.pdf"  # Create PDF filename from input in temp directory
    #Info: "We are creating temporary PDF file: ${pdf_file}"
    convert "$input_file" "$pdf_file" || { echo "Error converting image to PDF"; exit 1; }
    echo "$pdf_file"
    
}


# Function to print word count
print_word_count() {
    echo
    local in_file="$1"
    echo "Statistics:"

    # Count words and characters
    word_count=$(wc -w < "$in_file")  # Count words
    char_count=$(wc -c < "$in_file")  # Count characters

    # Count sentences using awk
sentence_count=$(awk 'BEGIN {RS="[.!?]"; count=0} {count+=NF} END {print count}' "$in_file")


    # Output the results
    echo "Words: $word_count"
    echo "Characters: $char_count"
    echo "Sentences: $sentence_count"
    
    echo "Tokens: $(ttok < "$md_file")"

    #echo
}


# Function to process PDF with docling
process_pdf_with_docling() {
    local pdf_file="$1"  # First argument is the PDF file
    shift                 # Shift to remove the PDF file from $@, leaving only additional arguments
    echo
    echo "Processing PDF: $pdf_file"
    echo "Using these additional arguments: $@"  # Log additional arguments for clarity
    echo

    # Call docling with the PDF file and any additional options
    docling -v --output "$output_dir" "$pdf_file" "$@" || { echo "Error processing PDF with docling"; exit 1; }
        
    echo
    echo "Head of the converted file:"
    echo
    head "$md_file"
    echo
    print_word_count "$md_file"
}


# Main script logic starts here

input_file="$1"


echo
echo "OCR via docling via PDF, ver. 2.1.4."
echo "Usage: '$0 <input-file> [options]' , it must be in that order."
echo "Use: '--ocr-lang xx'  to change the recognition language. Use 'docling --help' to learn more. "


if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' does not exist."
    exit 1
fi

echo
exiftool "$input_file" || { echo "Error running exiftool"; exit 1; }
# Construct the expected Markdown filename based on the original input file's name without leading slash
md_file="$(dirname "$input_file")/$(basename "${input_file%.*}").md"



#Does not make much sense, if PDF etc:
#print_word_count "$input_file"


# Set output_dir based on the original input file's path
output_dir="$(dirname "$input_file")"

# Determine if the input is an image or a PDF, and process accordingly

if [[ "$input_file" =~ \.(jpg|jpeg|png|gif)$ ]]; then
    echo "We need to convert source media to a PDF to overcome a docling language bug..."
    processed_file=$(convert_image_to_pdf "$input_file")  # Convert image to PDF in temp directory
else
    processed_file="$input_file"
fi

# Shift to remove $1 (the source file) from $@
shift  # This will allow us to pass only the additional arguments
#Or you can use: process_pdf_with_docling "$processed_file" "${@:2}"

# Call docling to process the PDF and generate Markdown output in the specified output directory
time process_pdf_with_docling "$processed_file" "$@"
