#!/bin/bash
# Demonstrate tertiary screen (nested alt).

echo -e '\e[?1049h'   # enter tertiary
clear
echo -e '\n\e[1;37mTERTIARY SCREEN\e[0m'
echo -e "You're now in a nested alt-buffer."
sleep 2
echo -e "Running another test here..."

# Run the 256-color background test again inside this screen
echo -e '\n\e[1;37m256-COLOR BACKGROUND (animated), in this screen ...\e[0m'
for i in {0..255}; do
  echo -ne "\e[48;5;${i}m  \e[0m"
  (( i % 16 == 15 )) && echo
  sleep 0.005
done
sleep 2

echo -e "Exiting tertiary screen in 2s..."
sleep 2
echo -e '\e[?1049l'   # exit tertiary -> back to secondary
