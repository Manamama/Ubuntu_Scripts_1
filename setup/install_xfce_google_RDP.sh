
#!/bin/bash
# install_xfce_google_RDP.sh
# Version 2.5.4
# Author: Gemini AI Agent
# Description: Installs and configures XFCE desktop environment, Chrome Remote Desktop, TeamViewer, and XRDP.

# --- Dependency Checks ---
command -v sudo >/dev/null || { echo "Error: sudo is not installed. This script requires sudo privileges."; exit 1; }
command -v apt-get >/dev/null || { echo "Error: apt-get is not installed. This script is for Debian/Ubuntu-based systems."; exit 1; }
command -v wget >/dev/null || { echo "Error: wget is not installed. Please install it."; exit 1; }
command -v dpkg >/dev/null || { echo "Error: dpkg is not installed. Please install it."; exit 1; }
command -v usermod >/dev/null || { echo "Error: usermod is not installed. Please install it."; exit 1; }
command -v systemctl >/dev/null || { echo "Error: systemctl is not installed. Please install it."; exit 1; }
command -v teamviewer >/dev/null || { echo "Warning: teamviewer is not installed. TeamViewer setup will be skipped."; }

# --- Configuration Variables ---
CHROME_REMOTE_DESKTOP_DEB="chrome-remote-desktop_current_amd64.deb"
CHROME_REMOTE_DESKTOP_URL="https://dl.google.com/linux/direct/$CHROME_REMOTE_DESKTOP_DEB"
TEAMVIEWER_HOST_DEB="teamviewer-host_amd64.deb"
TEAMVIEWER_HOST_URL="https://download.teamviewer.com/download/linux/$TEAMVIEWER_HOST_DEB"
DOWNLOAD_DIR="~/Downloads"

# Function to install XFCE desktop environment
install_xfce() {
    echo "Installing Xfce desktop environment..."
    sudo apt-get update || { echo "Error: Failed to update package lists."; exit 1; }
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 desktop-base xscreensaver dbus-x11 task-xfce-desktop firefox-esr || { echo "Error: Failed to install Xfce components."; exit 1; }
}

# Function to install and configure Chrome Remote Desktop
configure_chrome_remote_desktop() {
    echo "Installing and configuring Chrome Remote Desktop..."
    if [[ ! -f "$DOWNLOAD_DIR/$CHROME_REMOTE_DESKTOP_DEB" ]]; then
        wget -P "$DOWNLOAD_DIR" "$CHROME_REMOTE_DESKTOP_URL" || { echo "Error: Failed to download Chrome Remote Desktop package."; return 1; }
    fi
    sudo dpkg -i "$DOWNLOAD_DIR/$CHROME_REMOTE_DESKTOP_DEB" || { echo "Error: Failed to install Chrome Remote Desktop package."; return 1; }
    sudo usermod -a -G chrome-remote-desktop $USER || { echo "Error: Failed to add user to chrome-remote-desktop group."; return 1; }
    sudo apt-get --fix-broken install -y || { echo "Error: Failed to fix broken dependencies after Chrome Remote Desktop install."; return 1; }
    sudo service chrome-remote-desktop restart || { echo "Error: Failed to restart Chrome Remote Desktop service."; return 1; }
}

# Function to install and configure TeamViewer Host
configure_teamviewer() {
    echo "Installing and configuring TeamViewer Host..."
    if command -v teamviewer >/dev/null; then
        if [[ ! -f "$DOWNLOAD_DIR/$TEAMVIEWER_HOST_DEB" ]]; then
            wget -P "$DOWNLOAD_DIR" "$TEAMVIEWER_HOST_URL" || { echo "Error: Failed to download TeamViewer Host package."; return 1; }
        fi
        sudo dpkg -i "$DOWNLOAD_DIR/$TEAMVIEWER_HOST_DEB" || { echo "Error: Failed to install TeamViewer Host package."; return 1; }
        sudo apt-get --fix-broken install -y || { echo "Error: Failed to fix broken dependencies after TeamViewer install."; return 1; }
        sudo teamviewer --daemon start || { echo "Error: Failed to start TeamViewer daemon."; return 1; }
        sudo teamviewer --daemon status || { echo "Warning: TeamViewer daemon status check failed."; }
    else
        echo "Skipping TeamViewer installation as 'teamviewer' command not found."
    fi
}

# Function to install and configure XRDP
configure_xrdp() {
    echo "Installing and configuring XRDP..."
    sudo apt-get install -y xrdp || { echo "Error: Failed to install xrdp."; exit 1; }
    sudo systemctl enable xrdp || { echo "Error: Failed to enable xrdp service."; exit 1; }
    sudo adduser xrdp ssl-cert || { echo "Warning: Failed to add xrdp to ssl-cert group. May require manual intervention."; }
    echo xfce4-session > ~/.xsession || { echo "Error: Failed to set default Xsession."; exit 1; }
    sudo service xrdp restart || { echo "Error: Failed to restart xrdp service."; exit 1; }
}

# Main execution
install_xfce
configure_chrome_remote_desktop
configure_teamviewer
configure_xrdp

echo "Installation and configuration complete. Please visit https://remotedesktop.google.com/access to finalize Chrome Remote Desktop setup."
