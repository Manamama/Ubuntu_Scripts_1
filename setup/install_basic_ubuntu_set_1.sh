#!/bin/bash

# Author: Gemini AI Agent, ChatGPT, Modified by Manamama
# Description: Installs a robust development and AI environment on Ubuntu/Debian systems.

set -uo pipefail # keep -u and -o pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# do NOT use -e globally. No '-e' → as the  commands that fail won’t abort the script, letting functions fail naturally.
#-u → undefined variables still fail (good safety)
# -o pipefail → pipelines still propagate errors

echo The script is running in: $SCRIPT_DIR which shall be: SCRIPT_DIR

# --- Dependency Checks ---
check_dependencies() {
	echo "🔍 Checking essential dependencies..."
	command -v sudo >/dev/null || {
		echo "Error: sudo is not installed. This script requires sudo privileges."
		exit 1
	}
	command -v apt-get >/dev/null || {
		echo "Error: apt-get is not installed. This script is for Debian/Ubuntu-based systems."
		exit 1
	}
	command -v wget >/dev/null || {
		echo "Error: wget is not installed. Please install it."
		exit 1
	}
	command -v dpkg >/dev/null || {
		echo "Error: dpkg is not installed. Please install it."
		exit 1
	}
	command -v usermod >/dev/null || {
		echo "Error: usermod is not installed. Please install it."
		exit 1
	}
	command -v systemctl >/dev/null || {
		echo "Error: systemctl is not installed. Please install it."
		exit 1
	}

	# Node.js and npm specific checks
	if ! command -v node >/dev/null; then
		echo "Warning: Node.js is not installed. Node.js dependent installations might fail."
	fi
	if ! command -v npm >/dev/null; then
		echo "Warning: npm is not installed. npm dependent installations might fail."
	fi
	echo "✅ Dependency checks complete."
}

# --- URLs ---
REPO_URL="https://github.com/Manamama/Ubuntu_Scripts_1/"
SRC_DIR="$HOME/Downloads/GitHub" # Source directory for cloning repos
CPUFETCH_REPO_URL="https://github.com/Dr-Noob/cpufetch"
FASTFETCH_REPO_URL="https://github.com/fastfetch-cli/fastfetch"
GOTOP_DEB_URL="https://github.com/cjbassi/gotop/releases/download/3.0.0/gotop_3.0.0_linux_amd64.deb"
PEAKPERF_REPO_URL="https://github.com/Dr-noob/peakperf"
PLATFORM_TOOLS_URL="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
CHARM_APT_KEY_URL="https://repo.charm.sh/apt/gpg.key"
KITWARE_APT_KEY_URL="https://apt.kitware.com/keys/kitware-archive-latest.asc"
KITWARE_APT_REPO_BASE_URL="https://apt.kitware.com/ubuntu"
NVM_REPO_URL="https://github.com/nvm-sh/nvm.git"
LLAMA_CPP_REPO_URL="https://github.com/ggml-org/llama.cpp"
CHROME_REMOTE_DESKTOP_BASE_URL="https://dl.google.com/linux/direct/"
TEAMVIEWER_HOST_BASE_URL="https://download.teamviewer.com/download/linux/"
LOCALLIB="$HOME/.local/lib"
install_deb_local() {
	local DEB="$1"
	local TMPROOT
	local LOCALBIN="$HOME/.local/bin"
	local LOCALLIB="$HOME/.local/lib"

	if [ -z "$DEB" ] || [ ! -f "$DEB" ]; then
		echo "Usage: install_deb_local <package.deb>"
		return 1
	fi

	mkdir -p "$LOCALBIN" "$LOCALLIB"

	# Create temporary extraction root
	TMPROOT=$(mktemp -d)

	echo "Extracting $DEB into $TMPROOT ..."
	dpkg-deb -x "$DEB" "$TMPROOT"

	# Move binaries
	if [ -d "$TMPROOT/usr/local/bin" ]; then
		mv "$TMPROOT/usr/local/bin/"* "$LOCALBIN/"
	fi

	# Move libraries (optional)
	if [ -d "$TMPROOT/usr/local/lib" ]; then
		mv "$TMPROOT/usr/local/lib/"* "$LOCALLIB/" 2>/dev/null || true
	fi

	# Clean up
	rm -rf "$TMPROOT"

	echo "Installation complete."
	echo "Binaries in $LOCALBIN, libraries in $LOCALLIB."
	echo "Add to your environment if needed:"
	echo "export PATH=\"$LOCALBIN:$PATH\""
	echo "export LD_LIBRARY_PATH=\"$LOCALLIB:${LD_LIBRARY_PATH:-}\""
}

