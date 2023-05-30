
# Version 2.5.2, ChatGPT reordered
# Update the package lists
sudo apt-get update

# Install the Xfce desktop environment and related packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 desktop-base

# Install the xscreensaver, dbus-x11, and task-xfce-desktop packages
sudo apt-get install -y xscreensaver dbus-x11 task-xfce-desktop

# Install the Firefox ESR browser
sudo apt-get install -y firefox-esr

# Download the Chrome Remote Desktop package if it doesn't already exist
if [[ ! -f "~/Downloads/chrome-remote-desktop_current_amd64.deb" ]]; then
    wget -P ~/Downloads https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
fi

# Install the Chrome Remote Desktop package using dpkg
sudo dpkg -i ~/Downloads/chrome-remote-desktop_current_amd64.deb

# Add the current user to the chrome-remote-desktop group
sudo usermod -a -G chrome-remote-desktop $USER

# Fix any broken dependencies using apt
sudo apt-get --fix-broken install -y

# Download the TeamViewer package if it doesn't already exist
if [[ ! -f "~/Downloads/teamviewer-host_amd64.deb" ]]; then
    wget -P ~/Downloads https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb
fi

# Install the TeamViewer package using dpkg
sudo dpkg -i ~/Downloads/teamviewer-host_amd64.deb

# Fix any broken dependencies using apt
sudo apt-get --fix-broken install -y
# Start teamviewer daemon
sudo teamviewer --daemon start
# service --status-all, to check if it is running

# Install the Xrdp package for remote desktop support
sudo apt-get install -y xrdp

# Enable the Xrdp service to start on boot
sudo systemctl enable xrdp

# Add the user xrdp to the ssl-cert group
sudo adduser xrdp ssl-cert

# Set the default Xsession to xfce4-session for Xrdp
echo xfce4-session > ~/.xsession

# Restart the Xrdp service
sudo service xrdp restart

# Restart the Chrome Remote Desktop service
sudo service chrome-remote-desktop restart

# Print a message instructing the user to visit a specific URL to set up Chrome Remote Desktop
echo "Go to https://remotedesktop.google.com/access now and download and paste here the activation command."
