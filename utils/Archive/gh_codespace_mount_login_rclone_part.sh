#This is bad, as it plays many a bad trick: A. hides cursor (sic), after & operation. B. rclone is crap in itself, after all, especially with 'git' 


: '

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
        host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | lolcat 
else
    echo "Updating existing rclone remote: '$RCLONE_REMOTE'"
    rclone config update "$RCLONE_REMOTE" \
        host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | lolcat 
fi



    #rclone config update "$RCLONE_REMOTE" host 127.0.0.1 user codespace key_file "$KEY_PATH" port "$LOCAL_PORT" | lolcat 
    #sleep 1 
 if [ $? -ne 0 ]; then
    echo "❌ Failed to create rclone remote '$RCLONE_REMOTE'." | lolcat
    return 1
   
  fi
  
  
  
  
  
    #echo "✅ The record of the rclone remote: '$RCLONE_REMOTE' has been updated in configuration."



    echo  "7️⃣  Mount the paths via rclone FUSE. "


    if ! mountpoint -q "$MOUNT_PATH"; then





echo Not doing this: 
        echo -n "Mounting Codespace: " 
        echo   $CSPACE_NAME | lolcat 
        echo -n " the remote path: " 
     
      
        echo  "$WORKSPACE_PATH"| lolcat 
        echo -n " via a rclone local mount on: "  
        echo "$MOUNT_PATH" | lolcat
        echo 


    #Chown it, as some sudo changes to root ownership now and then: 

#No error:
#exit

    sudo chown $(whoami):$(whoami)  $HOME/.config/rclone/rclone.conf
    
#The port may change so we add: -o StrictHostKeyChecking=no 
# Sudo does not work somehow, we use the trick of changing: 'usermount3: option allow_other only allowed if 'user_allow_other' is set in /etc/fuse.conf' 
        #sudo 
        #exit
        #This causes some huge error in 'echo', the lines get shifted and the feedback disappears: 
        #sudo rclone mount "$RCLONE_REMOTE:/$WORKSPACE_PATH" "$MOUNT_PATH"     --config $HOME/.config/rclone/rclone.conf --allow-other  --vfs-cache-mode writes --vfs-cache-max-size 100M & 
        #MOUNT_PID=$!
        #sleep 1
        echo We skip rclone, so: 
        echo "MOUNT_PID is: $MOUNT_PID"
        
#exit 
        
        if ! ps -p "$MOUNT_PID" > /dev/null; then
            echo "❌ rclone mount failed to start." | lolcat
            return 1
        fi
    else
        echo "✅ Already mounted at $MOUNT_PATH"        
    fi
    sleep 1
 
 
 
    #echo "Checking: 'ls $MOUNT_PATH' : "
    echo 
    

    #ls "$MOUNT_PATH"  | lolcat



    #Chown it, as some sudo changes to root ownership now and then: 

    sudo chown $(whoami):$(whoami)  $HOME/.config/rclone/rclone.conf
    
    
'
