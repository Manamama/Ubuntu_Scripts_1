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

# Check if the active account's token has 'codespace' scope using API
#!/bin/bash
# Check active user and 'codespace' scope using gh auth status -a, no external tools
echo -n "1️⃣  Checking 🔍 the active GitHub user and the OAuth token scopes... : "

gh auth status -a | lolcat
# Get active account output
AUTH_ACTIVE=$(gh auth status -a 2>&1)

# Extract active user from "Logged in" line
while IFS= read -r line; do
  if [[ $line =~ Logged\ in\ to\ github\.com\ account\ ([^ ]*) ]]; then
    ACTIVE_USER=${BASH_REMATCH[1]}
    break
  fi
done <<< "$AUTH_ACTIVE"

# Extract scopes from "Token scopes" line
while IFS= read -r line; do
  if [[ $line =~ Token\ scopes:\ (.*) ]]; then
    ACTIVE_SCOPES=${BASH_REMATCH[1]//\'/} # Remove single quotes
    break
  fi
done <<< "$AUTH_ACTIVE"

# Check if active user was found
if [ -z "$ACTIVE_USER" ]; then
  echo "❌ No active user found. Run 'gh auth login' to authenticate." | lolcat
  return 1
fi

#echo -n "✅ Active user: "
#echo "$ACTIVE_USER" | lolcat

echo Active User must be both : 1. 'ssh' enabled. 2. Scope to codespaces, see: 'gh auth refresh -h github.com -s codespace'

# Check if codespace is in scopes
if [[ ! "$ACTIVE_SCOPES" =~ codespace ]]; then
  echo "❌ Missing 'codespace' scope for '$ACTIVE_USER'. Run 'gh auth refresh -h github.com -s codespace'." | lolcat
  return 1
fi

#echo "✅ User '$ACTIVE_USER' has 'codespace' scope."

    echo " Your 'gh' account has the 'codespace' scope, congrats."
    echo "2️⃣  Select one from the available codespaces:"
    CODESPACES=$(gh codespace list --json name,state | jq -r '.[] | .name')
    if [ $? -ne 0 ]; then
        echo "❌ Error listing codespaces. Make sure gh CLI is authenticated and codespaces are available." | lolcat
        return 1
    fi
    if [ -z "$CODESPACES" ]; then
        echo "No access to codespaces found. Either check your rights (scopes) relating to your codespaces for this account or do create a codespace first." | lolcat
        return 1
    fi

    #echo "Available Codespaces:"
    select CSPACE_NAME in $CODESPACES ; do
        if [ -n "$CSPACE_NAME" ]; then
            #echo "Selected Codespace: $CSPACE_NAME" 
            echo
            break
        else
            echo "Invalid selection. Please try again." | lolcat
        fi
    done

    echo "Codespace details:"
    gh codespace view -c "$CSPACE_NAME" | lolcat
    if [ $? -ne 0 ]; then
        echo "❌ Error viewing codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    echo
    echo -n "3️⃣  Determining the Codespace workspace path... : "

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
    #echo -n "Workspace path: "
    echo "$WORKSPACE_PATH" | lolcat


    echo  "Determining the Codespace remote IP (for use by e.g. MiXplorer to map share) ... : "
# Hide somehow that curl, smth like: 2>/dev/null 
    REMOTE_IP=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no "curl ifconfig.me -s" )
    if [ $? -ne 0 ]; then
        echo "❌ Error getting remote IP from codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    echo -n Remote IP found: 
    echo "$REMOTE_IP" | lolcat
    echo