# Example usage:
# install_deb_local /path/to/gotop_3.0.0_linux_amd64.deb

configure_system_resources() {
	echo "⚙️ Configuring system resources (disk, swap, repo)..."

	 CUR_USER=$(whoami)
	
	 PYTHON_LIB=$(python -m site --user-site)
	 PERSISTENT_DEST_BASE="/root/home_extended" # Default for GCloud

echo "export PATH=\"${LOCALBIN:-/usr/local/bin}:$PATH\""
echo "export LD_LIBRARY_PATH=\"${LOCALLIB:-/usr/local/lib}:${LD_LIBRARY_PATH:-}\""



# export LD_LIBRARY_PATH=$LOCALLIB:$LD_LIBRARY_PATH

	if [ -n "${CODESPACE_NAME-}" ]; then
		echo "[INFO] Detected GitHub Codespace: using /tmp for temporary storage"
		PERSISTENT_DEST_BASE="/tmp"
	fi

	while mountpoint -q "$PYTHON_LIB"; do
		echo "[RESET] Unmounting $PYTHON_LIB ..."
		sudo umount -l "$PYTHON_LIB"
	done

	if [ -n "${CODESPACE_NAME-}" ]; then
		echo "[INFO] Detected GitHub Codespace: leaving $PYTHON_LIB in place"
	else

		# --- Python site-packages relocation ---
		 PYTHON_LIB_DEST="${PYTHON_LIB/$HOME/$PERSISTENT_DEST_BASE}"

		mkdir -p "$PYTHON_LIB"
		sudo mkdir -p "$PYTHON_LIB_DEST"
		sudo chown "$CUR_USER:$CUR_USER" "$PYTHON_LIB_DEST"

		rm -rf "$PYTHON_LIB"
		mkdir -p "$PYTHON_LIB"

		echo "[ACTION] Binding $PYTHON_LIB_DEST -> $PYTHON_LIB ..."
		sudo mount --bind "$PYTHON_LIB_DEST" "$PYTHON_LIB"
		sudo mount -o remount,rw,exec "$PYTHON_LIB"
		echo "[DONE] Bound with exec: $PYTHON_LIB_DEST -> $PYTHON_LIB"

	fi

	# --- Cache relocation ---
	 CACHE_SRC="$HOME/.cache"
	 CACHE_DEST="$PERSISTENT_DEST_BASE/.cache"

	mkdir -p "$CACHE_SRC"
	sudo mkdir -p "$CACHE_DEST"
	sudo chown "$CUR_USER:$CUR_USER" "$CACHE_DEST"

	while mountpoint -q "$CACHE_SRC"; do
		echo "[RESET] Unmounting $CACHE_SRC ..."
		sudo umount -l "$CACHE_SRC"
	done

	rm -rf "$CACHE_SRC"
	mkdir -p "$CACHE_SRC"

	echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
	sudo mount --bind "$CACHE_DEST" "$CACHE_SRC"
	sudo mount -o remount,rw,exec "$CACHE_SRC"
	echo "[DONE] Bound with exec: $CACHE_DEST -> $CACHE_SRC"

	echo
	echo "Final mount state:"
	mount | grep /home

	# --- Swap file creation ---
	echo "Creating 16 GB swap file..."
	sudo fallocate -l 16G /tmp/swapfile
	sudo chmod 600 /tmp/swapfile
	sudo mkswap /tmp/swapfile
	sudo swapon /tmp/swapfile
	swapon --show
	free -h

	echo
	echo "Space free on /home or /workspace (on the persistent thus too limited storage):"
	df -h | grep Use%
	df -h | grep /home
	df -h | grep /workspace

}

