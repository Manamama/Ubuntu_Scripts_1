#!/usr/bin/env bash
#
# setup/ubuntu_scripts_env.sh
# Single-file: safe to SOURCE from ~/.bashrc; when EXECUTED it will perform
# a one-shot idempotent bind of $PERSISTENT_DEST_BASE/.cache -> $HOME/.cache.
#
# Usage:
# 1) Source safely from ~/.bashrc:
#      source /path/to/setup/ubuntu_scripts_env.sh
#    (this will only export env vars and return quickly)
#
# 2) When you want the bind to happen, run the file (not source):
#      PERSISTENT_DEST_BASE=/path/to/persistent CUR_USER=$(id -un) sudo bash /path/to/setup/ubuntu_scripts_env.sh
#    or as root:
#      PERSISTENT_DEST_BASE=/path/to/persistent CUR_USER=$(id -un) bash /path/to/setup/ubuntu_scripts_env.sh
#
# If /home/.../.cache is already mounted from a different source, the script will skip
# unless you set FORCE_BIND=1 (then it does a lazy unmount and rebind).
#

# -----------------------
# Environment (always runs)
# -----------------------
# PATH
export PATH="$HOME/.local/bin:$HOME/.npm/bin:$HOME/.local/usr/bin:$PATH"

# LD_LIBRARY_PATH (preserve existing)
export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"

# NVM (no errors if absent)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  . "$NVM_DIR/bash_completion"
fi

# Gemini CLI: force headless/no browser
export NO_BROWSER=1

# -------------
# Sourcing check
# -------------
is_sourced() {
  # Returns 0 if script is being sourced, non-zero if executed.
  # Works in bash.
  if [ -n "${BASH_SOURCE:-}" ] && [ "${BASH_SOURCE[0]}" != "$0" ]; then
    return 0
  fi
  return 1
}

# If sourced, do not run mount logic (prevent loops when sourced from ~/.bashrc)
if is_sourced; then
  # silently return to keep shells quiet and fast
  return 0 2>/dev/null || exit 0
fi

# -----------------------
# Executed path (one-shot)
# -----------------------
# Execution-only (performed when you run the file). This portion performs the bind.
CACHE_SRC="${CACHE_SRC:-$HOME/.cache}"

# Require explicit PERSISTENT_DEST_BASE to avoid accidental overrides
if [ -z "${PERSISTENT_DEST_BASE:-}" ]; then
  cat <<EOF >&2
PERSISTENT_DEST_BASE not set. No bind performed.
To perform the bind run (example):
  PERSISTENT_DEST_BASE=/path/to/persistent CUR_USER=\$(id -un) sudo bash "$0"
Or run as root:
  PERSISTENT_DEST_BASE=/path/to/persistent CUR_USER=\$(id -un) bash "$0"
EOF
  exit 0
fi

CACHE_DEST="${PERSISTENT_DEST_BASE%/}/.cache"
CUR_USER="${CUR_USER:-$(id -un)}"

# Choose sudo command (allow interactive password prompt when executing)
if [ "$(id -u)" -eq 0 ]; then
  SUDO_CMD=""
else
  SUDO_CMD="sudo"
fi

# Helper: get current mount source for CACHE_SRC
get_current_src() {
  local target="$1"
  local src=""
  if command -v findmnt >/dev/null 2>&1; then
    src=$(findmnt -n -o SOURCE --target "$target" 2>/dev/null || true)
  fi
  if [ -z "$src" ]; then
    # parse `mount` output: device on mountpoint type ...
    src=$(mount | awk -v m="$target" '$3==m{print $1; exit}')
  fi
  printf '%s' "$src"
}

# Check current mount status
current_src=""
if mountpoint -q "$CACHE_SRC"; then
  current_src=$(get_current_src "$CACHE_SRC")
fi

# Idempotent decision logic
if mountpoint -q "$CACHE_SRC" && [ "$current_src" = "$CACHE_DEST" ]; then
  echo "[SKIP] $CACHE_SRC already bind-mounted from $CACHE_DEST"
  exit 0
fi

if mountpoint -q "$CACHE_SRC" && [ "$current_src" != "$CACHE_DEST" ]; then
  echo "[NOTE] $CACHE_SRC is currently mounted from: ${current_src:-<unknown>}"
  if [ "${FORCE_BIND:-0}" -eq 1 ]; then
    echo "[ACTION] FORCE_BIND=1: lazy-unmounting $CACHE_SRC ..."
    $SUDO_CMD umount -l "$CACHE_SRC" || true
  else
    echo "[ABORT] Not replacing existing mount. If you want to force it, re-run with FORCE_BIND=1."
    echo "Example:"
    echo "  FORCE_BIND=1 PERSISTENT_DEST_BASE=$PERSISTENT_DEST_BASE CUR_USER=$CUR_USER sudo bash $0"
    exit 1
  fi
fi

# Prepare destination
$SUDO_CMD mkdir -p "$CACHE_DEST"
$SUDO_CMD chown "$CUR_USER:$CUR_USER" "$CACHE_DEST" 2>/dev/null || true

# Replace source directory and bind
rm -rf "$CACHE_SRC"
mkdir -p "$CACHE_SRC"

echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
$SUDO_CMD mount --bind "$CACHE_DEST" "$CACHE_SRC"
$SUDO_CMD mount -o remount,rw,exec "$CACHE_SRC"
if mountpoint -q "$CACHE_SRC"; then
  echo "[DONE] Bound with exec: $CACHE_DEST -> $CACHE_SRC"
  exit 0
else
  echo "[ERROR] Bind attempt failed."
  exit 2
fi
