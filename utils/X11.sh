#!/bin/bash
# X11.sh - Script to manage Termux X11 server and applications.
# Version 1.1

# --- Dependency Checks ---
command -v sudo >/dev/null || { echo "Error: sudo is not installed. This script requires sudo privileges."; exit 1; }
command -v pkill >/dev/null || { echo "Error: pkill is not installed. Please install it."; exit 1; }
command -v termux-x11 >/dev/null || { echo "Error: termux-x11 is not installed. Please install it."; exit 1; }
command -v am >/dev/null || { echo "Error: am (Android Activity Manager) is not available. This script is for Termux on Android."; exit 1; }

# Kill the current X11 server
sudo pkill  -f termux.x11 || echo "Warning: No running termux.x11 server found to kill."

# Start a new instance of the X11 server in the background
termux-x11 :1  &>/dev/null &

# Start the Termux:X11 application (an X client) which interfaces with the X11 server
am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null || { echo "Error: Failed to start Termux:X11 application."; exit 1; }

# Bring Termux (another X client) to the foreground
am start -n com.termux/.app.TermuxActivity &>/dev/null || { echo "Error: Failed to bring Termux to foreground."; exit 1; }

echo "X11 server and Termux applications started. You should now see the X11 environment."
