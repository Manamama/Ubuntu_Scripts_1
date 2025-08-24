#!/bin/bash

# Author: Gemini AI Agent, ChatGPT, Modified by Manamama
# Description: Installs a robust development and AI environment on Ubuntu/Debian systems.

set -uo pipefail  # keep -u and -o pipefail
# do NOT use -e globally. No -e → commands that fail won’t abort the script, letting functions fail naturally.
#-u → undefined variables still fail (good safety)
# -o pipefail → pipelines still propagate errors

export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<EOF
keyboard-configuration keyboard-configuration/layoutcode string us
keyboard-configuration keyboard-configuration/modelcode string pc105
keyboard-configuration keyboard-configuration/variant string 
keyboard-configuration keyboard-configuration/optionscode string
EOF



git config --global user.email manamama@github.com

git config --global user.name ManamaMa


# --- Core Utilities ---
install_core_utilities() {



  echo "🔧 Installing core utilities..."
  echo
  # --- Verify Critical Mounts ---
  echo "🔎 Verifying that data directories are correctly relocated..."

  local all_mounts_ok=true
  local CACHE_SRC="$HOME/.cache"
  local LIB_SRC="$HOME/.local/lib"

  if ! mount | grep -q "on $CACHE_SRC"; then
    echo "⚠️ WARNING: $CACHE_SRC is not a bind mount. The relocation logic in .bashrc may have failed."
    all_mounts_ok=false
  fi

  if ! mount | grep -q "on $LIB_SRC"; then
    echo "⚠️ WARNING: $LIB_SRC is not a bind mount. The relocation logic in .bashrc may have failed."
    all_mounts_ok=false
  fi

  if [ "$all_mounts_ok" = true ]; then
    echo "✅ Success: ~/.cache and ~/.local/lib are correctly relocated."
  fi
  echo
  # --- End of Verification ---

  #No warning in GCloud about persistence of apt
  mkdir -p ~/.cloudshell
  touch ~/.cloudshell/no-apt-get-warning

  export DEBIAN_FRONTEND=noninteractive
  
  export PATH=$PATH:$HOME/.local/bin

  sudo apt update
  #DEBIAN_FRONTEND=noninteractive sudo apt-get install -y keyboard-configuration
  sudo dpkg-reconfigure -f noninteractive keyboard-configuration
  sudo apt install -y aptitude ffmpeg aria2
  #This takes too much time:
  #sudo apt upgrade -y 
  

  
  mkdir -p ~/Downloads/GitHub 
cd ~/Downloads/GitHub
  
}


# --- AI Tools ---
install_ai_tools() {

sudo npm install -g rust-just

  echo "🧠 Installing AI/ML tools..."
  python -m ensurepip
  python -m pip install -U whisperx numpy torch torchvision torchaudio tensorflow-cpu jax jaxlib protobuf --extra-index-url https://download.pytorch.org/whl/cpu
  # python -m pip install git+https://github.com/openai/whisper.git
}


# --- XRDP Setup ---
configure_xrdp() {
  echo "🖥️ Configuring XRDP..."
  sudo apt install -y xrdp
  sudo systemctl enable --now xrdp || true
  sudo adduser xrdp ssl-cert || true
  sudo systemctl restart xrdp || true
}

