#!/bin/bash

# Required Tools and Dependencies:
#
# This script requires the following tools to be installed on your system:
#
# 1. **Bash**: The script is written in Bash, so a compatible shell is required.
#
# 2. **ExifTool**: This tool is used to read metadata from the input file.
#    - Installation (Ubuntu/Debian): `sudo apt-get install exiftool`
#
# 3. **Docling**: This is the main tool used for processing PDFs and JPGs and generating Markdown output. Make sure you have a docling version post 2.10.0` ! 
#
# 4. **ttok**: This command is used to tokenize the text output from the Markdown file. Ensure it is installed and available.
#    - Installation may vary; usually `pip install ttok`.
#
: '
Try:
from llama_index.core import SimpleDirectoryReader
from llama_index.readers.docling import DoclingReader

# Create an instance of DoclingReader
reader = DoclingReader()

# Set up SimpleDirectoryReader with the file extractor for PDFs
dir_reader = SimpleDirectoryReader(
    input_dir="...",  # Your specified folder
    file_extractor={".pdf": reader},  # Use DoclingReader for PDF extraction
)

But: 
 You can also use Docling directly from your command line to convert individual files —be it local or by URL— or whole directories.
 

# Load data and handle errors
try:
    docs = dir_reader.load_data()
    if docs:
        print(docs.metadata)  # Print metadata of the first document
    else:
        print("No documents were loaded.")
except Exception as e:
    print(f"Error loading data: {e}")
    
'




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
    
    echo "Tokens: $(ttok < "$md_file")"

    #echo
}


# Function to process PDF with docling
process_input_with_docling() {


   
    echo "Calling the docling program that way:" 
    # Print the exact command used
    
    echo -n -e "\033[94m"

    echo -n "$0"
    echo -n "   "
    echo -n  --output "$output_dir" --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode placeholder 
    for arg in "$@"; do
      if [[ "$arg" == *" "* ]]; then
        echo -n " \"$arg\" "
      else
        echo -n " $arg"
      fi
    done
    echo

    echo -e "\033[0m"  # Reset color to default
 
#echo "Received arguments: "$@" "
    # Print received arguments for debugging


    # Call docling with the PDF file and any additional options
    # See discussion: https://github.com/DS4SD/docling/discussions/245
    # Experiment with: --ocr
    # Define the command as a string

    docling --output "$output_dir" --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode placeholder "$@"
    echo
    echo "Head of the converted file:"
    echo -e "\033[94m"
    head "$md_file"
    echo -e "\033[0m"  # Reset color to default
    echo "Target document statistics:"
    print_word_count "$md_file"
    echo
    echo "It has taken us that much time to process all:"
}


# Main script logic starts here

input_file="$1"


echo
echo "OCR via docling via PDF, version 2.3.3, author ManamaMa"
echo "Usage: '$0 <input-file> | <input-folder> | <input-URL> [options]'."
echo "Most useful options:"
echo "  --ocr                    Process also the bitmap content using OCR."
echo "  --no-ocr                 Skip OCR processing for faster performance."
echo "  --ocr-lang <lang-code>   Specify recognition languages (a two-letter code for EasyOCR, but see https://www.jaided.ai/easyocr/ for more; or a three-letter code for Tesseract)."
echo "  --table-mode	         choice (fast | accurate)."
echo "  --image-export-mode      choice (placeholder | embedded | referenced). With placeholder, only the position of the image is marked in the output. In the embedded mode, the image is embedded as base64 encoded string. In referenced mode, the image is exported in PNG format and referenced from the main exported document."
echo "The default added options are: '--output {the folder of the source file} --pdf-backend dlparse_v2 --table-mode accurate --image-export-mode placeholder '.  Use 'docling --help' or visit: https://ds4sd.github.io/docling/cli/ to learn more. "


if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' does not exist."
    exit 1
fi

echo
echo "Source document statistics:"


exiftool "$input_file" || { echo "Error running exiftool"; exit 1; }

echo -e "\033[0m"  # Reset color to default
    
 
echo
# Construct the expected Markdown filename based on the original input file's name without leading slash
md_file="$(dirname "$input_file")/$(basename "${input_file%.*}").md"



#Does not make much sense, if PDF etc:
#print_word_count "$input_file"


# Set output_dir based on the original input file's path
output_dir="$(dirname "$input_file")"



# Call docling to process the PDF and generate Markdown output in the specified output directory
time process_input_with_docling "$@"

open "$md_file"
