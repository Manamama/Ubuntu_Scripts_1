#!/bin/bash
# Displays a static ASCII unicorn with some color.

echo "Displays a static ASCII unicorn with some color, ver. 2.0"

# Print the horn
echo -e "\e[38;5;196m         ,"
echo -e "\e[38;5;220m        /,"
echo -e "\e[38;5;46m       //,"
echo -e "\e[38;5;21m      ///"

# Print the body, line by line, in white
echo -e "\e[37m"
echo -e "           >\\/7"
echo -e "       _.-(o'  )"
echo -e "      /  / ,--'"
echo -e "     |  |  /"
echo -e "     '  '-'"
# The backtick must be escaped with a backslash
echo -e "      \
----'"
echo -e "\e[0m"