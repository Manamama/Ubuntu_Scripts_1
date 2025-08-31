#!/bin/bash

# This script demonstrates creating a UI with Unicode box-drawing and block characters.

# Function to print a progress bar
# Arguments:
#   $1: current percentage (0-100)
print_progress() {
  local percentage=$1
  local width=40 # Width of the progress bar in characters
  
  # Calculate how many characters should be filled
  local filled_width=$(( (percentage * width) / 100 ))
  
  # Create the filled part of the bar using a full block character
  local filled_part=$(printf "%${filled_width}s" | tr ' ' '\u2588')
  
  # Create the empty part of the bar using a light shade character
  local empty_part=$(printf "%$((width - filled_width))s" | tr ' ' '\u2591')

  # Print the bar with color, inside brackets
  echo -ne "\e[38;5;82m[${filled_part}${empty_part}]\e[0m"
}

# --- Main ---

# Hide cursor for a cleaner look during animation
echo -e "\e[?25l"

# Clear the screen and move cursor to home position
echo -e "\e[2J\e[H"

# Draw the UI box using Unicode box-drawing characters and colors
# Top border with title
echo -e "\e[1;36m\u250F\u2501\u2501[ Advanced Unicode UI Demo ]\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2513\e[0m"
# Middle content area
echo -e "\e[1;36m\u2503                                                            \u2503\e[0m"
echo -e "\e[1;36m\u2503   \e[0;37mRendering progress:                                   \e[1;36m\u2503\e[0m"
echo -e "\e[1;36m\u2503                                                            \u2503\e[0m"
# Bottom border
echo -e "\e[1;36m\u2517\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u251B\e[0m"

# Animate the progress bar inside the box
for i in {0..100..1}; do
  # Move cursor to the position for the progress bar (line 4, column 7)
  echo -ne "\e[4;7H"
  print_progress $i
  # Print the percentage number next to the bar
  echo -ne " \e[1;37m${i}%\e[0m"
  sleep 0.03
done

# Add a "Done." message
echo -ne "\e[4;7H"
print_progress 100
echo -ne " \e[1;32mDone.\e[0m   " # Add some spaces to overwrite the percentage

# Move cursor below the box and show it again
echo -e "\e[6;1H"
echo -e "\e[?25h"