#Check it via: 'gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'netstat -tuln' ' or similar
        REMOTE_PORT=2222
        LOCAL_PORT=2226
        #Do not use: 
        #KEY_PATH=~/.ssh/id_rsa
        #as it is indeed the default one, for ssh and such in Termux, but GitHub Codespace CLI 'gh' default key filename is: '~/.ssh/codespaces.auto' as private and 'codespaces.auto.pub' as public. So we shall use: 
        KEY_PATH=~/.ssh/codespaces.auto
        #Note that ~/.config/gh/hosts.yml also plays a role: stores the GitHub CLI’s configuration, but not including the OAuth token used for API calls (e.g., gh codespace list, gh codespace ssh). The "codespace rights" (i.e., the codespace scope) are not properties of the SSH key (~/.ssh/codespaces.auto) at all—they belong to the OAuth token used for GitHub CLI API calls. The key never "lacked codespace rights" in either scenario; it's solely for SSH authentication and doesn't interact with scopes. 'gh auth status' shows it: either https or ssh with codespace scope is needed. So run: ' gh auth refresh -h github.com -s codespace' to add that scope. 
        
    echo "4️⃣  Starting the forwarding of the Codespace SSH port: $REMOTE_PORT to the local port: $LOCAL_PORT "
    
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

        echo "Starting port forward (LOCAL_PORT $LOCAL_PORT → REMOTE_PORT $REMOTE_PORT)"
        gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no -L  $LOCAL_PORT:localhost:$REMOTE_PORT -N &
            FORWARD_PID=$!
        sleep 0.5
        if ! ps -p "$FORWARD_PID" > /dev/null; then
            echo "❌ Port forwarding failed to start (PID $FORWARD_PID)." | lolcat
            return 1
        fi
        echo "$FORWARD_PID" > "$PID_FILE"
        echo -n "🔌 Port forward started: "
        echo "(PID $FORWARD_PID)" | lolcat
    fi

    #Chown it, as some sudo changes to root ownership now and then: 

    sudo chown $(whoami):$(whoami)  /home/zezen/.config/rclone/rclone.conf

    echo "5️⃣  Set up or update the configuration of the rclone remote GitHub Codespace record ... :"
    RCLONE_REMOTE="GH_01"
    rclone config update "$RCLONE_REMOTE" host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | lolcat 
    sleep 1 
 if [ $? -ne 0 ]; then
    echo "❌ Failed to create rclone remote '$RCLONE_REMOTE'." | lolcat
    return 1
   
  fi
    #echo "✅ The record of the rclone remote: '$RCLONE_REMOTE' has been updated in configuration."
    echo "6️⃣  Prepare the mount paths: unmount them ... "
    MOUNT_PATH="$HOME/storage/GitHub_Codespace_rclone_$CSPACE_NAME"
    SSHFS_MOUNT="$HOME/storage/GitHub_Codespace_sshfs_$CSPACE_NAME"
    mkdir -p "$MOUNT_PATH" "$SSHFS_MOUNT"
    sudo umount "$MOUNT_PATH" 2>/dev/null
    sudo umount "$SSHFS_MOUNT" 2>/dev/null

    echo -n "7️⃣  Mount the paths via rclone FUSE. "
    if ! mountpoint -q "$MOUNT_PATH"; then
        echo -n "Mounting Codespace" 
        echo  -n $CSPACE_NAME | lolcat 
        echo -n userspace 
        echo -n $WORKSPACE_PATH | lolcat 
        echo -n  via rclone on 
        echo -n $MOUNT_PATH | lolcat
        echo "..."
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
    sleep 1
    echo Checking: "ls $MOUNT_PATH" : 
ls $MOUNT_PATH | lolcat



    if ! mountpoint -q "$SSHFS_MOUNT"; then
        echo -n "8️⃣  Mounting via SSHFS on:"
        echo "$SSHFS_MOUNT..." | lolcat
        sudo sshfs codespace@127.0.0.1:"$WORKSPACE_PATH" "$SSHFS_MOUNT" -p $LOCAL_PORT \
            -oIdentityFile="$KEY_PATH" -oStrictHostKeyChecking=no -o reconnect \
            -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o allow_other | lolcat
        if [ $? -ne 0 ]; then
            echo "⚠️ SSHFS mount failed, proceeding to SSH session anyway..." | lolcat
        fi
    fi

echo Checking: "ls $SSHFS_MOUNT"  :
ls "$SSHFS_MOUNT" | lolcat


    echo "9️⃣  Entering the interactive session"
    echo "FYI: by default, Codespaces automatically stops after ~30 minutes of inactivity and gets deleted after 30 days of not logging in again."
    echo "👉 Starting Codespace SSH session..."
    gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no
    
    #This errors unduly if control C etc: 
: '
    if [ $? -ne 0 ]; then
        echo "❌ Error starting interactive SSH session to codespace '$CSPACE_NAME'." | lolcat
        return 1
    fi
    '
}

echo This script does nothing apart from creating a function called gh_me. Source me then. 
