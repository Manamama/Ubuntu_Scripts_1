#!/bin/bash
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
#   - $FILTER (optional, for colored output)
#   - Termux environment (for specific paths like $HOME/storage/)
#
# Usage:
#   Source this script in your shell:
#   source /path/to/gh_codespace_mount_login.sh
#   Then, call the function:
#   gh_me
gh_me() {
#!/bin/bash
# Check if the active account's token has 'codespace' scope using API

# Check active user and 'codespace' scope using gh auth status -a, no external tools


if command -v $FILTER >/dev/null; then
    FILTER="lolcat"
else
    FILTER="cat"
fi


echo Mounting shares and logging into GitHub Codespaces, paranoid edition, version 5.1.2
#Changed ssh mechanism to port forwards 
echo 


        #Do not use in Ubuntu: 
        #KEY_PATH=$HOME/.ssh/id_rsa
        #as it is indeed the default one, for ssh and such in Termux, but GitHub Codespace CLI 'gh' default key filename is: '$HOME/.ssh/codespaces.auto' as private and 'codespaces.auto.pub' as public. So we shall use: 
        #KEY_PATH=$HOME/.ssh/codespaces.auto

echo -n "1️⃣  Checking the OS: " 
        
    if [ -n "$TERMUX__HOME" ]; then
    echo -n "📲  We are in Termux.  " 
        KEY_PATH="$HOME/.ssh/id_rsa"
    else
        echo -n We are not in Termux. 
        KEY_PATH="$HOME/.ssh/codespaces.auto"
    fi
echo -n So we are using this KEY_PATH with ssh keys: 
echo $KEY_PATH | $FILTER
echo 

echo -n "2️⃣  Checking 🔍 the active GitHub user and the OAuth token scopes... : "

gh auth status -a | $FILTER
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
  echo "❌ No active user found. Run 'gh auth login' to authenticate." | $FILTER
  return 1
fi

#echo -n "✅ Active user: "
#echo "$ACTIVE_USER" | $FILTER

echo The Active User account above must be both : 1. Git operations protocol: 'ssh' enabled. 2. Have Token scopes: 'codespaces', see: 'gh auth refresh -h github.com -s codespace'

# Check if codespace is in scopes
if [[ ! "$ACTIVE_SCOPES" =~ codespace ]]; then
  echo "❌ Missing 'codespace' scope for '$ACTIVE_USER'. Runing: 'gh auth refresh -h github.com -s codespace'." | $FILTER
  gh auth refresh -h github.com -s codespace
  #return 1
fi

#echo "✅ User '$ACTIVE_USER' has 'codespace' scope."

    echo " Your 'gh' account has the 'codespace' scope, congrats."
    echo "⇛  Select one from the available codespaces:"
    CODESPACES=$(gh codespace list --json name,state | jq -r '.[] | .name')
    if [ $? -ne 0 ]; then
        echo "❌ Error listing codespaces. Make sure gh CLI is authenticated and codespaces are available." | $FILTER
        return 1
    fi
    if [ -z "$CODESPACES" ]; then
        echo "No access to codespaces found. Either check your rights (scopes) relating to your codespaces for this account or do create a codespace first." | $FILTER
        return 1
    fi

    #echo "Available Codespaces:"
    select CSPACE_NAME in $CODESPACES ; do
        if [ -n "$CSPACE_NAME" ]; then
            #echo "Selected Codespace: $CSPACE_NAME" 
            echo
            break
        else
            echo "Invalid selection. Please try again." | $FILTER
        fi
    done

    echo "Codespace details:"
    gh codespace view -c "$CSPACE_NAME" | $FILTER
    if [ $? -ne 0 ]; then
        echo "❌ Error viewing codespace '$CSPACE_NAME'." | $FILTER
        #return 1
    fi
    echo
    echo -n "3️⃣  Determining the Codespace workspace path... : "

    WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'pwd' | tr -d '\r\n')
    if [ $? -ne 0 ]; then
        echo "❌ Error getting workspace path from codespace '$CSPACE_NAME'." | $FILTER
        #return 1
    fi
    if [[ "$WORKSPACE_PATH" == "/home/codespace" ]]; then
        WORKSPACE_PATH=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'ls -d /workspaces/* 2>/dev/null | head -n1' | tr -d '\r\n')
        if [ $? -ne 0 ]; then
            echo "❌ Error getting workspace path from /workspaces/ in codespace '$CSPACE_NAME'." | $FILTER
            #return 1
        fi
    fi
    #echo -n "Workspace path: "
    echo "$WORKSPACE_PATH" | $FILTER


    echo  "Determining the Codespace remote IP (for use by e.g. MiXplorer to map share) ... : "
