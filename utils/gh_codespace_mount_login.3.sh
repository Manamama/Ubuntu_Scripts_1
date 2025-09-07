# Description: This function automates the process of connecting to a GitHub Codespace,
#              setting up necessary local mounts, and initiating an interactive SSH session.
#              It is designed to provide local filesystem access to a remote Codespace
#              environment, similar to how gcloud_mount_login.sh works for Google Cloud Shell.
#
# Expected Logic Flow:
# 1. List available GitHub Codespaces.
# 2. Allow the user to choose a specific Codespace to connect to (automated choice).
# 3. Determine the Codespace's workspace path.
# 4. Start an rclone SFTP server within the selected Codespace.
# 5. Establish a local port forward to tunnel connections to the Codespace's rclone SFTP server.
# 6. Set up or update the rclone remote configuration to use the local port forward.
# 7. Prepare local mount paths for rclone FUSE and SSHFS.
# 8. Mount the Codespace's workspace locally via rclone FUSE.
# 9. Mount the Codespace's workspace locally via SSHFS (as a fallback or alternative).
# 10. Initiate an interactive SSH session to the Codespace.
# 11. Provide reminders for stopping the Codespace.
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

    WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- 'pwd' | tr -d '\r\n')
    if [ $? -ne 0 ]; then
        echo "❌ Error getting workspace path from codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    if [[ "$WORKSPACE_PATH" == "/home/codespace" ]]; then
        WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- 'ls -d /workspaces/* 2>/dev/null | head -n1' | tr -d '\r\n')
        if [ $? -ne 0 ]; then
            echo "❌ Error getting workspace path from /workspaces/ in codespace '$CSPACE_NAME'." | lolcat
            return 1
        fi
    fi
    echo "Workspace path: $WORKSPACE_PATH"

    REMOTE_IP=$(gh codespace ssh -c "$CSPACE_NAME" -- "curl ifconfig.me")
    if [ $? -ne 0 ]; then
        echo "❌ Error getting remote IP from codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    echo "Remote IP (for use by e.g. MiXplorer to map share):"
    echo "REMOTE_IP is: $REMOTE_IP" | lolcat
    echo

    echo "4️⃣ Start rclone SFTP server"
    REMOTE_PORT=2223
    gh codespace ssh -c "$CSPACE_NAME" -- "nohup rclone serve sftp $WORKSPACE_PATH --addr :$REMOTE_PORT >/dev/null 2>&1 &"
    if [ $? -ne 0 ]; then
        echo "❌ Error starting rclone SFTP server in codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    LOCAL_PORT=2222
    PID_FILE="/tmp/gh_codespace_forward_${CSPACE_NAME}_${LOCAL_PORT}.pid"

    echo "5️⃣ Check and manage local port forward"

    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null; then
            echo "✅ Port forward already running with PID $OLD_PID. Reusing existing forward." | lolcat
            FORWARD_PID="$OLD_PID"
        else
            echo "Stale PID file found. Cleaning up..." | lolcat
            rm "$PID_FILE"
        fi
    fi

    if [ -z "$FORWARD_PID" ]; then
        # Check if port is in use by another process
        if lsof -tiTCP:"$LOCAL_PORT" -sTCP:LISTEN > /dev/null; then
            echo "⚠️ Local port $LOCAL_PORT is already in use by another process. Please free it up manually." | lolcat
            return 1
        fi

        echo "6️⃣ Start fresh port forward (LOCAL_PORT → REMOTE_PORT)"
        gh codespace ssh -c "$CSPACE_NAME" -- -L $LOCAL_PORT:localhost:$REMOTE_PORT -N &
        FORWARD_PID=$!
        echo "$FORWARD_PID" > "$PID_FILE"
        sleep 0.5
        echo "🔌 Port forward started (PID $FORWARD_PID)" | lolcat
    fi
    echo "7️⃣ Setup rclone remote"
    RCLONE_REMOTE="GH_01"
    if ! rclone listremotes | grep -qx "${RCLONE_REMOTE}:"; then
        rclone config create "$RCLONE_REMOTE" sftp \
            host 127.0.0.1 user codespace key_file ~/.ssh/id_rsa port $LOCAL_PORT >/dev/null
    fi
    rclone config update "$RCLONE_REMOTE" host 127.0.0.1 port $LOCAL_PORT >/dev/null

    echo "8️⃣ Prepare mount paths"
    MOUNT_PATH=~/storage/GitHub_Codespace_rclone_$CSPACE_NAME
    SSHFS_MOUNT=~/storage/GitHub_Codespace_sshfs_$CSPACE_NAME
    mkdir -p "$MOUNT_PATH" "$SSHFS_MOUNT"
    sudo umount "$MOUNT_PATH" 2>/dev/null
    sudo umount "$SSHFS_MOUNT" 2>/dev/null
    echo "9️⃣ Mount via rclone FUSE if not already mounted"
    if ! mountpoint -q "$MOUNT_PATH"; then
        echo "Mounting Codespace $CSPACE_NAME userspace $WORKSPACE_PATH via rclone on $MOUNT_PATH..."
        sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH" \
            --config ~/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes &
    else
        echo "✅ Already mounted at $MOUNT_PATH"
    fi

    echo "🔟 SSHFS fallback mount"
    KEY_PATH=~/.ssh/id_rsa
    if ! mountpoint -q "$SSHFS_MOUNT"; then
        echo "Mounting via SSHFS fallback on $SSHFS_MOUNT..."
        sudo sshfs codespace@127.0.0.1:"$WORKSPACE_PATH" "$SSHFS_MOUNT" -p $LOCAL_PORT \
            -oIdentityFile="$KEY_PATH" -oStrictHostKeyChecking=no -o reconnect \
            -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o allow_other
    fi

    echo "1️⃣1️⃣ Entering the interactive session"
    echo "At end do try to use **gh codespace stop**. By default, Codespaces automatically stops after ~30 minutes of inactivity."
    echo "👉 Starting Codespace SSH session..."
    gh codespace ssh -c "$CSPACE_NAME"
    if [ $? -ne 0 ]; then
        echo "❌ Error starting interactive SSH session to codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
}