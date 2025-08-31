#!/bin/bash
# Truecolor rainbow bar test.
echo -e '\n\e[1;37mTRUECOLOR RAINBOW\e[0m'
for g in {0..255..5}; do
  let r=255-g
  let b=g/2
  echo -ne "\e[48;2;${r};${g};${b}m "
  sleep 0.01
done
echo -e "\e[0m"
