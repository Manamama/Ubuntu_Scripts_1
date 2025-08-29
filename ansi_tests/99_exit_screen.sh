#!/bin/bash
# Exits the secondary screen buffer, returning to the normal terminal.
echo -e '\n\e[0mDemo complete. Returning to normal screen...'
sleep 2
echo -e '\e[?1049l'
