#!/bin/bash
gh_me() {
  # [Previous code unchanged: scope check, Codespace selection, WORKSPACE_PATH, REMOTE_IP]
  echo "🔍 Checking active user and OAuth token scopes..."
  AUTH_ACTIVE=$(gh auth status -a 2>&1)
  while IFS= read -r line; do
    if [[ $line =~ Logged\ in\ to\ github\.com\ account\ ([^ ]*) ]]; then
      ACTIVE_USER=${BASH_REMATCH[1]}
      break
    fi
  done <<< "$AUTH_ACTIVE"
  while IFS= read -r line; do
    if [[ $line =~ Token\ scopes:\ (.*) ]]; then
      ACTIVE_SCOPES=${BASH_REMATCH[1]//\'/}
      break
    fi
  done <<< "$AUTH_ACTIVE"
  if [ -z "$ACTIVE_USER" ]; then
    echo "❌ No active user found. Run 'gh auth login' to authenticate." | lolcat
    return 1
  fi
  echo "✅ Active user: $ACTIVE_USER"
  if [[ ! "$ACTIVE_SCOPES" =~ codespace ]]; then
    echo "❌ Missing 'codespace' scope for '$ACTIVE_USER'. Run 'gh auth refresh -h github.com -s codespace'." | lolcat
    return 1
  fi
  echo "1️⃣ Your 'gh' account has the 'codespace' scope, congrats. We are listing available codespaces:"
  CODESPACES=$(gh codespace list --json name,state | jq -r '.[] | .name')
  if [ $? -ne 0 ]; then
    echo "❌ Error listing codespaces. Make sure gh CLI is authenticated and codespaces are available." | lolcat
    return 1
  fi
  if [ -z "$CODESPACES" ]; then
    echo "No access to codespaces found. Either check your rights (scopes) relating to your codespaces for this account or do create a codespace first." | lolcat
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
  KEY_PATH=~/.ssh/codespaces.auto
  RCLONE_REMOTE="GH_01"

  echo "4️⃣ Check SSH key and rclone remote"
  if [ ! -f "$KEY_PATH" ] || [ ! -r "$KEY_PATH" ]; then
    echo "❌ SSH key file '$KEY_PATH' not found or not readable. Run 'gh auth login --git-protocol ssh' to generate it." | lolcat
    return 1
  fi
  rclone config update "$RCLONE_REMOTE" host 127.0.0.1 user codespace key_file "$KEY_PATH" port 22 >/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Failed to update rclone remote '$RCLONE_REMOTE'. Recreating it..." | lolcat
    rclone config delete "$RCLONE_REMOTE" >/dev/null 2>&1
    rclone config create "$RCLONE_REMOTE" sftp host 127.0.0.1 user codespace key_file "$KEY_PATH" port 22 >/dev/null
    if [ $? -ne 0 ]; then
      echo "❌ Failed to create rclone remote '$RCLONE_REMOTE'." | lolcat
      return 1
    fi
  fi
  echo "✅ rclone remote '$RCLONE_REMOTE' configured."

  echo "5️⃣ Prepare mount paths"
  MOUNT_PATH="$HOME/storage/GitHub_Codespace_rclone_$CSPACE_NAME"
  SSHFS_MOUNT="$HOME/storage/GitHub_Codespace_sshfs_$CSPACE_NAME"
  mkdir -p "$MOUNT_PATH" "$SSHFS_MOUNT"
  sudo umount "$MOUNT_PATH" 2>/dev/null
  sudo umount "$SSHFS_MOUNT" 2>/dev/null

  echo "6️⃣ Mount via rclone FUSE"
  if ! mountpoint -q "$MOUNT_PATH"; then
    echo "Mounting Codespace $CSPACE_NAME userspace $WORKSPACE_PATH via rclone on $MOUNT_PATH..."
    # Use gh as SSH proxy
    sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH" \
      --config ~/.config/rclone/rclone.conf \
      --allow-other \
      --vfs-cache-mode writes \
      --ssh-exec "gh codespace ssh -c \"$CSPACE_NAME\" --" &
    MOUNT_PID=$!
    sleep 2
    if ! ps -p "$MOUNT_PID" > /dev/null || ! mountpoint -q "$MOUNT_PATH"; then
      echo "❌ rclone mount failed to start (PID $MOUNT_PID) or mountpoint not active. Check rclone logs." | lolcat
      kill $MOUNT_PID 2>/dev/null
      return 1
    fi
    echo "✅ rclone mount started (PID $MOUNT_PID)."
  else
    echo "✅ Already mounted at $MOUNT_PATH."
  fi

  echo "7️⃣ SSHFS fallback mount"
  if ! mountpoint -q "$SSHFS_MOUNT"; then
    echo "Mounting via SSHFS fallback on $SSHFS_MOUNT..."
    sudo sshfs codespace@localhost:"$WORKSPACE_PATH" "$SSHFS_MOUNT" \
      -p 22 \
      -oIdentityFile="$KEY_PATH" \
      -oStrictHostKeyChecking=no \
      -o reconnect \
      -o ServerAliveInterval=5 \
      -o ServerAliveCountMax=3 \
      -o TCPKeepAlive=yes \
      -o allow_other \
      -o ProxyCommand="gh codespace ssh -c \"$CSPACE_NAME\" -- -o ForwardX11=no" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "⚠️ SSHFS mount failed, proceeding to SSH session anyway..." | lolcat
    else
      echo "✅ SSHFS mount started."
    fi
  else
    echo "✅ Already mounted at $SSHFS_MOUNT."
  fi

  echo "8️⃣ Entering the interactive session"
  echo "At end, try to use **gh codespace stop**. By default, Codespaces automatically stops after ~30 minutes of inactivity."
  echo "👉 Starting Codespace SSH session..."
  gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no
  if [ $? -ne 0 ]; then
    echo "❌ Error starting interactive SSH session to codespace '$CSPACE_NAME'." | lolcat
    return 1
  fi
}
echo This script does nothing apart from creating a function called gh_me. Source me then.

