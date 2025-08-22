#!/bin/bash
# install_basic_ubuntu_set_1.sh
# Version 2.3.0
# Author: Gemini AI Agent, ChatGPT, Modified by Manamama
# Description: Installs a robust development and AI environment on Ubuntu/Debian systems.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive


# --- Core Utilities ---
install_core_utilities() {

  echo "🔧 Installing core utilities..."
  export DEBIAN_FRONTEND=noninteractive

  export PATH=$PATH:$HOME/.local/bin
  mkdir -p /opt/user_home_data/
  
  #Check if not linked already: 
  ls -ls $HOME/.local
  echo
  mv $HOME/.local $HOME/.local.bak 
  mv $HOME/.cache $HOME/.cache.bak 
   
  sudo chown $(whoami):$(whoami) -R /opt/user_home_data/

  mkdir -p /opt/user_home_data/.local
  mkdir -p /opt/user_home_data/.cache

  ln -s /opt/user_home_data/.local $HOME/.local || true
  ln -s /opt/user_home_data/.cache $HOME/.cache || true
  



  ls -ls $HOME/.local 
  echo
  mkdir -p $HOME/.local/bin
  #Decide if to move $HOME/.cache/ to some /temp/.cache folder here
  sudo chown $(whoami):$(whoami) -R $HOME/.local/
  mkdir -p $PATH:$HOME/.local/bin
  sudo apt update
  DEBIAN_FRONTEND=noninteractive sudo apt-get install -y keyboard-configuration && sudo dpkg-reconfigure -f noninteractive keyboard-configuration
  sudo apt install -y aptitude ffmpeg aria2 
}

# --- AI Tools ---
install_ai_tools() {
  echo "🧠 Installing AI/ML tools..."
  pip install -U whisperx
  #pip install git+https://github.com/openai/whisper.git
  python -m pip install numpy torch torchvision torchaudio tensorflow-cpu jax jaxlib protobuf --upgrade --extra-index-url https://download.pytorch.org/whl/cpu
}

# --- XRDP Setup ---
configure_xrdp() {
  echo "🖥️ Configuring XRDP..."
  sudo apt install -y xrdp
  sudo systemctl enable --now xrdp
  sudo adduser xrdp ssl-cert || true
  sudo systemctl restart xrdp
}

