#!/bin/bash
# install_basic_ubuntu_set_1.sh
# Version 1.3
# Author: Gemini AI Agent
# Description: Installs a basic set of applications and configures essential services for Ubuntu/Debian systems.

# --- Dependency Checks ---
command -v sudo >/dev/null || { echo "Error: sudo is not installed. This script requires sudo privileges."; exit 1; }
command -v apt >/dev/null || { echo "Error: apt is not installed. This script is for Debian/Ubuntu-based systems."; exit 1; }
command -v pip >/dev/null || { echo "Error: pip is not installed. Please install Python and pip."; exit 1; }
command -v curl >/dev/null || { echo "Error: curl is not installed. Please install it."; exit 1; }

# Function to install core utilities
install_core_utilities() {
    echo "Installing core utilities..."
    sudo apt update || { echo "Error: Failed to update apt packages."; exit 1; }
    sudo apt install -y aptitude ffmpeg aria2 youtube-dl || { echo "Error: Failed to install core utilities."; exit 1; }
}

# Function to install AI/ML related tools
install_ai_tools() {
    echo "Installing AI/ML tools..."
    pip install git+https://github.com/openai/whisper.git || { echo "Error: Failed to install whisper."; exit 1; }
}

# Function to configure XRDP for remote desktop
configure_xrdp() {
    echo "Configuring XRDP..."
    sudo apt install -y xrdp || { echo "Error: Failed to install xrdp."; exit 1; }
    sudo service xrdp start || { echo "Error: Failed to start xrdp service."; exit 1; }
    sudo service xrdp status || { echo "Warning: xrdp service status check failed."; }
    # Note: adduser might require manual interaction if user already exists or for password setup.
    # Consider automating with expect or pre-creating users if this is for unattended setup.
    sudo adduser xrdp ssl-cert || { echo "Warning: Failed to add xrdp to ssl-cert group. May require manual intervention."; }
    sudo service xrdp restart || { echo "Error: Failed to restart xrdp service."; exit 1; }
}

# Function to install system info and browser tools
install_system_tools() {
    echo "Installing system info and browser tools..."
    sudo apt install -y neofetch geoip-bin ranger baobab firefox-esr || { echo "Error: Failed to install system tools."; exit 1; }
}

# Function to display system information
display_system_info() {
    echo "Displaying system information..."
    neofetch || echo "Warning: neofetch command failed."
    curl https://ipinfo.io/ip || echo "Warning: Failed to retrieve public IP address."
}

# Main execution
install_core_utilities
install_ai_tools
configure_xrdp
install_system_tools
display_system_info

echo "Basic Ubuntu setup complete."

# Tips:
# To mount it via Sshfs: sshfs abovetrans@34.147.26.51: /home/zezen/google_abovetrans_cloud_VM_1 -p 6000 -oIdentityFile=/home/zezen/.ssh/google_compute_engine -oStrictHostKeyChecking=no
# See https://cloud.google.com/sdk/gcloud/reference/cloud-shell/get-mount-command

# DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0ARtbsJrLrNVnIbdBlV5jewUOc7uhwyjRKCI0PiDnlmideyoYHgtgchSzTv1ldRfRNKL3uQ" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