configure_persistent_environment() {
	echo "📝 Configuring persistent environment variables..."

	local ENV_FILE="$SCRIPT_DIR/ubuntu_scripts_env.sh"

	

	# Add sourcing line to .bashrc if not already present
	if ! grep -qxF "source \"$ENV_FILE\"" ~/.bash_aliases; then
		echo "" >>~/.bashrc # Add a newline for separation
		echo "# Source Ubuntu_Scripts_1 environment configuration" >>~/.bash_aliases
		echo "source \"$ENV_FILE\"" >>~/.bashrc
		echo "✅ Added sourcing line to ~/.bash_aliases."
	else
		echo "ℹ️ Sourcing line already present in ~/.bash_aliases."
	fi
	echo "✅ Persistent environment configured."
	echo
}

# --- Repository Setup ---
setup_repositories() {
	echo "📦 Setting up additional APT repositories..."

	# Kitware (for modern CMake)
	echo "Adding Kitware repository..."
	# Detect Ubuntu codename dynamically
	CODENAME=$(lsb_release -cs)
	echo "ℹ️ Detected Ubuntu codename: $CODENAME"

	# Clean previous Kitware sources if any
	sudo rm -f /etc/apt/sources.list.d/kitware.list
	sudo sed -i '/kitware/d' /etc/apt/sources.list
	sudo rm -f /usr/share/keyrings/kitware-archive-keyring.gpg

	# Add Kitware key
	wget -c -qO - "$KITWARE_APT_KEY_URL" |
		gpg --dearmor |
		sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

	# Add the correct Kitware repository for detected Ubuntu version
	echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] ""$KITWARE_APT_REPO_BASE_URL"" $CODENAME main" |
		sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

	# Grub Customizer
	echo "Adding Grub Customizer PPA..."
	sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y

	# Charm (for Glow)
	echo "Adding Charm repository..."
	sudo mkdir -p /etc/apt/keyrings
	# Use gpg --dearmor safely, overwrite without prompt
	curl -fsSL "$CHARM_APT_KEY_URL" | sudo gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg
	# Add repo referencing the keyring
	echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt * *" | sudo tee /etc/apt/sources.list.d/charm.list



echo Adding Firefox repository ... 
# Add Mozilla Team PPA
sudo add-apt-repository -y ppa:mozillateam/ppa



	echo "Adding Visual Studio repository..."

	
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
rm packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

	# Final update after adding all repos
	echo "Updating package list after adding repositories..."

sudo apt update
sudo apt install -y code
# Install Firefox as deb

sudo mkdir -p /opt && \
sudo wget -O /opt/firefox.tar.xz "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" && \
sudo tar -C /opt -xf /opt/firefox.tar.xz && \
sudo rm /opt/firefox.tar.xz && \
sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox && \
hash -r



	
}

install_ai_tools() {

	npm install -g rust-just

	echo "🧠 Installing AI/ML tools..."
	python -m ensurepip

 #Huge with CUDA:
 #python -m pip install --user -U whisperx numpy torch torchvision torchaudio tensorflow jax jaxlib protobuf 

 CPU only: 
	python -m pip install --user -U whisperx pydub numpy torch torchvision torchaudio tensorflow-cpu jax jaxlib protobuf --extra-index-url https://download.pytorch.org/whl/cpu
 python -m pip install --user openai-whisper -U 
 pip install -U whisperx -U 

cd ~/Downloads/GitHub
 git clone https://github.com/modelscope/FunASR
 pip install -U  --user FunASR/ 
 echo "If it fails, that is 'funasr' does not run, do force it:"
 echo "pip install -U  --user FunASR/ --force-reinstall"
 echo
 echo "Syntax is: 'funasr ++model=paraformer-en ++vad_model="fsmn-vad" ++punc_model="ct-punc" ++input="{audio_filename}"' "

}