# --- System and Dev Tools ---
install_system_tools() {
    echo "🧰 Installing system and dev tools..."

    sudo apt-get update

    # Core dev tools
    sudo apt-get install -y \
        pciutils build-essential cmake curl libcurl4-openssl-dev \
        libomp-dev libssl-dev adb fastboot neofetch geoip-bin ranger baobab firefox \
        || echo "⚠️ Some base packages failed to install."

    # Optional: cpufetch (available only in 22.04+)
    if apt-cache show cpufetch >/dev/null 2>&1; then
        sudo apt install -y cpufetch || echo "⚠️ Failed to install cpufetch."
    else
        echo "ℹ️ cpufetch not available on this system."
    fi
    wget https://github.com/cjbassi/gotop/releases/download/3.0.0/gotop_3.0.0_linux_amd64.deb
sudo dpkg -i gotop_3.0.0_linux_amd64.deb

git clone https://github.com/Dr-Noob/cpufetch  || echo "⚠️ cpufetch already exists or failed clone, continuing..."
cd cpufetch
sudo make install 
cpufetch

cd .. 

pip install -U youtube-dl
    # PeakPerf setup
    git clone https://github.com/Dr-noob/peakperf || echo "⚠️ Exists or failed to clone peakperf."
    cd peakperf || return

    # Patch CMakeLists.txt to skip SANITY_FLAGS
    sed -i '/set(SANITY_FLAGS/ s/^/#/' CMakeLists.txt

    ./build.sh && ./peakperf || echo "⚠️ Peakperf build/run failed."

    cd .. || return

    sudo apt clean
    sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
    sudo apt install -y grub-customizer python3-pip scrcpy || echo "⚠️ Some optional tools failed."

    # Install Android Platform Tools
    cd ~/Downloads
    wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
    unzip -o platform-tools-latest-linux.zip
    sudo cp -r platform-tools/* /usr/bin/

}

# --- Modern CMake ---
install_modern_cmake() {
  echo "🛠 Installing latest CMake via Kitware..."

  sudo rm -f /etc/apt/sources.list.d/kitware.list
  sudo sed -i '/kitware/d' /etc/apt/sources.list
  sudo rm -f /usr/share/keyrings/kitware-archive-keyring.gpg

  wget -qO - https://apt.kitware.com/keys/kitware-archive-latest.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main" \
    | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y cmake
}

# --- Node.js + NVM ---
install_node_nvm_npm() {
  echo "🕸 Installing Node.js via NVM..."

  export NVM_DIR="$HOME/.nvm"
  [ ! -d "$NVM_DIR" ] && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'

  grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
  grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc

  echo "✅ Node: $(node -v), npm: $(npm -v)"
}

# --- Sysinfo ---
display_system_info() {
  echo "📟 System Info:"
  neofetch || true
  curl -s https://ipinfo.io/ip || echo "⚠️ IP fetch failed."
}

# --- LLaMA Build ---
build_llama() {
  echo "🦙 Cloning and building llama.cpp..."

  mkdir -p ~/Downloads/GitHub && cd ~/Downloads/GitHub
  git clone https://github.com/ggml-org/llama.cpp  || echo "⚠️ llama.cpp already exists, continuing..."
  cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON
  cmake --build llama.cpp/build --config Release -j --clean-first --target llama-cli llama-gguf-split
  cd llama.cpp/build && sudo make install
}

# --- Gemini CLI ---
install_gemini_cli() {
  npm install -g @google/gemini-cli
  export NO_BROWSER=1
  echo "🔮 Run \`gemini\` to get started."
}

# --- Execution Flow ---
install_core_utilities
install_ai_tools
configure_xrdp
install_system_tools
install_modern_cmake
install_node_nvm_npm
display_system_info
build_llama
install_gemini_cli

echo "✅ Basic Ubuntu setup complete."

# --- Notes ---
# SSHFS Mount:
# sshfs user@host:/remote/path /local/mountpoint -p 6000 -oIdentityFile=~/.ssh/google_compute_engine -oStrictHostKeyChecking=no

# Chrome Remote Desktop:
# DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="..." --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)




## Replit adaptation

Here be an ugly paste of interim idea how to install most of these in Replit: 


# Installation Plan
 

This plan outlines the steps to install the software from the `install_basic_ubuntu_set_1.sh` script, using a combination of `nix`, `pip`, and `npm` as requested.

## 1. Core Utilities

These are fundamental tools for development and media manipulation.

*   **Tools**: `ffmpeg`, `aria2`, `youtube-dl`
*   **Method**: `pip`. Failing that: `npm`. Failing that: `nix`

## 2. AI Tools

This section covers AI and machine learning tools.

*   **Tool**: `whisper`
*   **Method**: `pip`
*   **Command**:
    ```bash
    pip install git+https://github.com/openai/whisper.git
    ```

## 3. System and Dev Tools

This section includes a variety of development and system inspection tools.

*   **Tools**: `pciutils`, `build-essential`, `cmake`, `curl`, `libcurl4-openssl-dev`, `libomp-dev`, `libssl-dev`, `adb`, `fastboot`, `neofetch`, `geoip-bin`, `ranger`, `baobab`, `firefox`, `scrcpy`
*   **Method**: `nix`
*   **Command**:
    ```bash
    nix profile install nixpkgs#pciutils nixpkgs#build-essential nixpkgs#cmake nixpkgs#curl nixpkgs#libcurl nixpkgs#libomp nixpkgs#openssl nixpkgs#android-tools nixpkgs#neofetch nixpkgs#geoip nixpkgs#ranger nixpkgs#baobab nixpkgs#firefox nixpkgs#scrcpy
    ```

*   **Tool**: `cpufetch`
*   **Method**: Build from source
*   **Commands**:
    ```bash
    git build-essential --run "git clone https://github.com/Dr-Noob/cpufetch && cd cpufetch && make && sudo make install"
    ```
Watch out for errors.

*   **Tool**: `peakperf`
*   **Method**: Build from source
*   **Commands**:
    ```bash
    git cmake build-essential --run "git clone https://github.com/Dr-noob/peakperf && cd peakperf && sed -i '/set(SANITY_FLAGS/ s/^/#/' CMakeLists.txt && ./build.sh"
    ```

## 4. Node.js + NVM

This section may sets up the Node.js environment using NVM, as requested, but likely not needed as Replit should have the newest nvm etc stuff anyway.

## 5. LLaMA Build

This section covers building the `llama.cpp` project.

*   **Tool**: `llama.cpp`
*   **Method**: Build from source
*   **Commands**:
    ```bash
    mkdir -p ~/Downloads/GitHub && cd ~/Downloads/GitHub
    git cmake build-essential --run "git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp && cmake . -B build -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON && cmake --build build --config Release -j --clean-first --target llama-cli llama-gguf-split"
    ```

## 6. Gemini CLI
Not needed as Gemini AI is already in one and is using it right now ;)

## 7. XRDP Setup
Not needed, skipped
