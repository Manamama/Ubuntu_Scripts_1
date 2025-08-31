#!/usr/bin/env python3
# unhyphenate.py
# Version 1.3
# Author: Gemini AI Agent
# Description: Unhyphenates text from a file using the 'dehyphen' library, with configurable language.
# See: https://github.com/pd3f/dehyphen/issues/7 for why it is needed and what for. 

import sys
import os
import argparse
from dehyphen import FlairScorer, text_to_format

def flatten_list(nested_list):
    """Recursively flatten a nested list into a single list while preserving EOLs at the middle level."""
    flat_list = []

    # Outer loop for the first level
    for outer_item in nested_list:
        # Middle loop for the second level
        flat_list.append("\n")  # Add a single EOL for separation
        for middle_item in outer_item:                
            
            # Innermost loop for the third level
            for word in middle_item:
                flat_list.append(word)  # Append each word to the flat list

    return flat_list

def main(input_file, lang):
    # Initialize the scorer for the language
    scorer = FlairScorer(lang=lang)

    # Read the input file
    with open(input_file, 'r', encoding='utf-8') as file:
        source_text = file.read()

    # Format the input text
    special_format = text_to_format(source_text)

    # Remove hyphens from the text
    fixed_hyphens = scorer.dehyphen(special_format)
    # Flatten the nested list of characters into a single string
    if isinstance(fixed_hyphens, list):
        flat_output = flatten_list(fixed_hyphens)
        flattened_text = ' '.join(flat_output)
    else:
        flattened_text = fixed_hyphens

    # Create output file name based on input file name
    base_name = os.path.basename(input_file)
    output_file = os.path.join(os.path.dirname(input_file), f"{os.path.splitext(base_name)[0]}_unhyphenated.txt")

    # Write the fixed text to the output file
    with open(output_file, 'w', encoding='utf-8') as file:
        file.write(flattened_text)

    print(f"Unhyphenated text written to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Unhyphenate text from a file.")
    parser.add_argument("input_file", help="Path to the input text file.")
    parser.add_argument("--lang", default="pl", help="Language for dehyphenation (e.g., 'en', 'pl'). Default is 'pl'.")
    args = parser.parse_args()

    main(args.input_file, args.lang)

