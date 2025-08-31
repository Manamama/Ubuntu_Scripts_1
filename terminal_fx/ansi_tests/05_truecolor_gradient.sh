#!/bin/bash
# Truecolor gradient test.
echo -e '\n\e[1;37mTRUECOLOR GRADIENT\e[0m'
for r in {255..0..-15}; do
  let g=255-r
  echo -ne "\e[48;2;${r};${g};0m "
  sleep 0.01
done
echo -e "\e[0m"
