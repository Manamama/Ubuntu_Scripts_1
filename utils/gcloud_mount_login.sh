#!/bin/bash
#
# Description: Provides a function to manage Google Cloud Shell login, rclone mounts, and SSHFS mounts.
#              Primarily designed for use within Termux/Android environments to access Google Cloud resources.
#
# Usage:
#   This script defines the `gc1` function. To use it, source this script in your shell:
#   source /path/to/GCloud_mount_login.sh
#   Then, call the function:
#   gc1
#
# Dependencies:
#   - gcloud CLI (Google Cloud SDK)
#   - rclone
#   - sshfs
#   - lolcat (optional, for colored output)
#   - Termux environment (for specific paths like /data/data/com.termux)
#
# Last Modified: August 31, 2025


gc1(){
    # Ensure SSH folder ownership
    sudo chown -R u0_a278:u0_a278 /data/data/com.termux/files/home/.ssh

#use --account or --configuration to switch

    # Fetch Cloud Shell IP
    GCloud_IP=$(gcloud cloud-shell ssh --authorize-session --command "curl -s https://ipinfo.io/ip" 2>/dev/null || echo "")

#Use this: gcloud cloud-shell ssh --authorize-session --command 'source ~/.profile && whisperx' 

#or use: gcloud cloud-shell ssh --dry-run
#If quota overused: gcloud config set account .... 
# Restart only via: https://shell.cloud.google.com/?hl=en_GB&fromcloudshell=true&show=terminal
# This does not work: gcloud cloud-shell ssh --authorize-session --command 'sudo kill 1'



    if [[ -z "$GCloud_IP" ]]; then
        echo "⚠️  Failed to fetch Cloud Shell IP." | lolcat
        return 1
    fi

    echo -n "This GCloud box IP: "
    echo "$GCloud_IP" | lolcat
echo
echo

   #Useful info: gcloud config list 

    # Update rclone config
    rclone config update 'GCloud_01' host "$GCloud_IP"
    GCloud_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | cut -d'@' -f1)
    rclone config update 'GCloud_01' user "$GCloud_USER"

    echo -e "\nRclone 🌲:"
    rclone tree --level 1 'GCloud_01:'
    echo

    # Mount rclone remote
    RCLONE_MOUNT_PATH=~/storage/GCloud_01_rclone_$GCloud_USER
    mkdir -p "$RCLONE_MOUNT_PATH"
    echo "Mounting rclone remote at $RCLONE_MOUNT_PATH..."
    mount | grep GCloud | lolcat

    # Run umount and rclone mount attached to Termux FUSE server
echo "✅ Rclone umount and remount command issued in background... "

sudo umount $RCLONE_MOUNT_PATH

time sudo rclone mount \
    --config /data/data/com.termux/files/home/.config/rclone/rclone.conf \
    GCloud_01: "$RCLONE_MOUNT_PATH" \
    --allow-other \
    --vfs-cache-mode writes  &
#Nota bene: --daemon does not work well
    
#echo "Test of mount:" 
#sudo mount | grep $RCLONE_MOUNT_PATH | lolcat

    # Mount Cloud Shell via SSHFS as fallback
    SSHFS_MOUNT=~/storage/GCloud_01_$GCloud_USER_sshfs
    mkdir -p "$SSHFS_MOUNT"
    KEY_PATH=/data/data/com.termux/files/home/.ssh/google_compute_engine

    #if mountpoint -q "$SSHFS_MOUNT"; then
        #echo "✅ Already mounted at $SSHFS_MOUNT"
    #else
        echo "🔌 Unmounting and mounting Cloud Shell via SSHFS at $SSHFS_MOUNT..."
sudo umount $SSHFS_MOUNT
        sudo sshfs "$GCloud_USER@$GCloud_IP": "$SSHFS_MOUNT" -p 6000 \
            -o IdentityFile="$KEY_PATH" \
            -o StrictHostKeyChecking=no \
            -o reconnect \
            -o ServerAliveInterval=5 \
            -o ServerAliveCountMax=3 \
            -o TCPKeepAlive=yes \
            -o allow_other
 echo "Test of mount: "
sudo mount | grep $SSHFS_MOUNT | lolcat

    #fi

    echo
    echo "To reset GCloud, use:"
    echo "https://shell.cloud.google.com/?hl=en_GB&fromcloudshell=true&show=terminal" | lolcat
    echo "👉 Starting gcloud cloud-shell ssh --authorize-session ..."
    gcloud cloud-shell ssh --authorize-session

#Tips: && echo && echo && bash ~/install_basic_ubuntu_set_1.sh "  && termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3"

}
