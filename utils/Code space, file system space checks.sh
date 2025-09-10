echo For theory, read this document: Visual Studio Code Overlay Explanation.md
echo

for mount in $(mount | awk '$5=="overlay"{print $3}'); do
    echo "=== $mount ==="
    
    # Show apparent usage via df
    df -h "$mount"
    
    # Check if overlay upperdir is set
    upperdir=$(grep "upperdir=" /proc/mounts | grep "$mount" | sed 's/.*upperdir=\([^,]*\).*/\1/')
    
    if [ -n "$upperdir" ]; then
        echo "Overlay upperdir: $upperdir"
        # Show disk usage in the upperdir
        sudo du -h --max-depth=2 "$upperdir" | sort -h
    fi

    # Show visible usage inside the mount itself
    sudo du -xh --one-file-system "$mount" | sort -h | tail -n 20
done


mount | df

echo For theory, read this document: Visual Studio Code Overlay Explanation.md
echo