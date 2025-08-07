#!/bin/bash
# install_basic_ubuntu_set_1.sh
# Version 1.7
# Author: Gemini AI Agent, ChatGPT, Modified by Manamama
# Description: Installs a robust development and AI environment on Ubuntu/Debian systems.

set -e
export DEBIAN_FRONTEND=noninteractive

# --- Dependency Checks ---
for cmd in sudo apt pip curl; do
  command -v $cmd >/dev/null || { echo "Error: '$cmd' is not installed."; exit 1; }
done

# --- Core Utilities ---
install_core_utilities() {
  echo "🔧 Installing core utilities..."
  sudo apt update
  sudo apt-get install -y keyboard-configuration && sudo dpkg-reconfigure -f noninteractive keyboard-configuration
  sudo apt install -y aptitude ffmpeg aria2 youtube-dl
}

# --- AI Tools ---
install_ai_tools() {
  echo "🧠 Installing AI/ML tools..."
  pip install git+https://github.com/openai/whisper.git
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

  sudo apt install -y neofetch geoip-bin ranger baobab \
      build-essential curl libcurl4-openssl-dev libomp-dev \
      pciutils cmake cpufetch lobomp-dev libssl-dev adb fastboot

  # Fallback to Snap Firefox (no firefox-esr in Ubuntu 20.04)
  if ! sudo apt install -y firefox; then
    echo "⚠️ Firefox via APT failed. Installing via Snap..."
    sudo snap install firefox || echo "⚠️ Snap Firefox install also failed. Skipping browser install."
  fi

  # PeakPerf setup
  git clone https://github.com/Dr-noob/peakperf
  pushd peakperf
    sed -i '/set(SANITY_FLAGS/ s/^/#/' CMakeLists.txt
    ./build.sh && ./peakperf
  popd

  # Grub Customizer
  sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
  sudo apt install -y grub-customizer

  # Python pip & extras
  sudo apt install -y python3-pip scrcpy

  # Android Platform Tools
  pushd ~/Downloads
    wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
    unzip -o platform-tools-latest-linux.zip
    sudo cp -rf platform-tools/* /usr/bin/
    /bin/fastboot --version || echo "⚠️ fastboot not found post-install."
  popd

  # Gotop
  wget https://github.com/xxxserxxx/gotop/releases/download/v4.2.0/gotop_v4.2.0_linux_amd64.deb
  sudo dpkg -i gotop_v4.2.0_linux_amd64.deb || sudo apt -f install -y
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
  git clone https://github.com/ggml-org/llama.cpp
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
