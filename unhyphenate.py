#Ver 1.1

import sys
from dehyphen import FlairScorer, text_to_format
import os

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

def main(input_file):
    # Initialize the scorer for the language - select the right one
    scorer = FlairScorer(lang="pl")

    # Read the input file
    with open(input_file, 'r', encoding='utf-8') as file:
        source_text = file.read()

    # Format the input text
    special_format = text_to_format(source_text)

    # Remove hyphens from the text
    fixed_hyphens = scorer.dehyphen(special_format)
    #print(fixed_hyphens)
    # Flatten the nested list of characters into a single string
    if isinstance(fixed_hyphens, list):
        # Use the flattening function to get a flat list of strings
        flat_output = flatten_list(fixed_hyphens)
        flattened_text = ' '.join(flat_output)  # Join all flattened elements into a single string
    else:
        flattened_text = fixed_hyphens  # In case it's already a string

    # Create output file name based on input file name
    base_name = os.path.basename(input_file)
    output_file = os.path.join(os.path.dirname(input_file), f"{os.path.splitext(base_name)[0]}_unhyphenated.txt")

    # Write the fixed text to the output file
    with open(output_file, 'w', encoding='utf-8') as file:
        file.write(flattened_text)

    print(f"Unhyphenated text written to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python unhyphenate.py <path_to_input_file>")
        sys.exit(1)

    input_file_path = sys.argv[1]
    main(input_file_path)
