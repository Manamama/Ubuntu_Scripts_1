#!/bin/bash
# 256-color background test (animated).
echo -e '\n\e[1;37m256-COLOR BACKGROUND (animated)\e[0m'
for i in {0..255}; do
  echo -ne "\e[48;5;${i}m  \e[0m"
  (( i % 16 == 15 )) && echo
  sleep 0.005
done
