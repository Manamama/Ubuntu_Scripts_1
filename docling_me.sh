#!/bin/bash



# Function to convert image to PDF and save in temp directory
convert_image_to_pdf() {
    local input_file="$1"
    local pdf_file="${TMPDIR:-/tmp}/${input_file##*/}.pdf"  # Create PDF filename from input in temp directory
    #Info: "We are creating temporary PDF file: ${pdf_file}"
    convert "$input_file" "$pdf_file"
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
    
    echo "Tokens:  $(cat "$md_file" | ttok)"
    echo
}


# Function to process PDF with docling
process_pdf_with_docling() {
    local pdf_file="$1"  # First argument is the PDF file
    shift                 # Shift to remove the PDF file from $@, leaving only additional arguments
    echo
    echo "Processing PDF: $pdf_file"
    echo "Using these additional arguments: $@"  # Log additional arguments for clarity

    # Call docling with the PDF file and any additional options
    docling -v --output "$output_dir" "$pdf_file" "$@"
        
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
echo "OCR via docling via PDF, ver. 2.1.3."
echo "Usage: '$0 <input-file> [options]' , it must be in that order."
echo "Use: '--ocr-lang xx'  to change the recognition language. Use 'docling --help' to learn more. "

echo
exiftool "$input_file"
# Construct the expected Markdown filename based on the original input file's name without leading slash
md_file="$(dirname "$input_file")/$(basename "${input_file%.*}").md"


# Check if input file is provided
if [[ -z "$input_file" ]]; then

    exit 1
fi

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
