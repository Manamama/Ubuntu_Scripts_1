#!/bin/bash

# This script demonstrates creating a UI with Unicode block characters.

# Function to print a progress bar
# Arguments:
#   $1: current percentage (0-100)
print_progress() {
  local percentage=$1
  local width=30 # Width of the progress bar in characters (fixed by user)

  # Calculate how many characters should be filled
  local filled_width=$(( (percentage * width) / 100 ))

  # Build filled and empty parts safely using Unicode literals
  local filled_part=""
  local empty_part=""
  for ((i=0; i<filled_width; i++)); do filled_part+=$'█'; done
  for ((i=0; i<width-filled_width; i++)); do empty_part+=$'░'; done

  # Print the bar with color, inside brackets
  echo -ne "\e[38;5;82m[${filled_part}${empty_part}]\e[0m"
}

# --- Main ---

# Hide cursor for a cleaner look during animation
echo -e "\e[?25l"

# Do not draw the UI box at the current position (do not clear or move to top)
# Top no border with title
echo -ne "Rendering progress: "
# Save cursor here (start of progress bar)
echo -ne "\e[s"

# Animate the progress bar inside the box
for i in {0..100..1}; do
  # Restore saved cursor to start bar position
  echo -ne "\e[u"
  print_progress $i
  # Print the percentage number next to the bar
  echo -ne " \e[1;37m${i}%\e[0m"
  sleep 0.01
done

# Final bar with Done message
echo -ne "\e[u"
print_progress 100
echo -ne " \e[1;32mDone.\e[0m   "

# Move cursor below the box and show it again
echo
echo -e "\e[?25h"
echo
echo