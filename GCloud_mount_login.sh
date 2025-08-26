


gc1() {
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

    gcloud config list

    # Update rclone config
    rclone config update 'GCloud_01' host "$GCloud_IP"
    GCloud_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | cut -d'@' -f1)
    rclone config update 'GCloud_01' user "$GCloud_USER"

    echo -e "\nRclone 🌲:"
    rclone tree --level 1 'GCloud_01:'
    echo

    # Mount rclone remote
    MOUNT_PATH=~/storage/GCloud_01_rclone
    mkdir -p "$MOUNT_PATH"
    echo "Mounting rclone remote at $MOUNT_PATH..."
    mount | grep gcloud | lolcat

    # Run umount and rclone mount attached to Termux FUSE server
sudo umount /data/data/com.termux/files/home/storage/GCloud_01_rclone

time sudo rclone mount \
    --config /data/data/com.termux/files/home/.config/rclone/rclone.conf \
    GCloud_01: "$MOUNT_PATH" \
    --allow-other \
    --vfs-cache-mode writes  &
#Nota bene: --daemon does not work well
    echo "✅ Rclone mount command issued in background. Test: "
sudo mount | grep $MOUNT_PATH


    # Mount Cloud Shell via SSHFS as fallback
    SSHFS_MOUNT=~/storage/gcloud_01
    mkdir -p "$SSHFS_MOUNT"
    KEY_PATH=/data/data/com.termux/files/home/.ssh/google_compute_engine

    if mountpoint -q "$SSHFS_MOUNT"; then
        echo "✅ Already mounted at $SSHFS_MOUNT"
    else
        echo "🔌 Mounting Cloud Shell via SSHFS..."
        sudo sshfs "$GCloud_USER@$GCloud_IP": "$SSHFS_MOUNT" -p 6000 \
            -o IdentityFile="$KEY_PATH" \
            -o StrictHostKeyChecking=no \
            -o reconnect \
            -o ServerAliveInterval=5 \
            -o ServerAliveCountMax=3 \
            -o TCPKeepAlive=yes \
            -o allow_other
    fi

    echo
    echo "To restart it, use:"
    echo "gcloud cloud-shell ssh --authorize-session --command 'sudo kill 1'" | lolcat
    echo "👉 Starting gcloud cloud-shell ssh --authorize-session ..."
    gcloud cloud-shell ssh --authorize-session

#Tips: && echo && echo && bash ~/install_basic_ubuntu_set_1.sh "  && termux-media-player play "/storage/5951-9E0F/Audio/Funny_Sounds/Quack Quack-SoundBible.com-620056916.mp3"

}
