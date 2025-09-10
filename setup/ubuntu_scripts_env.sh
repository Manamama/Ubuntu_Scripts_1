#!/usr/bin/env bash

# Environment
export PATH="$HOME/.local/bin:$HOME/.npm/bin:$HOME/.local/usr/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export NO_BROWSER=1

# Determine persistent destination
if [ -n "${CODESPACE_NAME-}" ]; then
  PERSISTENT_DEST_BASE="/tmp"
elif [ -z "${PERSISTENT_DEST_BASE-}" ]; then
  echo "[ABORT] PERSISTENT_DEST_BASE not set."
  return 1 2>/dev/null || exit 1
fi

CACHE_SRC="$HOME/.cache"
CACHE_DEST="${PERSISTENT_DEST_BASE%/}/.cache"
CUR_USER="${CUR_USER:-$(id -un)}"
SUDO_CMD=""
[ "$(id -u)" -ne 0 ] && SUDO_CMD="sudo"

# Check if already mounted from correct source
already_bound=0
if mountpoint -q "$CACHE_SRC"; then
  mounted_src=$(mount | awk -v target="$CACHE_SRC" '$3==target{print $1; exit}')
  [ "$mounted_src" = "$CACHE_DEST" ] && already_bound=1
fi

if [ "$already_bound" -eq 1 ]; then
  echo "[SKIP] $CACHE_SRC already bound to $CACHE_DEST"
else
  # If mounted from a different source, unmount
  mountpoint -q "$CACHE_SRC" && $SUDO_CMD umount -l "$CACHE_SRC" || true

  # Prepare directories
  $SUDO_CMD mkdir -p "$CACHE_DEST"
  $SUDO_CMD chown "$CUR_USER:$CUR_USER" "$CACHE_DEST" 2>/dev/null || true

  rm -rf "$CACHE_SRC"
  mkdir -p "$CACHE_SRC"

  # Bind
  echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
  $SUDO_CMD mount --bind "$CACHE_DEST" "$CACHE_SRC"
  $SUDO_CMD mount -o remount,rw,exec "$CACHE_SRC"

  mountpoint -q "$CACHE_SRC" && echo "[DONE] Bound: $CACHE_DEST -> $CACHE_SRC" || echo "[ERROR] Bind failed."
fi
