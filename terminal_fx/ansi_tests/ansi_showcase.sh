#!/usr/bin/env bash
# ===========================================
# ANSI Terminal Showcase for Termux / Bash
# Demonstrates:
#   - Text attributes
#   - Cursor tricks
#   - 256-color palette
#   - Truecolor gradients
#   - Animated rainbow & matrix effect
#   - Secondary/Tertiary screen buffers
# ===========================================

RESET="\e[0m"

# Helper: pause with prompt
pause() {
  echo -e "\n${RESET}\e[2m[Press Enter to continue]${RESET}"
  read -r
}

# ------------------------------------------------
# 0. Enter secondary screen buffer (like htop)
# ------------------------------------------------
echo -e "\e[?1049h"    # switch to alternate buffer
clear

# ------------------------------------------------
# 1. TEXT ATTRIBUTES
# ------------------------------------------------
echo -e "\n\e[1;37mTEXT ATTRIBUTES\e[0m"
echo -e "\e[1mBold Text${RESET}"
echo -e "\e[2mDim Text${RESET}"
echo -e "\e[3mItalic Text${RESET}"
echo -e "\e[4mUnderlined Text${RESET}"
echo -e "\e[7mInverse Colors${RESET}"
echo -e "\e[9mStrikethrough${RESET}"
echo -e "\e[8mInvisible (look closely!)${RESET}"
pause

# ------------------------------------------------
# 2. CURSOR CONTROL DEMO
# ------------------------------------------------
echo -e "\n\e[1;37mCURSOR CONTROL (step by step)\e[0m"

echo -e "Normal line"
sleep 1

echo -e "\e[sMoved line (cursor hidden)\e[?25l"
sleep 2

echo -e "\e[uBack at saved spot, cursor visible again\e[?25h"
sleep 2

echo -ne "This will disappear in 2 sec..."
sleep 2
echo -e "\e[2K\rLine cleared!"
sleep 1
pause

# ------------------------------------------------
# 3. 256-COLOR FOREGROUND TEST
# ------------------------------------------------
echo -e "\n\e[1;37m256-COLOR FOREGROUND TEST\e[0m"
for i in {0..255}; do
  echo -ne "\e[38;5;${i}m${i}\t"
  (( i % 8 == 7 )) && echo -e "${RESET}"
done
pause

# ------------------------------------------------
# 4. 256-COLOR BACKGROUND TEST (animated sweep)
# ------------------------------------------------
echo -e "\n\e[1;37m256-COLOR BACKGROUND (animated)\e[0m"
for i in {0..255}; do
  echo -ne "\e[48;5;${i}m  ${RESET}"
  (( i % 16 == 15 )) && echo
  sleep 0.005
done
pause

# ------------------------------------------------
# 5. TRUECOLOR GRADIENT (RGB)
# ------------------------------------------------
echo -e "\n\e[1;37mTRUECOLOR GRADIENT\e[0m"
for r in {255..0..-15}; do
  g=$((255 - r))
  echo -ne "\e[48;2;${r};${g};0m "
  sleep 0.01
done
echo -e "${RESET}"
pause

# ------------------------------------------------
# 6. TRUECOLOR RAINBOW BAR
# ------------------------------------------------
echo -e "\n\e[1;37mTRUECOLOR RAINBOW\e[0m"
for g in {0..255..5}; do
  r=$((255 - g))
  b=$((g / 2))
  echo -ne "\e[48;2;${r};${g};${b}m "
  sleep 0.01
done
echo -e "${RESET}"
pause

# ------------------------------------------------
# 7. MATRIX-STYLE FALLING CHARS
# ------------------------------------------------
echo -e "\n\e[1;37mMATRIX EFFECT (short demo)\e[0m"
LINES=$(tput lines)
COLS=$(tput cols)

for ((i=0; i<300; i++)); do
  row=$((RANDOM % LINES))
  col=$((RANDOM % COLS))
  char=$(printf "\\$(printf '%03o' $((RANDOM % 94 + 33)))")
  echo -ne "\e[${row};${col}H\e[38;2;0;255;0m${char}${RESET}"
  sleep 0.01
done
pause

# ------------------------------------------------
# 8. Demonstrate tertiary screen (nested alt)
# ------------------------------------------------
echo -e "\e[?1049h"   # enter tertiary
clear
echo -e "\n\e[1;37mTERTIARY SCREEN\e[0m"
echo -e "You're now in a nested alt-buffer."
sleep 2
echo -e "Returning to secondary screen in 2s after test..."


# ------------------------------------------------
# 4. 256-COLOR BACKGROUND TEST (animated sweep)                   # ------------------------------------------------
echo -e "\n\e[1;37m256-COLOR BACKGROUND (animated), in this screen ...\e[0m"
for i in {0..255}; do
  echo -ne "\e[48;5;${i}m  ${RESET}"
  (( i % 16 == 15 )) && echo
  sleep 0.005
done
pause

sleep 2
echo -e "\e[?1049l"   # exit tertiary -> back to secondary

# ------------------------------------------------
# EXIT
# ------------------------------------------------
echo -e "\n${RESET}Demo complete. Returning to normal screen..."
sleep 2
echo -e "\e[?1049l"   # exit secondary -> back to normal

