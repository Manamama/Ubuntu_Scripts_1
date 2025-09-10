# Description: This function automates the process of connecting to a GitHub Codespace,
#              setting up necessary local mounts, and initiating an interactive SSH session.
#              It uses the Codespace's native SSH daemon for SFTP, mounting the workspace
#              locally via rclone FUSE and SSHFS (as a fallback).
#
# Expected Logic Flow:
# 1. List available GitHub Codespaces.
# 2. Allow the user to choose a specific Codespace to connect to.
# 3. Determine the Codespace's workspace path.
# 4. Establish a local port forward to the Codespace's SSH server (port 22).
# 5. Set up or update the rclone remote configuration to use the local port forward.
# 6. Prepare local mount paths for rclone FUSE and SSHFS.
# 7. Mount the Codespace's workspace locally via rclone FUSE.
# 8. Mount the Codespace's workspace locally via SSHFS (as a fallback).
# 9. Initiate an interactive SSH session to the Codespace.
# 10. Provide reminders for stopping the Codespace.
#
# Dependencies:
#   - gh CLI (GitHub CLI)
#   - rclone
#   - sshfs
#   - jq (for JSON parsing)
#   - lolcat (optional, for colored output)
#   - Termux environment (for specific paths like ~/storage/)
#
# Usage:
#   Source this script in your shell:
#   source /path/to/gh_codespace_mount_login.sh
#   Then, call the function:
#   gh_me
gh_me() {
    echo "1️⃣ List codespaces:"
    CODESPACES=$(gh codespace list --json name,state | jq -r '.[] | .name')
    if [ $? -ne 0 ]; then
        echo "❌ Error listing codespaces. Make sure gh CLI is authenticated and codespaces are available." | lolcat
        return 1
    fi
    if [ -z "$CODESPACES" ]; then
        echo "No codespaces found. Please create one first." | lolcat
        return 1
    fi

    echo "Available Codespaces:"
    select CSPACE_NAME in $CODESPACES; do
        if [ -n "$CSPACE_NAME" ]; then
            echo "Selected Codespace: $CSPACE_NAME" | lolcat
            break
        else
            echo "Invalid selection. Please try again." | lolcat
        fi
    done

    echo "2️⃣"
    gh codespace view -c "$CSPACE_NAME"
    if [ $? -ne 0 ]; then
        echo "❌ Error viewing codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    echo "3️⃣ Determine Codespace workspace path"

    WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'pwd' | tr -d '\r\n')
    if [ $? -ne 0 ]; then
        echo "❌ Error getting workspace path from codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    if [[ "$WORKSPACE_PATH" == "/home/codespace" ]]; then
        WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'ls -d /workspaces/* 2>/dev/null | head -n1' | tr -d '\r\n')
        if [ $? -ne 0 ]; then
            echo "❌ Error getting workspace path from /workspaces/ in codespace '$CSPACE_NAME'." | lolcat
            return 1
        fi
    fi
    echo "Workspace path: $WORKSPACE_PATH"

    REMOTE_IP=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no "curl ifconfig.me")
    if [ $? -ne 0 ]; then
        echo "❌ Error getting remote IP from codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    echo "Remote IP (for use by e.g. MiXplorer to map share):"
    echo "REMOTE_IP is: $REMOTE_IP" | lolcat
    echo


REMOTE_PORT=2223
        LOCAL_PORT=2222
    echo "4️⃣ Start local port $LOCAL_PORT forward to Codespace SSH $REMOTE_PORT"
    
    PID_FILE="$HOME/.cache/gh_codespace_forward_${CSPACE_NAME}_${LOCAL_PORT}.pid"

    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null; then
            echo "✅ Port forward already running with PID $OLD_PID. Reusing existing forward." | lolcat
            FORWARD_PID="$OLD_PID"
        else
            echo "Stale PID file found. Cleaning up..." | lolcat
            rm -f "$PID_FILE"
        fi
    fi

    if [ -z "$FORWARD_PID" ]; then
        # Check if port is in use (fallback to netstat for Termux)
        if command -v netstat >/dev/null && netstat -tuln | grep -q ":$LOCAL_PORT\s"; then
            echo "⚠️ Local port $LOCAL_PORT is already in use by another process. Please free it up manually." | lolcat
            return 1
        fi

        echo "Starting port forward (LOCAL_PORT $LOCAL_PORT → REMOTE_PORT 22)"
        gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no -L  $LOCAL_PORT:localhost:$REMOTE_PORT -N &
            FORWARD_PID=$!
        sleep 0.5
        if ! ps -p "$FORWARD_PID" > /dev/null; then
            echo "❌ Port forwarding failed to start (PID $FORWARD_PID)." | lolcat
            return 1
        fi
        echo "$FORWARD_PID" > "$PID_FILE"
        echo "🔌 Port forward started (PID $FORWARD_PID)" | lolcat
    fi

    echo "5️⃣ Setup rclone remote"
    RCLONE_REMOTE="GH_01"
    if ! rclone listremotes | grep -qx "${RCLONE_REMOTE}:"; then
        rclone config create "$RCLONE_REMOTE" sftp \
            host 127.0.0.1 user codespace key_file ~/.ssh/id_rsa port $LOCAL_PORT >/dev/null
    fi
    rclone config update "$RCLONE_REMOTE" host 127.0.0.1 port $LOCAL_PORT >/dev/null

    echo "6️⃣ Prepare mount paths"
    MOUNT_PATH="$HOME/storage/GitHub_Codespace_rclone_$CSPACE_NAME"
    SSHFS_MOUNT="$HOME/storage/GitHub_Codespace_sshfs_$CSPACE_NAME"
    mkdir -p "$MOUNT_PATH" "$SSHFS_MOUNT"
    sudo umount "$MOUNT_PATH" 2>/dev/null
    sudo umount "$SSHFS_MOUNT" 2>/dev/null

    echo "7️⃣ Mount via rclone FUSE if not already mounted"
    if ! mountpoint -q "$MOUNT_PATH"; then
        echo "Mounting Codespace $CSPACE_NAME userspace $WORKSPACE_PATH via rclone on $MOUNT_PATH..."
        sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH" \
            --config ~/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes &
        MOUNT_PID=$!
        sleep 1
        if ! ps -p "$MOUNT_PID" > /dev/null; then
            echo "❌ rclone mount failed to start." | lolcat
            return 1
        fi
    else
        echo "✅ Already mounted at $MOUNT_PATH"
    fi

    echo "8️⃣ SSHFS fallback mount"
    KEY_PATH=~/.ssh/id_rsa
    if ! mountpoint -q "$SSHFS_MOUNT"; then
        echo "Mounting via SSHFS fallback on $SSHFS_MOUNT..."
        sudo sshfs codespace@127.0.0.1:"$WORKSPACE_PATH" "$SSHFS_MOUNT" -p $LOCAL_PORT \
            -oIdentityFile="$KEY_PATH" -oStrictHostKeyChecking=no -o reconnect \
            -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o allow_other
        if [ $? -ne 0 ]; then
            echo "⚠️ SSHFS mount failed, proceeding to SSH session anyway..." | lolcat
        fi
    fi

    echo "9️⃣ Entering the interactive session"
    echo "At end, try to use **gh codespace stop**. By default, Codespaces automatically stops after ~30 minutes of inactivity."
    echo "👉 Starting Codespace SSH session..."
    gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no
    if [ $? -ne 0 ]; then
        echo "❌ Error starting interactive SSH session to codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
}

echo This script does nothing apart from creating a function called gh_me. Source me then. 
