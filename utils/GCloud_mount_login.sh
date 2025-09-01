
: '

gh_me() {
    # 1️⃣ Authenticate GH CLI
    #gh auth login --with-token < ~/.ghtoken1

    # 2️⃣ Pick first available Codespace
    CSPACE_NAME=$(gh codespace list --json name,state \
        | jq -r '.[] | select(.state=="Available") | .name' \
        | head -n1)
    [[ -z "$CSPACE_NAME" ]] && { echo "❌ No Available Codespace"; return 1; }
    echo -n "✅ Using Codespace:"

echo " $CSPACE_NAME" | lolcat
gh codespace view
    # 3️⃣ Determine Codespace workspace path
    WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- 'pwd' | tr -d '\r\n')
    if [[ "$WORKSPACE_PATH" == "/home/codespace" ]]; then
        WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- 'ls -d /workspaces/* 2>/dev/null | head -n1' | tr -d '\r\n')
    fi
    echo "Workspace path: $WORKSPACE_PATH



 

REMOTE_IP=$(gh codespace ssh -c "$CSPACE_NAME" curl ifconfig.me)
echo Remote IP (for use my e.g. MiXplorer to map share): 
echo REMOTE_IP is: | lolcat
echo

 
    # 4️⃣ Start rclone SFTP server in Codespace on REMOTE_PORT
    REMOTE_PORT=2223
    LOCAL_PORT=2222
    gh codespace ssh -c "$CSPACE_NAME" -- "nohup rclone serve sftp $WORKSPACE_PATH --addr :$REMOTE_PORT >/dev/null 2>&1 &"

    # 5️⃣ Kill any previous local port forward
    EXISTING_PID=$(lsof -tiTCP:"$LOCAL_PORT" -sTCP:LISTEN)
    if [[ -n "$EXISTING_PID" ]]; then
        echo "⚠️ Local port $LOCAL_PORT already in use, killing PID $EXISTING_PID"
        kill "$EXISTING_PID"
        sleep 0.5
    fi

    # 6️⃣ Start fresh port forward (LOCAL_PORT → REMOTE_PORT)
    gh codespace ssh -c "$CSPACE_NAME" -- -L $LOCAL_PORT:localhost:$REMOTE_PORT -N &
    FORWARD_PID=$!
    sleep 0.5
    echo "🔌 Port forward started (PID $FORWARD_PID)"

    # 7️⃣ Setup rclone remote silently
    RCLONE_REMOTE="GH_01"
    if ! rclone listremotes | grep -qx "${RCLONE_REMOTE}:"; then
        rclone config create "$RCLONE_REMOTE" sftp \
            host 127.0.0.1 user codespace key_file ~/.ssh/id_rsa port $LOCAL_PORT >/dev/null
    fi
    rclone config update "$RCLONE_REMOTE" host 127.0.0.1 port $LOCAL_PORT >/dev/null

    # 8️⃣ Prepare mount paths
    MOUNT_PATH=~/storage/GH_01_rclone
    SSHFS_MOUNT=~/storage/GH_01_sshfs
    mkdir -p "$MOUNT_PATH" "$SSHFS_MOUNT"
sudo umount $MOUNT_PATH
sudo umount $SSHFS_MOUNT
    # 9️⃣ Mount via rclone FUSE if not already mounted
    if ! mountpoint -q "$MOUNT_PATH"; then
        echo "Mounting Codespace userspace $WORKSPACE_PATH via rclone on $MOUNT_PATH..."
        sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH" \
            --config ~/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes &
    else
        echo "✅ Already mounted at $MOUNT_PATH"
    fi

    # 🔟 SSHFS fallback mount
    KEY_PATH=~/.ssh/id_rsa
    if ! mountpoint -q "$SSHFS_MOUNT"; then
        #echo "Mounting via SSHFS fallback on $SSHFS_MOUNT..."
        #sudo sshfs codespace@127.0.0.1:"$WORKSPACE_PATH" "$SSHFS_MOUNT" -p $LOCAL_PORT \
            -oIdentityFile="$KEY_PATH" -oStrictHostKeyChecking=no -o reconnect \
            -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o allow_other
    fi

    # 1️⃣1️⃣ Interactive session
    echo "At end do use **gh codespace stop**. By default, Codespaces automatically stop after ~30 minutes of inactivity."
    echo "👉 Starting Codespace SSH session..."
    gh codespace ssh -c "$CSPACE_NAME"
}

'