# Hide somehow that curl, smth like: 2>/dev/null 
    REMOTE_IP=$(gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no "curl ifconfig.me -s" )
    if [ $? -ne 0 ]; then
        echo "❌ Error getting remote IP from codespace '$CSPACE_NAME'." | $FILTER
        return 1
    fi
    echo -n Remote IP found: 
    echo "$REMOTE_IP" | $FILTER
    echo

#Check the remote one via: 'gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no 'netstat -tuln' ' or similar
        REMOTE_PORT=2222
        
        #Local one, we start with: 
        LOCAL_PORT=3222
        
        
# Theory: $HOME/.ssh/known_hosts has all IP:ports combination 


        #Note that $HOME/.config/gh/hosts.yml also plays a role: stores the GitHub CLI’s configuration, but not including the OAuth token used for API calls (e.g., gh codespace list, gh codespace ssh). The "codespace rights" (i.e., the codespace scope) are not properties of the SSH key ($HOME/.ssh/codespaces.auto) at all—they belong to the OAuth token used for GitHub CLI API calls. The key never "lacked codespace rights" in either scenario; it's solely for SSH authentication and doesn't interact with scopes. 'gh auth status' shows it: either https or ssh with codespace scope is needed. So run: ' gh auth refresh -h github.com -s codespace' to add that scope. 
        
        #NB. Upon reviewing the GitHub CLI documentation, it's confirmed that the gh codespace ssh command automatically generates a new SSH key pair if one doesn't already exist in the $HOME/.ssh directory. This process is not conditional upon the presence of the codespaces.auto file; rather, it ensures that a valid key pair is available for authentication. 
        #that’s the “Sally Anne” trap in action. I had two mental assumptions baked in:

#Key dependency assumption: I assumed that if the codespaces.auto private key file was missing, gh codespace ssh would fail. In other words, the SSH handshake wouldn’t even start without the pre-existing key. That’s the “Anne thinks Sally still has the marble” error: I imagined the system would behave like a human watching a hidden key.

#No automatic key regeneration assumption: Even if it somehow connected, I assumed gh would never silently recreate the key. I treated SSH keys as immutable artifacts, only generated manually by the user. I didn’t account for the CLI’s internal logic to always ensure credentials exist—even if it has to forge them on-the-fly.

# the gh codespace ssh command does not strictly depend on the local $HOME/.ssh/codespaces.auto key for establishing a connection to the Codespace. Instead, it uses the GitHub API and the OAuth token of the active account (Manamama-Gemini-Cloud-AI-01, with codespace scope) to authenticate and negotiate the SSH session. The gh CLI manages the connection by leveraging cached session material or API-driven authentication
        echo -n "4️⃣ Checking/starting forwarding of Codespace SSH port: $REMOTE_PORT to local port: "
        echo "$LOCAL_PORT" | $FILTER
echo "(Some steps require sudo privileges. You may be prompted for your password.)" 

#This does not work! Do not use any of these versions: 
#PORTS_JSON=$(gh codespace ports -c "$CSPACE_NAME" --json sourcePort)

#!/usr/bin/env bash
# Usage: REMOTE_PORT=2222 CSPACE_NAME=curly-funicular ./forward.sh

DEFAULT_LOCAL=3222

# 1️⃣ Check if remote port is already forwarded locally

echo "The processes related to 'codespace' here:" 
 ps -eo pid,args     | grep "codespace" 
 echo 
 
LOCAL_PORT=$(ps -eo pid,args \
    | grep "[g]h codespace ports forward ${REMOTE_PORT}:" \
    | sed -n "s/.*${REMOTE_PORT}:\([0-9]\+\).*/\1/p" \
    | head -n1)



# 2️⃣ If unbound, find a free local port and bind once
if [ -z "$LOCAL_PORT" ]; then
    LOCAL_PORT=$DEFAULT_LOCAL
    while ss -tln 2>/dev/null | grep -q ":$LOCAL_PORT "; do
        LOCAL_PORT=$((LOCAL_PORT + 1))
    done
    # Start the forward quietly in background
    echo "✅ Using local port $LOCAL_PORT (found free) for forwarding... "

    gh codespace ports forward "${REMOTE_PORT}:${LOCAL_PORT}" -c "$CSPACE_NAME"   | lolcat &
fi

# 3️⃣ Single paranoid print at the end
echo "🔍 Paranoid check: Remote port $REMOTE_PORT forwarded to local port $LOCAL_PORT."



echo You must run at least once: sftp  -i $KEY_PATH -P $LOCAL_PORT codespace@127.0.0.1 
echo Try also: sftp  -i $KEY_PATH -P $REMOTE_PORT codespace@$REMOTE_IP

