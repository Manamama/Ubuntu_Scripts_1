tput civis
for i in {0..5}; do
# do not move it to top
  #tput cup 0 0
  echo -ne "\033[2K\033[38;5;82m[$(printf "%${i}s" | tr ' ' '\u2588')$(printf "%$((5-i))s" | tr ' ' '\u2591')]\033[0m $((i*20))%"
echo
  sleep 0.5
done
# do not move it to bottom either.
#tput cup 1 0
tput cnorm