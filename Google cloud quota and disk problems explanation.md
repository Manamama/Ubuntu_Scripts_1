Got it. Let’s do a clear, truth-first, pro memoria-style explanation of the architecture, cause, and a monitoring approach for the “disk full but visible files are small” problem in Google Cloud Shell.

1️⃣ Architecture (Cloud Shell home overlay)

┌─────────────────────────────┐ │ Google Cloud host VM │ │ ┌─────────────────────┐ │ │ │ Physical disk / SSD │ │ │ └─────────┬───────────┘ │ │ │ │ │ /var/volumes/root-home-directory/home_extended │ │ (backing store for /home) └───────┬────┴────────────────┘ │ overlayfs mount on /home (inside container) │ ┌────────────┴─────────────┐ │ Cloud Shell container │ │ ┌───────────────────┐ │ │ │ /home (mount) │◀── visible files & bind mounts │ │ ┌───────────────┐ │ │ │ │ │ .cache │ │ │ │ │ │ .local/lib/... │ │ │ │ │ └───────────────┘ │ │ │ └───────────────────┘ │ └─────────────────────────┘ 

/home inside the container is overlayfs mounted on the host-managed disk /dev/disk/by-id/google-home-part1.

Your bind mounts (.cache, .local/lib/...) point to /root/home_extended/... on the host.

Google Cloud Shell prepopulates /home with ephemeral system files that exist only in the upper overlay layer.

These upper-layer ephemeral files are invisible to du inside the container but count toward df usage.

2️⃣ Root Cause

The overlayfs upper layer holds ephemeral system files that are always there for a Cloud Shell session.

Even if you clean .cache, .local, or cloned repos in your home, these upper-layer files remain invisible but allocated.

The “disk full” error occurs when:

The overlayfs layer reaches its allocated device capacity.

df reports nearly full.

du inside container shows only your visible files — giving the illusion of “empty but full”.

✅ Key point: Not a filesystem corruption, not a user process leak, not deleted-but-open files. This is purely container overlay management.

3️⃣ System check for approaching “disk full” status

From inside your container, you can monitor the ghost/orphaned space using the difference between df and du:

#!/bin/bash MOUNT="/home" DF_USED=$(sudo df -B1 $MOUNT | awk 'NR==2 {print $3}') DU_USED=$(sudo du -s -B1 $MOUNT | awk '{print $1}') GHOST=$((DF_USED - DU_USED)) THRESHOLD=$((500*1024*1024)) # 500 MB threshold echo "=== $MOUNT usage check ===" echo "DF used bytes : $DF_USED" echo "DU used bytes : $DU_USED" echo "Ghost bytes : $GHOST" if (( GHOST > THRESHOLD )); then echo "WARNING: overlay upper layer approaching full (~$GHOST bytes hidden)" fi 

Explanation:

df → reports total allocated blocks, including invisible overlay upper layer.

du → reports visible files.

ghost → df - du approximates the ephemeral upper-layer usage.

You can set a threshold to alert before writes fail.

4️⃣ How to deal with it

You cannot delete these ghost files from inside the container.

Restarting the Cloud Shell session clears the ephemeral overlay upper layer.

Bind mounts for .cache or .local reduce the chance, but don’t eliminate ephemeral system files outside bind targets.

✅ Summary Pro Memoria

ConceptInside ContainerOutside (Host Layer)Visible files (du)YesYesEphemeral overlay filesNoYesDisk allocation (df)Shows fullAccurateClearing ghost filesImpossibleSession restartCause of “full but empty”Overlay upper layerOverlay upper layer 

Trigger check: use df vs du as above.

Resolution: session restart.

Prevention: bind mounts, careful package management, small ephemeral files.


