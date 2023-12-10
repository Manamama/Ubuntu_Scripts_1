import requests
import html
import webbrowser

# Get the RSS feed of the Wikipedia user's contributions
url = "https://en.wikipedia.org/w/api.php?action=feedcontributions&user=Piotrus"
response = requests.get(url)

# Store the response content in a variable
content = response.text

# Decode the HTML tags in the content using html.unescape twice
content = html.unescape(html.unescape(content))

# Wrap the content in a complete HTML document
html_content = f'''
<!DOCTYPE html>
<html>
<head>
    <title>Wikipedia Contributions of ...</title>
</head>
<body>
{content}
</body>
</html>
'''

# Define the output file path
output_file = 'output_final_for_chrome.html'

# Write the content to an HTML file
with open(output_file, 'w') as f:
    f.write(html_content)

# Open the HTML file in a web browser
webbrowser.get('firefox').open_new_tab(output_file)