# --- XRDP Setup ---
configure_xrdp() {
echo "🖥️ Configuring XRDP..."
# Install xrdp
sudo DEBIAN_FRONTEND=noninteractive apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y xrdp

# Set KDE Plasma session
echo "startplasma-x11" > ~/.xrdp.ini

# Restrict xrdp to localhost for security
sudo sed -i 's/port=3389/port=tcp:\/\/127.0.0.1:3389/' /etc/xrdp/xrdp.ini

# Bypass session chooser
sudo bash -c 'cat > /etc/xrdp/startwm.sh' << 'EOF'
#!/bin/sh
exec /usr/bin/startplasma-x11
EOF
sudo chmod +x /etc/xrdp/startwm.sh


# Configure PAM for passwordless login for codespace user
sudo bash -c 'cat > /etc/pam.d/xrdp-sesman' << 'EOF'
auth sufficient pam_succeed_if.so uid = codespace quiet
auth required pam_deny.so
account include xrdp
session include xrdp
EOF

# Start xrdp
sudo service xrdp stop
sudo service xrdp start

# Verify
echo "🖥️ XRDP status:"
sudo service xrdp status
echo "🖥️ Running processes:"
ps -ef | grep xrdp
echo "🖥️ Listening ports:"
netstat -tuln | grep -E '3389|3350'

}

