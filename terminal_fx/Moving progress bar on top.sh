#!/bin/bash

# This script demonstrates creating a UI with Unicode box-drawing and block characters.

# Function to print a progress bar
# Arguments:
#   $1: current percentage (0-100)
print_progress() {
  local percentage=$1
  local width=40 # Width of the progress bar in characters
  local filled_width=$(( (percentage * width) / 100 ))
  local filled_part=""
  local empty_part=""
  
  # Create the filled part using a loop
  for ((i=1; i<=filled_width; i++)); do filled_part="${filled_part}\u2588"; done
  # Create the empty part using a loop
  for ((i=1; i<=$((width - filled_width)); i++)); do empty_part="${empty_part}\u2591"; done

  # Print the bar with color, inside brackets
  echo -ne "\033[38;5;82m[${filled_part}${empty_part}]\033[0m"
}

# --- Main ---

# Check for UTF-8 locale
if [[ ! $LC_ALL =~ UTF-8 && ! $LANG =~ UTF-8 ]]; then
  echo "Error: Terminal must support UTF-8. Set LC_ALL (e.g., export LC_ALL=en_US.UTF-8)."
  exit 1
fi

# Define UI dimensions
title="Advanced Unicode UI Demo"
title_length=${#title}
box_width=$((title_length + 34)) # Adjusted for padding + content
padding=$(( (box_width - title_length - 2) / 2 )) # Center the title
top_border=""
for ((i=1; i<=padding; i++)); do top_border="${top_border}\u2501"; done
top_border="${top_border}[${title}]${top_border}"
middle_line=$(printf "%${box_width}s" | tr ' ' ' ')
bottom_border=""
for ((i=1; i<=box_width; i++)); do bottom_border="${bottom_border}\u2501"; done

# Hide cursor
tput civis

# Clear screen to avoid overlap with prior output
tput clear

# Draw the UI box
echo -e "\033[1;36m\u250F${top_border}\u2513\033[0m"
echo -e "\033[1;36m\u2503${middle_line}\u2503\033[0m"
echo -e "\033[1;36m\u2503   \033[0;37mRendering progress:                                   \033[1;36m\u2503\033[0m"
echo -e "\033[1;36m\u2503${middle_line}\u2503\033[0m"
echo -e "\033[1;36m\u2517${bottom_border}\u251B\033[0m"

# Animate the progress bar
for i in {0..100..1}; do
  # Move cursor to line 4, column 7 (zero-based: line 3, col 6)
  tput cup 3 6
  print_progress $i
  # Print percentage with fixed width
  echo -ne " \033[1;37m$(printf "%3d%%" $i)\033[0m  "
  sleep 0.03
done

# Add "Done" message
tput cup 3 6
print_progress 100
echo -ne " \033[1;32mDone.\033[0m   "

# Move cursor below box and show cursor
tput cup 5 0
tput cnorm

echo "version 1.2, fixed alignment and positioning, retained original markers"