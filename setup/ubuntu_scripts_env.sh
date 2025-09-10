# ================================
# Ubuntu_Scripts_1 environment setup
# ================================

# Add local bin directories to PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
export PATH="$HOME/.local/usr/bin:$PATH"

# Add local lib directories to LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$HOME/.local/lib:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Gemini CLI: force no browser
export NO_BROWSER=1

# --- Cache relocation (optional) ---
CACHE_SRC="$HOME/.cache"
CACHE_DEST="$PERSISTENT_DEST_BASE/.cache"

# Only try if CACHE_DEST is defined
if [ -n "$PERSISTENT_DEST_BASE" ]; then
    mkdir -p "$CACHE_DEST"
    sudo chown "$CUR_USER:$CUR_USER" "$CACHE_DEST" 2>/dev/null || true

    # Bind only if not already bound to CACHE_DEST
    if ! mount | grep -qE "^$CACHE_DEST on $CACHE_SRC type"; then
        echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
        rm -rf "$CACHE_SRC"
        mkdir -p "$CACHE_SRC"
        sudo mount --bind "$CACHE_DEST" "$CACHE_SRC"
        sudo mount -o remount,rw,exec "$CACHE_SRC"
        echo "[DONE] Bound with exec: $CACHE_DEST -> $CACHE_SRC"
    else
        echo "[SKIP] $CACHE_SRC already bound to $CACHE_DEST"
    fi
fi
