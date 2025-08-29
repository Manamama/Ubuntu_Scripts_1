#!/bin/bash
# 256-color foreground test.
echo -e '\n\e[1;37m256-COLOR FOREGROUND TEST\e[0m'
for i in {0..255}; do
  echo -ne "\e[38;5;${i}m${i}\t"
  (( i % 8 == 7 )) && echo -e "\e[0m"
done