# --- System and Dev Tools ---
install_system_tools() {
    echo "🧰 Installing system and dev tools..."

    sudo apt-get update

    # Core dev tools
    sudo apt-get install -y pciutils build-essential cmake curl libcurl4-openssl-dev \
        libomp-dev libssl-dev adb fastboot neofetch geoip-bin ranger baobab firefox python3-pip ncdu mediainfo
npm install  -g neofetch                                
    # Optional: cpufetch
    if apt-cache show cpufetch >/dev/null 2>&1; then
        sudo apt install -y cpufetch
    else
cd ~/Downloads/GitHub


        echo "ℹ️ cpufetch not available via apt, building from source..."
        git clone https://github.com/Dr-Noob/cpufetch
        cd cpufetch
        sudo make install -j8
        cd ..
    fi

    # gotop
    wget -c https://github.com/cjbassi/gotop/releases/download/3.0.0/gotop_3.0.0_linux_amd64.deb
    sudo dpkg -i gotop_3.0.0_linux_amd64.deb

    # youtube-dl
    python -m pip install -U yt-dlp youtube-dl

    # PeakPerf setup
cd ~/Downloads/GitHub
    git clone https://github.com/Dr-noob/peakperf
    cd peakperf
    # Patch CMakeLists.txt to skip SANITY_FLAGS
    sed -i '/set(SANITY_FLAGS/ s/^/#/' CMakeLists.txt
    ./build.sh
    cp  ./peakperf "$HOME/.local/bin/"
    sudo make install -j8 
    #./peakperf
    cd ..

    sudo apt clean
    sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
    sudo apt install -y grub-customizer python3-pip scrcpy

# Android Platform Tools
cd ~/Downloads/GitHub
wget -c https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -o platform-tools-latest-linux.zip
sudo cp -r platform-tools/* /usr/bin/


sudo mkdir -p /etc/apt/keyrings
# Use gpg --dearmor safely, overwrite without prompt
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg
# Add repo referencing the keyring
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt * *" | sudo tee /etc/apt/sources.list.d/charm.list

sudo apt install -y glow



}

# --- Modern CMake ---
install_modern_cmake() {
    echo "🛠 Installing latest CMake via Kitware..."

    # Detect Ubuntu codename dynamically
    CODENAME=$(lsb_release -cs)
    echo "ℹ️ Detected Ubuntu codename: $CODENAME"

    # Clean previous Kitware sources if any
    sudo rm -f /etc/apt/sources.list.d/kitware.list
    sudo sed -i '/kitware/d' /etc/apt/sources.list
    sudo rm -f /usr/share/keyrings/kitware-archive-keyring.gpg

    # Add Kitware key
    wget  -c -qO - https://apt.kitware.com/keys/kitware-archive-latest.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

    # Add the correct Kitware repository for detected Ubuntu version
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu $CODENAME main" \
        | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

    # Update apt and install CMake
    sudo apt-get update
    sudo apt-get install -y cmake || echo "⚠️ CMake install failed. Check for unmet dependencies."

    echo "✅ Modern CMake installation complete."
}
# --- Node.js + NVM ---

install_node_nvm_npm() {
# Remove the old Node.js + npm first
sudo apt remove -y nodejs npm
sudo apt autoremove -y 

# Install Node.js 22.x (latest LTS) from NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
export PATH="$HOME/.npm-global/bin:$PATH"

# Verify
node --version   # should print v22.x
npm --version
}

install_node_nvm_npm2() {
    echo "🕸 Installing Node and npm..."
 

    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"

    # Clone the official NVM repository if not present
    if [ ! -d "$NVM_DIR/.git" ]; then
        git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    fi

    cd "$NVM_DIR" || return
    # Checkout the latest release tag (stable LTS support)
    git fetch --tags --quiet
    LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")
    git checkout "$LATEST_TAG" --quiet

    # Load NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install and use latest LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    # Ensure NVM loads in future shells
    grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
export PATH="$HOME/.npm-global/bin:$PATH"

    echo "✅ Node.js: $(node -v), npm: $(npm -v)"
    cd ~/Downloads/GitHub
}
 

# --- Sysinfo ---
display_system_info() {
  echo "📟 System Info:"
  #cpufetch
#No logo: 
cpufetch --logo-short \
  | sed -E 's/\x1b\[[0-9;]*m//g' \
  | sed -E ':a; s/#[^#]*#//g; ta; s/#//g; s/^[^[:alnum:]]+//; /^[[:space:]]*$/d'

  peakperf  -r 1 -w1
    neofetch --off || true
    
  curl -s https://ipinfo.io/ip || echo "⚠️ IP fetch failed."
}

# --- LLaMA Build ---
build_llama() {
  echo "🦙 Cloning and building llama.cpp..."
cd ~/Downloads/GitHub

  git clone https://github.com/ggml-org/llama.cpp  || echo "⚠️ llama.cpp already exists, continuing..."

cmake -S llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j8
sudo cmake --install llama.cpp/build

  
  
}

# --- Gemini CLI ---
install_gemini_cli() {
  npm install -g @google/gemini-cli
  export NO_BROWSER=1
  echo "🔮 Run \`gemini\` to get started."
}

echo
echo "📌 Starting Ubuntu setup..."
echo "Version 2.5.2"
echo  
# 1️⃣ Core environment and utilities first
install_core_utilities

# 2️⃣ Modern CMake early, for any builds that require it
install_modern_cmake

# 3️⃣ System and dev tools (depends on core utilities and CMake)
install_system_tools

install_node_nvm_npm

install_ai_tools

install_gemini_cli

# 6️⃣ LLaMA build (depends on modern CMake and system dev tools)
build_llama 

# 8️⃣ XRDP (optional, non-systemd systems may skip)
configure_xrdp || echo "⚠️ XRDP setup skipped (non-systemd system)."

# 9️⃣ Display system info at the end
display_system_info

echo "✅ Basic Ubuntu setup complete."



# --- Replit Adaptation ---
replit_adapt() {
    echo "🌀 Adapting setup for Replit environment..."

    # 1️⃣ Core utilities (user-space install)
    pip install --user ffmpeg aria2 youtube-dl

    # 2️⃣ AI/ML tools (user-space)
    python -m ensurepip
    python -m pip install --user -U whisperx numpy torch torchvision torchaudio tensorflow-cpu jax jaxlib protobuf --extra-index-url https://download.pytorch.org/whl/cpu

    # 3️⃣ Node.js (skip NVM, assume latest Node already present)
    echo "ℹ️ Using Node.js provided by Replit: $(node -v), npm: $(npm -v)"

    # 4️⃣ System/dev tools (nix only, user-space)
    nix profile install \
        nixpkgs#pciutils nixpkgs#cmake nixpkgs#curl nixpkgs#libcurl nixpkgs#libomp \
        nixpkgs#openssl nixpkgs#android-tools nixpkgs#neofetch nixpkgs#geoip nixpkgs#ranger \
        nixpkgs#baobab nixpkgs#firefox nixpkgs#scrcpy

    # 5️⃣ LLaMA build (build in workspace, user-space)
    mkdir -p ~/Downloads/GitHub && cd ~/Downloads/GitHub
    git clone https://github.com/ggml-org/llama.cpp || echo "⚠️ llama.cpp exists, skipping clone"
    cd llama.cpp
    cmake . -B build -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON
    cmake --build build --config Release -j --clean-first --target llama-cli llama-gguf-split
    cd ~/  # return to home

    # 6️⃣ Skip XRDP, sudo-only commands, systemd services, /opt mounts
    echo "ℹ️ Skipping XRDP, sudo, and /opt operations on Replit."

    echo "✅ Replit adaptation complete."
}
