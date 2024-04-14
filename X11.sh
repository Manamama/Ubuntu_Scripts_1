# Kill the current X11 server
sudo pkill  -f termux.x11

# Start a new instance of the X11 server in the background
termux-x11 :1  &

# Start the Termux:X11 application (an X client) which interfaces with the X11 server
am start -n com.termux.x11/com.termux.x11.MainActivity

# Bring Termux (another X client) to the foreground
am start -n com.termux/.app.TermuxActivity

echo Test message to check being back in control ...
