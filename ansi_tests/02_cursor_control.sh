#!/bin/bash
# Demonstrates cursor control.
echo -e '\n\e[1;37mCURSOR CONTROL (step by step)\e[0m'
echo -e 'Normal line'
sleep 1
echo -e '\e[sMoved line (cursor hidden)\e[?25l'
sleep 2
echo -e '\e[uBack at saved spot, cursor visible again\e[?25h'
sleep 2
echo -ne 'This will disappear in 2 sec...'
sleep 2
echo -e '\e[2K\rLine cleared!'
sleep 1
