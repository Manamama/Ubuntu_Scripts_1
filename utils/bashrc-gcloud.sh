
# This script configures the shell environment, manages storage (Python site-packages, cache), sets up swap, and initializes a Git repository for Google Cloud and GitHub Codespaces.



export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"

export PATH="$PATH:$HOME/.local/usr/bin:'/$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("BINDIR"))'')
"
mkdir -p "$HOME/.local/var/lib/dpkg"






# And install there for permanence: sudo dpkg --instdir=/home/abovetrans/.local --admindir=/home/abovetrans/.local/var/lib/dpkg --no-triggers -i gotop_v4.2.0_linux_amd64.deb

#You can bind /home, but not advised, as it is a temp, ephemeral folder:
# sudo mount --bind /root/home2 /home


export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$PATH:$HOME/.local/bin
export PATH="$HOME/.npm-global/bin:$PATH"

#!/usr/bin/env bash

# --- Ensure user bin dir ---
mkdir -p "$HOME/.local/bin"
echo "[INFO] Ensured bin dir exists at: $HOME/.local/bin"



CUR_USER=$(whoami)
CUR_HOME="$HOME"

#Checking the OS and naming



PYTHON_LIB=$(python -m site --user-site)

#Asssumes GCloud: 
PERSISTENT_DEST_BASE="/root/home_extended"


if [ -n "$CODESPACE_NAME" ]; then
    echo "[INFO] Detected GitHub Codespace: using /tmp for temporary storage"
    PERSISTENT_DEST_BASE="/tmp"
else

# --- Python site-packages relocation ---

PYTHON_LIB_DEST="${PYTHON_LIB/$HOME/$PERSISTENT_DEST_BASE}"

# Ensure source and destination exist
mkdir -p "$PYTHON_LIB"
sudo mkdir -p "$PYTHON_LIB_DEST"
sudo chown "$CUR_USER:$CUR_USER" "$PYTHON_LIB_DEST"

# Unmount any previous mounts at the source
while mountpoint -q "$PYTHON_LIB"; do
    echo "[RESET] Unmounting $PYTHON_LIB ..."
    sudo umount -l "$PYTHON_LIB"
done

#Wipe the current ones, sic! :
rm -rf $PYTHON_LIB
mkdir -p "$PYTHON_LIB"

# Bind and remount with exec
echo "[ACTION] Binding $PYTHON_LIB_DEST -> $PYTHON_LIB ..."
sudo mount --bind "$PYTHON_LIB_DEST" "$PYTHON_LIB"
sudo mount -o remount,rw,exec "$PYTHON_LIB"
echo "[DONE] Bound with exec: $PYTHON_LIB_DEST -> $PYTHON_LIB"

fi

# --- Cache relocation , ver. 1.1---


CACHE_SRC="$CUR_HOME/.cache"
CACHE_DEST="$PERSISTENT_DEST_BASE/.cache"

mkdir -p "$CACHE_SRC"
sudo mkdir -p "$CACHE_DEST"
sudo chown "$CUR_USER:$CUR_USER" "$CACHE_DEST"

# Reset stacked mounts if any
while mountpoint -q "$CACHE_SRC"; do
    echo "[RESET] Unmounting $CACHE_SRC ..."
    sudo umount -l "$CACHE_SRC"
done

#Wipe the current ones, sic! :
rm -rf $CACHE_SRC
mkdir -p "$CACHE_SRC"


# Bind and remount with exec
echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
sudo mount --bind "$CACHE_DEST" "$CACHE_SRC"
sudo mount -o remount,rw,exec "$CACHE_SRC"
echo "[DONE] Bound with exec: $CACHE_DEST -> $CACHE_SRC"

# --- Sanity check ---
echo
echo "Final mount state:"
mount | grep /home

# swap make , for Github mostly
# 1️⃣ Create a 16 GB swap file
sudo fallocate -l 16G /tmp/swapfile

# 2️⃣ Restrict permissions
sudo chmod 600 /tmp/swapfile

# 3️⃣ Set up the swap area
sudo mkswap /tmp/swapfile

# 4️⃣ Enable the swap
sudo swapon /tmp/swapfile

# 5️⃣ Verify
swapon --show
free -h

echo
echo "Space free on /home or /workspace (on the persistent thus too limited storage):" 
df -h | grep Use%
#if GCloud or like:
df -h | grep /home
#if GitHub Workspace or like:
df -h | grep /workspace

# --- End of relocation ---

# Note: For persistent mounts, consider adding it to /etc/fstab. Also maybe: 
# sudo chown -R abovetrans:abovetrans $CACHE_DEST

# The 'exec' option is crucial here. Without it, shared libraries (.so files) # and other executables in $LIB_SRC cannot be loaded or run. This was # causing the 'failed to map segment from shared object' error when running # applications like whisperx that rely on libraries in this directory


# this below is nonsense that it's not the cause of the problem of GCloud shell running out of space, only the mounts above which are hiding the real files left behind. The stragglers is the problem. Here we are leaving it for legacy reasons.
# --- Overlayfs /home ghost usage check ---
# This warns the user if ephemeral overlay upper-layer usage is high


mkdir -p $HOME/Downloads/GitHub 

#idempotent init run: 

REPO_URL="https://github.com/Manamama/Ubuntu_Scripts_1/"
REPO_DIR="$HOME/Downloads/GitHub/Ubuntu_Scripts_1"
INSTALL_SCRIPT="$REPO_DIR/install_basic_ubuntu_set_1.sh"
MARKER_FILE="$REPO_DIR/.installed_basic_set_1"

# --- Ensure repo directory exists ---
mkdir -p "$(dirname "$REPO_DIR")"

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[ACTION] Cloning repo into $REPO_DIR ..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "[ACTION] Updating repo in $REPO_DIR ..."
    cd "$REPO_DIR" && git pull --rebase --autostash
fi

# --- Run install script if marker missing ---
if [ ! -f "$MARKER_FILE" ]; then
    echo "[ACTION] Running install script: $INSTALL_SCRIPT"
    bash "$INSTALL_SCRIPT"
   
else
    echo "[SKIP] Install script already run (marker exists: $MARKER_FILE)"
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

echo ver. 2.9.1
echo 