# Wait for the forwarded port to become available
echo "⏳ Waiting for the forwarded port to be ready..."
for i in {1..20}; do

    if sudo ss -tln | grep -q ":$LOCAL_PORT "; then
        echo "✅ Port $LOCAL_PORT is ready."
        break
    fi
    echo $(date)

    sleep 0.5
done



echo Applying: "ssh-keyscan -p $LOCAL_PORT 127.0.0.1 " 
ssh-keyscan -p $LOCAL_PORT 127.0.0.1 >> $HOME/.ssh/known_hosts 2>/dev/null


    echo "5️⃣  Set up or update the configuration of the rclone remote GitHub Codespace record ... :"
    RCLONE_REMOTE="GH_01"
    #RCLONE_REMOTE=GH_${CSPACE_NAME}
    # Each run does a rclone config update GH_01 .... That’s fine for one codespace, but if you juggle several, you might want per-codespace remotes (GH_${CSPACE_NAME}).
    #This does not work well: 
    RCLONE_REMOTE="GH_${CSPACE_NAME}"

# Check if remote exists
if ! rclone config show | grep -q "^\[$RCLONE_REMOTE\]"; then
    echo "Creating new rclone remote '$RCLONE_REMOTE' (type = sftp)"
    rclone config create "$RCLONE_REMOTE" sftp \
        host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | $FILTER 
else
    echo "Updating existing rclone remote: '$RCLONE_REMOTE'"
    rclone config update "$RCLONE_REMOTE" \
        host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | $FILTER 
fi



    #rclone config update "$RCLONE_REMOTE" host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | $FILTER 
    #sleep 1 
 if [ $? -ne 0 ]; then
    echo "❌ Failed to create rclone remote '$RCLONE_REMOTE'." | $FILTER
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
        echo -n "Mounting Codespace: " 
        echo  -n $CSPACE_NAME | $FILTER 
        echo -n " the userspace path: " 
        echo -n $WORKSPACE_PATH | $FILTER 
        echo -n " via a rclone local mount on: "  
        echo -n $MOUNT_PATH | $FILTER


    #Chown it, as some sudo changes to root ownership now and then: 

    sudo chown $(whoami):$(whoami)  $HOME/.config/rclone/rclone.conf
    
#The port may change so we add: -o StrictHostKeyChecking=no 
# Sudo does not work somehow, we use the trick of changing: 'usermount3: option allow_other only allowed if 'user_allow_other' is set in /etc/fuse.conf' 
        #sudo 
        sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH" \
            --config $HOME/.config/rclone/rclone.conf --allow-other  --vfs-cache-mode writes --vfs-cache-max-size 100M & 
        MOUNT_PID=$!
        sleep 1
        if ! ps -p "$MOUNT_PID" > /dev/null; then
            echo "❌ rclone mount failed to start." | $FILTER
            return 1
        fi
    else
        echo "✅ Already mounted at $MOUNT_PATH"        
    fi
    sleep 1
    echo Checking: "ls $MOUNT_PATH" : 
ls $MOUNT_PATH | $FILTER



    #Chown it, as some sudo changes to root ownership now and then: 

    sudo chown $(whoami):$(whoami)  $HOME/.config/rclone/rclone.conf
    

    if ! mountpoint -q "$SSHFS_MOUNT"; then
        echo -n "8️⃣  Mounting via SSHFS on:"
        echo "$SSHFS_MOUNT" | $FILTER
        sudo sshfs codespace@127.0.0.1:"$WORKSPACE_PATH" "$SSHFS_MOUNT" -p $LOCAL_PORT \
            -oIdentityFile="$KEY_PATH" -oStrictHostKeyChecking=no -o reconnect \
            -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o allow_other | $FILTER
        if [ $? -ne 0 ]; then
            echo "⚠️ SSHFS mount failed, proceeding to SSH session anyway..." | $FILTER
        fi
    fi

echo Checking: "ls $SSHFS_MOUNT"  :
ls "$SSHFS_MOUNT" | $FILTER


    echo "9️⃣  Entering the interactive session"
    echo "FYI: by default, Codespaces automatically stops after ~30 minutes of inactivity and gets deleted after 30 days of not logging in again."
    echo "👉 Starting Codespace SSH session..."
    gh codespace ssh -c "$CSPACE_NAME" -- -o ForwardX11=no  
    
    #This errors unduly if control C etc: 
: '
    if [ $? -ne 0 ]; then
        echo "❌ Error starting interactive SSH session to codespace '$CSPACE_NAME'." | $FILTER
        return 1
    fi
    '
}

echo This script does nothing apart from creating a function called gh_me. Source me then. 
