#!/bin/bash
# Matrix-style falling characters demo.
echo -e '\n\e[1;37mMATRIX EFFECT (short demo)\e[0m'
# Assume dimensions as they can\'t be detected in all environments securely.
LINES=24
COLS=80
chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
for ((i=0; i<300; i++)); do
  let row=RANDOM%LINES
  let col=RANDOM%COLS
  let rand_idx=RANDOM%${#chars}
  char=${chars:$rand_idx:1}
  echo -ne "\e[${row};${col}H\e[38;2;0;255;0m${char}\e[0m"
  sleep 0.01
done