# --- System and Dev Tools ---
install_system_tools() {
	echo "🧰 Installing system and dev tools..."
	sudo apt-get update

	

	# Core dev tools
	sudo apt-get install -y pciutils build-essential cmake curl  adb fastboot neofetch geoip-bin ranger mc baobab firefox python3-pip ncdu mediainfo xdg-utils
sudo apt install -y libcurl4-openssl-dev meson libtre-dev libomp-dev libssl-dev	
sudo apt install -y bison flex 
 sudo apt-get install -y npm
	sudo npm install -g neofetch

#For CUDA NVIDIA stuff:
sudo apt-get install libcudnn8 libcudnn8-dev

 
	# Optional: cpufetch
	if apt-cache show cpufetch >/dev/null 2>&1; then
		sudo DEBIAN_FRONTEND=noninteractive apt install -y cpufetch
	else
		mkdir -p "$SRC_DIR"
		cd "$SRC_DIR"

		echo "ℹ️ cpufetch not available via apt, building from source..."
		git clone "$CPUFETCH_REPO_URL"
		cd cpufetch
		cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local
		make install -j8
		cd ..
	fi
	# Optional: fastfetch
	# Ensure fastfetch is cloned into ~/Downloads/GitHub
	mkdir -p ~/Downloads/GitHub
	mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"
	if [ ! -d "fastfetch" ]; then
		git clone "$FASTFETCH_REPO_URL"
	fi
	cd fastfetch
	#sudo make install
	cmake -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local
	cmake --build build --target install
	cd - # Return to previous directory

	# gotop
	wget -c "$GOTOP_DEB_URL"

	#for good measure:
	sudo DEBIAN_FRONTEND=noninteractive dpkg -i gotop_3.0.0_linux_amd64.deb
	install_deb_local gotop_3.0.0_linux_amd64.deb

	# youtube-dl
	python -m pip install -U yt-dlp youtube-dl

	# PeakPerf setup
	mkdir -p ~/Downloads/GitHub
	mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"
	if [ ! -d "peakperf" ]; then
		git clone "$PEAKPERF_REPO_URL"
	fi
	cd peakperf
	# Patch CMakeLists.txt to skip SANITY_FLAGS
	sed -i '/set(SANITY_FLAGS/s/^/#/' CMakeLists.txt
	./build.sh
	cp ./peakperf "$HOME/.local/bin/"
	# Removed: sudo make install -j8 (as it's failing and cp already places the binary)
	#./peakperf
	cd - # Return to previous directory

	sudo apt clean
	sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
	sudo apt update # Update apt cache after adding new PPA
	sudo DEBIAN_FRONTEND=noninteractive apt install -y grub-customizer python3-pip scrcpy 



	# Android Platform Tools
	mkdir -p ~/Downloads/GitHub
	mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"
	wget -c "$PLATFORM_TOOLS_URL"
	unzip -o platform-tools-latest-linux.zip
	sudo cp -r platform-tools/* /$HOME/.local/bin/
	cd - # Return to previous directory

	sudo mkdir -p /etc/apt/keyrings
	# Use gpg --dearmor safely, overwrite without prompt
	curl -fsSL "$CHARM_APT_KEY_URL" | sudo gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg
	# Add repo referencing the keyring
	echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt * *" | sudo tee /etc/apt/sources.list.d/charm.list

	sudo apt update # Update apt cache after adding new repo
	sudo DEBIAN_FRONTEND=noninteractive apt install -y glow
	
	
	#Now, the full front end, GUI, for e.g. Google Remote Desktop etc. 
	#This does not work as no dbus: 
    #sudo DEBIAN_FRONTEND=noninteractive apt install -y gnome-session dbus-x11 gdm3

# 2. Install KDE Plasma (minimal) and required DBus
sudo apt update
sudo apt install -y kde-plasma-desktop dbus-x11

# 3. Set up CRD session script to start Plasma with user-level DBus
cat > ~/.chrome-remote-desktop-session <<'EOF'
# Start user-level DBus session if not running
if ! pgrep -x "dbus-daemon" > /dev/null; then
  eval "$(dbus-launch --sh-syntax)"
  export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
fi
exec startplasma-x11
EOF
chmod +x ~/.chrome-remote-desktop-session

# 4. Restart CRD to load the new session
/opt/google/chrome-remote-desktop/chrome-remote-desktop --stop
/opt/google/chrome-remote-desktop/chrome-remote-desktop --start
    
    
    
    #!/usr/bin/env bash
set -euo pipefail

echo "Installing Google Chrome..."

# 1. Add Google’s signing key (keyring file goes to /usr/share/keyrings)
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor | sudo tee /usr/share/keyrings/google-linux-signing-keyring.gpg > /dev/null

# 2. Add Google Chrome repo (use signed-by to avoid global trust)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] \
https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# 3. Update apt cache
sudo apt-get update

# 4. Install Chrome stable
sudo apt-get install -y google-chrome-stable

echo "Google Chrome installation completed."



}

# --- Modern CMake ---
install_modern_cmake() {
	echo "🛠 Checking for modern CMake..."
	# Check if cmake is installed and if it's from kitware. If so, skip.
	if command -v cmake &> /dev/null && apt-cache policy cmake | grep -q "kitware"; then
		echo "✅ Modern CMake from Kitware already installed."
		return
	fi
	
	echo "Installing/upgrading to modern CMake from Kitware..."
	# The repository is now added by setup_repositories
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y cmake || echo "⚠️ CMake install failed. Check for unmet dependencies."

	echo "✅ Modern CMake installation complete."
}
# --- Node.js + NVM ---

install_nodejs_nvm() {
	echo "🕸 Installing Node and npm..."

	export NVM_DIR="$HOME/.nvm"
	mkdir -p "$NVM_DIR"

	# Clone the official NVM repository if not present
	if [ ! -d "$NVM_DIR/.git" ]; then
		git clone "$NVM_REPO_URL" "$NVM_DIR"
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
	grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >>~/.bashrc
	grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.bashrc
	export PATH="$HOME/.npm/bin:$PATH"

	echo "✅ Node.js: $(node -v), npm: $(npm -v)"
	mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"
	cd - # Return to previous directory
}

# --- LLaMA Build ---
build_llama() {
	echo "🦙 Cloning and building llama.cpp..."
	# LLaMA Build
	mkdir -p ~/Downloads/GitHub
	mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"

	if [ ! -d "llama.cpp" ]; then
		git clone "$LLAMA_CPP_REPO_URL"
	else
		cd llama.cpp && git pull --rebase --autostash
		cd .. # Return to ~/Downloads/GitHub
	fi

#We may be building with CUDA after all as Google Collab also has terminal nowadays
#But we need to detect it so leaving off, as it takes hours:
	cmake -S llama.cpp -B llama.cpp/build \
		-DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON \
		-DCMAKE_INSTALL_PREFIX=$HOME/.local &&
		cmake --build llama.cpp/build --config Release -j8 &&
		cmake --install llama.cpp/build
	cd # Return to previous directory

}

# --- Gemini CLI ---
install_gemini_cli() {
	#  NPM_CONFIG_PREFIX=~/.npm npm install -g @google/gemini-cli
	npm install -g @google/gemini-cli
	export NO_BROWSER=1
	# echo "🔮 Run"
}

# Function to install XFCE desktop environment
install_xfce() {
	echo "Installing Xfce desktop environment..."
sudo update	 || {
		echo "Error: Failed to update package lists."
		exit 1
	}
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 desktop-base xscreensaver dbus-x11 task-xfce-desktop firefox-esr || {
		echo "Error: Failed to install Xfce components."
		exit 1
	}
}

# Function to install and configure Chrome Remote Desktop
configure_chrome_remote_desktop() {

#See also the Plasma setup above
	echo "Installing and configuring Chrome Remote Desktop..."
	if [[ ! -f "$DOWNLOAD_DIR/$CHROME_REMOTE_DESKTOP_DEB" ]]; then
		wget -P "$DOWNLOAD_DIR" "$CHROME_REMOTE_DESKTOP_BASE_URL$CHROME_REMOTE_DESKTOP_DEB" || {
			echo "Error: Failed to download Chrome Remote Desktop package."
			return 1
		}
	fi
	
	sudo DEBIAN_FRONTEND=noninteractive  apt-get --fix-broken install -y || {
		echo "Error: Failed to fix broken dependencies after Chrome Remote Desktop install."
		return 1
	}
	sudo DEBIAN_FRONTEND=noninteractive   apt install xserver-xorg-video-dummy  xbase-clients python3-psutil python3-xdg -y 
	sudo usermod -a -G chrome-remote-desktop $USER || {
		echo "Error: Failed to add user to chrome-remote-desktop group."
		return 1
	}
	
		sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$DOWNLOAD_DIR/$CHROME_REMOTE_DESKTOP_DEB" || {
		echo "Error: Failed to install Chrome Remote Desktop package."
		return 1
	}

	sudo DEBIAN_FRONTEND=noninteractive  apt-get --fix-broken install -y || {
		echo "Error: Failed to fix broken dependencies after Chrome Remote Desktop install."
		return 1
	}
	sudo service chrome-remote-desktop restart || {
		echo "Error: Failed to restart Chrome Remote Desktop service."
		return 1
	}
	
	echo 
	echo Now do: 
	1. Go to: https://remotedesktop.google.com/headless and copy the code 
	2. Paste snippet in 'gh' machine. Select pin. 
	3. Then start ' /opt/google/chrome-remote-desktop/start-host --start' 
	4. In https://remotedesktop.google.com/access/session/12ec807f-446d-4a3f-99e4-d10e904b6308
	echo 
}

# Function to install and configure TeamViewer Host
configure_teamviewer() {
	echo "Installing and configuring TeamViewer Host..."
	if command -v teamviewer >/dev/null; then
		if [[ ! -f "$DOWNLOAD_DIR/$TEAMVIEWER_HOST_DEB" ]]; then
			wget -P "$DOWNLOAD_DIR" "$TEAMVIEWER_HOST_BASE_URL$TEAMVIEWER_HOST_DEB" || {
				echo "Error: Failed to download TeamViewer Host package."
				return 1
			}
		fi
		sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$DOWNLOAD_DIR/$TEAMVIEWER_HOST_DEB" || {
			echo "Error: Failed to install TeamViewer Host package."
			return 1
		}
		sudo DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y || {
			echo "Error: Failed to fix broken dependencies after TeamViewer install."
			return 1
		}
		sudo teamviewer --daemon start || {
			echo "Error: Failed to start TeamViewer daemon."
			return 1
		}
		sudo teamviewer --daemon status || { echo "Warning: TeamViewer daemon status check failed."; }
	else
		echo "Skipping TeamViewer installation as 'teamviewer' command not found."
	fi
}

# --- Replit Adaptation ---
replit_adapt() {
	echo "🌀 Adapting setup for Replit environment..."

	# 1️⃣ Core utilities (user-space install)
	pip install --user ffmpeg aria2 youtube-dl

	# 2️⃣ AI/ML tools (user-space)
	python -m ensurepip
	python -m pip install --user -U whisperx numpy torch torchvision torchaudio pip install "huggingface_hub[cli]" tensorflow-cpu jax jaxlib protobuf --extra-index-url https://download.pytorch.org/whl/cpu

	# 3️⃣ Node.js (skip NVM, assume latest Node already present)
	echo "ℹ️ Using Node.js provided by Replit: $(node -v), npm: $(npm -v)"

	# 4️⃣ System/dev tools (nix only, user-space)
	nix profile install \
		nixpkgs#pciutils nixpkgs#cmake nixpkgs#libcurl nixpkgs#libomp \
		nixpkgs#openssl nixpkgs#android-tools nixpkgs#neofetch nixpkgs#geoip nixpkgs#ranger \
		nixpkgs#baobab nixpkgs#firefox nixpkgs#scrcpy

	# 5️⃣ LLaMA build (build in workspace, user-space)
	mkdir -p ~/Downloads/GitHub && mkdir -p "$SRC_DIR"
	cd "$SRC_DIR"
	git clone https://github.com/ggml-org/llama.cpp || echo "⚠️ llama.cpp exists, skipping clone"
	cd llama.cpp
	cmake . -B build -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=OFF -DLLAMA_CURL=ON
	cmake --build build --config Release -j --clean-first --target llama-cli llama-gguf-split
	cd ~/ # return to home

	# 6️⃣ Skip XRDP, sudo-only commands, systemd services, /opt mounts
	echo "ℹ️ Skipping XRDP, sudo, and /opt operations on Replit."

	echo "✅ Replit adaptation complete."
}

# --- Sysinfo ---
display_system_info() {
	echo "📟 System Info:"
	#cpufetch
	#No logo:
	cpufetch --logo-short |
		sed -E 's/\x1b\[[0-9;]*m//g' |
		sed -E ':a; s/#[^#]*#//g; ta; s/#//g; s/^[^[:alnum:]]+//; /^[[:space:]]*$/d'

	echo Trying: 'peakperf  -r 1 -w1'. It fails on GitHub Spaces, so then add: '-b ice_lake' or like, see also 'peakperf --help' then.

	alias peakperf="peakperf  -r 1 -w1 || peakperf  -r 1 -w1 -b ice_lake"

	peakperf -r 1 -w1 || peakperf -r 1 -w1 -b ice_lake
	#    neofetch --off || true
	fastfetch -l none

	curl -s https://ipinfo.io/ip || echo "⚠️ IP fetch failed."

}

echo
echo "📌 Starting Ubuntu setup..."
echo "Version 2.8.5"

# Check for marker file to prevent re-execution

MARKER_FILE="~/.installed_basic_set_1"  # Marker file in HOME directory
echo "Checking via this marker: $MARKER_FILE if this script has been executed here..."

if [ -f "$MARKER_FILE" ]; then
	echo "✅ Script already executed. Remove the marker if you want to rerun it. Exiting."
	exit 0
fi

echo Perform initial dependency checks ...
check_dependencies

echo We configure_system_resources ...

configure_system_resources

echo "Install early the current CMake, for any builds that require it"
install_modern_cmake

echo "System and dev tools (depends on dependencies and CMake)"
install_system_tools

#Skipping it for a while:
#install_nodejs_nvm

echo AI tools ...
install_ai_tools

echo "LLaMA build (depends on modern CMake and system dev tools)"
build_llama

echo "Gemini CLI to talk to Gemini AI..."
install_gemini_cli

echo "Setting up the Remote Desktop stuff  ... "
# Desktop Environment Setup
#install_xfce
configure_chrome_remote_desktop
#configure_teamviewer
configure_xrdp || echo "⚠️ XRDP setup skipped (non-systemd system)."

configure_persistent_environment

echo "Display system info and performance at the end"
display_system_info

echo
echo "We are in $(pwd)."
echo "Changing the status so that the script has been fully executed, via this marker: $MARKER_FILE"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"

touch $MARKER_FILE

echo "✅ Basic Ubuntu setup complete."
