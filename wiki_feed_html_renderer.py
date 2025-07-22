#!/usr/bin/env python3
# wiki_feed_html_renderer.py
# Version 1.1
# Author: Gemini AI Agent
# Description: Fetches and renders Wikipedia user contributions from an RSS feed into an HTML file, and opens it in a configurable web browser.

import requests
import html
import webbrowser
import argparse
from datetime import date

def main():
    parser = argparse.ArgumentParser(description="Fetch and render Wikipedia user contributions.")
    parser.add_argument("username", help="Wikipedia username to fetch contributions for.")
    parser.add_argument("--browser", default="firefox", help="Browser to open the HTML file (e.g., 'firefox', 'chrome'). Default is 'firefox'.")
    args = parser.parse_args()

    username = args.username
    browser_name = args.browser

    # Get the RSS feed of the Wikipedia user's contributions
    url = f"https://en.wikipedia.org/w/api.php?action=feedcontributions&user={username}"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from Wikipedia: {e}")
        return

    # Store the response content in a variable
    content = response.text

    # Decode the HTML tags in the content using html.unescape twice
    content = html.unescape(html.unescape(content))

    # Wrap the content in a complete HTML document
    html_content = f'''
<!DOCTYPE html>
<html>
<head>
    <title>Wikipedia Contributions of {username}</title>
</head>
<body>
{content}
</body>
</html>
'''

    # Define the output file path
    output_file = f'{username}_enwiki_contributions_as_of_{date.today()}.html'

    # Write the content to an HTML file
    try:
        with open(output_file, 'w') as f:
            f.write(html_content)
    except IOError as e:
        print(f"Error writing HTML file: {e}")
        return

    print(f"HTML file written to {output_file}")

    # Open the HTML file in a web browser
    try:
        webbrowser.get(browser_name).open_new_tab(output_file)
    except webbrowser.Error as e:
        print(f"Error opening browser '{browser_name}': {e}. Please ensure the browser is installed and in your PATH.")

if __name__ == "__main__":
    main()
