#!/bin/bash
# install_basic_ubuntu_set_1.sh
# Version 1.6
# Author: Gemini AI Agent, ChatGPT, Modified by Manamama
# Description: Installs a basic set of applications and configures essential services for Ubuntu/Debian systems.


export DEBIAN_FRONTEND=noninteractive

# --- Dependency Checks ---
command -v sudo >/dev/null || { echo "Error: sudo is not installed. This script requires sudo privileges." }
command -v apt >/dev/null || { echo "Error: apt is not installed. This script is for Debian/Ubuntu-based systems." }
command -v pip >/dev/null || { echo "Error: pip is not installed. Please install Python and pip." }
command -v curl >/dev/null || { echo "Error: curl is not installed. Please install it." }

# Function to install core utilities
install_core_utilities() {
    echo "Installing core utilities..."
    
    sudo apt update || { echo "Error: Failed to update apt packages." }
    
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y keyboard-configuration && sudo dpkg-reconfigure -f noninteractive keyboard-configuration

    sudo apt install -y aptitude ffmpeg aria2 youtube-dl || { echo "Error: Failed to install core utilities." }
}

# Function to install AI/ML related tools
install_ai_tools() {
    echo "Installing AI/ML tools..."
    pip install git+https://github.com/openai/whisper.git || { echo "Error: Failed to install whisper." }
}

# Function to configure XRDP for remote desktop
configure_xrdp() {
    echo "Configuring XRDP..."
    sudo apt install -y xrdp || { echo "Error: Failed to install xrdp." }
    sudo service xrdp start || { echo "Error: Failed to start xrdp service." }
    sudo adduser xrdp ssl-cert || { echo "Warning: Failed to add xrdp to ssl-cert group."; }
    sudo service xrdp restart || { echo "Error: Failed to restart xrdp service." }
}

# Function to install system info and browser tools
install_system_tools() {
    echo "Installing system info, development and browser tools..."
    
    sudo apt-get update
 sudo apt-get install pciutils build-essential cmake curl libcurl4-openssl-dev lobomp-dev cpufetch libomp-dev libssl-dev adb fastboot-y
 
    sudo apt install -y neofetch geoip-bin ranger baobab firefox || { echo "Error: Failed to install system tools." }

    git clone https://github.com/Dr-noob/peakperf


cd peakperf

#In CmakeList.txt comment out #Set (SANITY_FLAGS)
sed -i '/set(SANITY_FLAGS/ s/^/#/' CMakeLists.txt

./build.sh
./peakperf
sudo apt clean
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt install grub-customizer -y
sudo apt install python3-pip -y 
sudo apt clean
sudo apt autoremove -y
sudo apt install scrcpy -y 
# https://gist.github.com/Ericwyn/e89553d8dfcb9fc9066da506d9e6fd93
cd ~/Downloads

	wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip

	unzip platform-tools-latest-linux.zip

	sudo cp -R -f platform-tools/* /usr/bin/*

	#rm -rf platform-tools/
	#rm platform-tools-latest-linux.zip

	echo "install latest platform success"

	/bin/fastboot --version

wget https://github.com/xxxserxxx/gotop/releases/download/v4.2.0/gotop_v4.2.0_linux_amd64.deb
sudo dpkg -i gotop_v4.2.0_linux_amd64.deb

}

# Function to cleanly install the latest CMake via Kitware repo
install_modern_cmake() {
    echo "Installing development tools and modern CMake from Kitware APT repo..."

    # Clean old Kitware config if exists
    sudo rm -f /etc/apt/sources.list.d/kitware.list
    sudo sed -i '/kitware/d' /etc/apt/sources.list
    sudo rm -f /usr/share/keyrings/kitware-archive-keyring.gpg

    # Add Kitware securely
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main" \
        | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

    sudo apt-get update
    sudo apt-get install -y cmake || { echo "Error: Failed to install CMake." }
}

# Function to install Node.js, npm, and nvm properly (no apt)
install_node_nvm_npm() {
    echo "Installing latest Node.js, npm, and nvm..."

    # Install NVM (Node Version Manager)
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    fi

    # Load nvm immediately (without relogin)
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest Node.js LTS
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"

    grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc


}

# Function to display system information
display_system_info() {
    echo "Displaying system information..."
    neofetch || echo "Warning: neofetch command failed."
    curl https://ipinfo.io/ip || echo "Warning: Failed to retrieve public IP address."
}

# --- Main Execution ---
install_core_utilities
install_ai_tools
configure_xrdp
install_system_tools
install_modern_cmake
install_node_nvm_npm
display_system_info

mkdir -P Downloads/GitHub
cd Downloads/GitHub
git clone https://github.com/ggml-org/llama.cpp


#See: https://docs.unsloth.ai/basics/gpt-oss-how-to-run-and-fine-tune for theory
#No CUDA , but switch on, if CUDA available: 
cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j --clean-first --target llama-cli llama-gguf-split
#cp llama.cpp/build/bin/llama-* llama.cpp
cd llama.cpp/build
sudo make install



#Gemini: 
 npm install -g @google/gemini-cli
 export NO_BROWSER=1 
 echo run `gemini` now. 

echo "✅ Basic Ubuntu setup complete."

# --- Tips ---
# To mount via Sshfs:
# sshfs user@host:/remote/path /local/mountpoint -p 6000 -oIdentityFile=~/.ssh/google_compute_engine -oStrictHostKeyChecking=no
#
# Chrome Remote Desktop launch example:
# DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="..." --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
