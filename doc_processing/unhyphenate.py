#!/usr/bin/env python3
# unhyphenate.py
# Version 2.0
# Author: Gemini AI Agent
# Description: Unhyphenates text from a file using the 'dehyphen' library, with configurable language.
# See: https://github.com/pd3f/dehyphen/issues/7 for why it is needed and what for. 

import sys
import os
import argparse
from typing import List
from dehyphen import FlairScorer, text_to_format

def main(input_file: str, lang: str) -> None:
    """
    Unhyphenates text from a given file and saves it to a new file.

    Args:
        input_file (str): The path to the input text file.
        lang (str): The language code for dehyphenation (e.g., 'en', 'pl').
    """
    # Initialize the scorer for the language
    scorer = FlairScorer(lang=lang)

    # Read the input file
    with open(input_file, 'r', encoding='utf-8') as file:
        source_text = file.read()

    # Format the input text
    special_format = text_to_format(source_text)

    # Remove hyphens from the text
    fixed_hyphens = scorer.dehyphen(special_format)

    # Reconstruct the text from the nested list structure
    if isinstance(fixed_hyphens, list):
        # The output is a list of paragraphs, where each paragraph is a list of sentences,
        # and each sentence is a list of words.
        paragraphs = []
        for paragraph in fixed_hyphens:
            sentences = [' '.join(sentence) for sentence in paragraph]
            paragraphs.append(' '.join(sentences))
        flattened_text = '\n\n'.join(paragraphs)
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