#!/bin/bash
echo "Displays an animated ASCII unicorn that runs and bounces. Ver. 1.3"

# Hide cursor for a clean animation
echo -e "\e[?25l"
# Clear the screen
echo -e "\e[2J"

# Starting vertical position
row=5

# Animation loop - from column 1 to 40 (user's change)
for ((col=1; col<=55; col++)); do
  # --- Update vertical position ---
  let "v_change = RANDOM % 3 - 1" # -1, 0, or 1
  let "row += v_change"

  # --- Boundary checks to keep it on screen ---
  # Top boundary (1 is the highest row)
  if (( row < 1 )); then row=1; fi
  # Bottom boundary (unicorn is 10 lines tall, so 15 keeps it from scrolling)
  if (( row > 15 )); then row=15; fi

  # Move cursor to the top left to redraw
  echo -ne "\e[H"
  # Clear the screen again for the new frame
  echo -e "\e[2J"

  # Alternate sparkle color for the horn tip
  if (( col % 2 == 0 )); then
    sparkle_color="\e[38;5;226m" # Yellow
  else
    sparkle_color="\e[38;5;231m" # White
  fi

  # --- Draw Unicorn at current position (row, col) ---
  # Each line is positioned relative to the current 'row'
  
  # Horn
  echo -ne "\e[${row};${col}H${sparkle_color}         ,"
  echo -ne "\e[$((row+1));${col}H\e[38;5;220m        /," 
  echo -ne "\e[$((row+2));${col}H\e[38;5;46m       //," 
  echo -ne "\e[$((row+3));${col}H\e[38;5;21m      ///"

  # Body
  echo -ne "\e[$((row+4));${col}H\e[37m           >\\/7"
  echo -ne "\e[$((row+5));${col}H\e[37m       _.-(o'  )"
  echo -ne "\e[$((row+6));${col}H\e[37m      /  / ,--'"
  echo -ne "\e[$((row+7));${col}H\e[37m     |  |  /"
  echo -ne "\e[$((row+8));${col}H\e[37m     '  '-'"
  echo -ne "\e[$((row+9));${col}H\e[37m      \
----'"

  # Control animation speed (user's change)
  sleep 0.05
done

# Show cursor again at the end
echo -e "\e[?25h"
# Reset colors
echo -e "\e[0m"
