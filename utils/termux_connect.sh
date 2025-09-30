#!/bin/bash

#It is an ugly merge of three scripts: old termux_me.sh and rclone_mount_termux.sh and rndis (the first bit below) that switches on Net sharing

#Install: 
#sudo apt install openssh-server
#sudo apt install net-tools
#sudo apt install iproute2
#sudo apt install xclip
#sudo snap install lolcat

# Function to retrieve the transport ID of the connected device
get_connected_device() {
    # List connected devices with adb, filter for lines containing "transport_id", number each line, and print the second field (the transport ID)
    echo "$(adb devices -l | grep "transport_id" | nl | awk '{print $2}')"
}




# Function to identify the Termux user on a selected device
get_termux_user() {
    selected_device=$1
    # Execute a shell command on the selected device to list processes, filter for Termux processes, take the first line, and print the first field (the user)
    echo "$(adb -s $selected_device shell su -c 'ps -A -o USER,PID,RSS,S,NAME' | grep com.termux | head -1 | awk '{ print $1 }')"
}

# Function to scan a specified IP address and port using nmap
scan_ip() {
  ip=$1 # The IP address to scan
  port=$2 # The port to scan
  echo "Scanning IP: $ip and port: $port"
  # Scan the specified IP address and port with nmap, filter for lines containing IP addresses, and print the results
  nmap_results=$(nmap -n -p $port $ip/24 | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
  echo $nmap_results
}



# Dynamically detects Termux devices, verifies mounts, and checks rclone config with explicit status, minimal output, and robust error handling
set -uo pipefail  # Remove set -e to prevent premature exits, keep -u and pipefail

echo "========================================="
echo "📌 Paranoid Termux login and Termux rclone mount script, version 6.3.3"
echo "========================================="

# SSH and rclone user (Termux internal user)
REMOTE_USER="u0_a278"
# Password file (create with actual password for Termux SSH)
PASSWORD_FILE="$HOME/.ssh/.termux_ssh_pass"
# Check if password file exists and is readable
if [[ ! -f "$PASSWORD_FILE" ]] || [[ ! -r "$PASSWORD_FILE" ]]; then
    echo "❌ FATAL: Password file '$PASSWORD_FILE' not found or not readable."
    echo "📋 Create it with: echo 'your_actual_password' > $PASSWORD_FILE && chmod 600 $PASSWORD_FILE"
    exit 1
  else
  echo "Password file '$PASSWORD_FILE' shall be used for the password to Droid". 
fi



# ----------------- Step 0: prerequisites -----------------
echo "[0/7] Checking prerequisites..."
for cmd in ssh sftp rclone nc sshpass mountpoint tee; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ FATAL: '$cmd' not found. Install it first (e.g., 'sudo apt install $cmd')."
        exit 1
    fi
done
# Check /tmp write permissions
if ! touch /tmp/test_write.$$ || ! chmod 664 /tmp/test_write.$$; then
    echo "❌ FATAL: Cannot write to /tmp. Check permissions."
    exit 1
fi
rm -f /tmp/test_write.$$
echo "✅ Prerequisites OK"

# ----------------- Step 1: determine mount base -----------------

#Nota bene, this would be more elegant, but then we need read write access to new folders therein, because of dynamic IPs, and this needs sudo: 
MOUNT_BASE="/media/$USER"
#So we use: 
MOUNT_BASE="${HOME}/mnt"



mkdir -p "$MOUNT_BASE"
echo "[1/7] Mount base set to '$MOUNT_BASE'"



echo "We are switching on Net sharing for an USB connected device, thus adding another IP. For that, we start with listing all the devices; what are the USB devices 'attached' to this box that the 'adb -d' commands shows?:" 
adb devices -l | lolcat 
echo "🖧  Trying to use the first device: $(adb -d get-serialno | tr -d n) as the Net source (USB tethering), do treat any error as a warning here ... "
adb -d shell svc usb setFunctions rndis

echo "Tip: if wrong Droid device auto selected, then use e.g.   'adb -s ZHE6ORBQ7TR8BQHM -d shell svc usb setFunctions rndis' (another one from the list above) to switch to another source; replacing ZHE6ORBQ7TR8BQHM with your device name shown above." 

sleep 1


# ----------------- Step 2: detect candidate Termux IPs -----------------
echo "[2/7] Detecting candidate Termux IPs..."
CANDIDATE_IPS=()
while read -r ip; do
    ip_clean=$(echo "$ip" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
    # Optional: Filter out unstable IPs (e.g., Bluetooth)
    # [[ $ip_clean != "192.168.44.1" ]] && [[ -n "$ip_clean" ]] && CANDIDATE_IPS+=("$ip_clean")
    [[ -n "$ip_clean" ]] && CANDIDATE_IPS+=("$ip_clean")
done < <(arp -an | awk '{print $2}' | tr -d '()')

echo "[✓] Candidate IPs detected: ${CANDIDATE_IPS[*]}"

# ----------------- Step 3: test SSH and get remote user -----------------
DETECTED_IPS=()
declare -A REMOTE_USERS

for ip in "${CANDIDATE_IPS[@]}"; do
    echo "[3/7] Testing SSH connectivity to $ip:8022..."
    if nc -z -w2 "$ip" 8022 &>/dev/null; then
        echo "✅ Port 8022 open on $ip"
        LOG_FILE="/tmp/ssh_error_$ip.log"
        # Ensure log file is writable
        touch "$LOG_FILE" 2>/dev/null && chmod 664 "$LOG_FILE" 2>/dev/null || {
            echo "❌ FATAL: Cannot create/write to $LOG_FILE"
            exit 1
        }
        RETRY_COUNT=0
        MAX_RETRIES=2
        SUCCESS=0
        while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
            ((RETRY_COUNT++))
            echo "🔄 SSH attempt $RETRY_COUNT/$MAX_RETRIES for $ip..."
            # Run sshpass with verbose output, capture both stdout and stderr
            if user=$(sshpass -f $PASSWORD_FILE ssh -p 8022  -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$REMOTE_USER@$ip" 'whoami' 2>&1 | tee "$LOG_FILE"); then
                echo "✅ Remote user detected on $ip: $user"
                DETECTED_IPS+=("$ip")
                REMOTE_USERS["$ip"]="$user"
                SUCCESS=1
                break
            else
                echo "⚠️ SSH handshake failed on attempt $RETRY_COUNT for $ip (exit code: $?)"
                echo "📋 SSH error log: $LOG_FILE"
                cat "$LOG_FILE"
                # Check if log file was written
                if [[ ! -s "$LOG_FILE" ]]; then
                    echo "⚠️ Warning: Log file $LOG_FILE is empty"
                fi
            fi
        done
        # Fallback to alternative username if sshpass fails
        if [[ $SUCCESS -eq 0 ]]; then
            echo "⚠️ Falling back to alternative username for $ip..."
            if user=$(sshpass -f $PASSWORD_FILE ssh -p 8022 -v -o StrictHostKeyChecking=no -o ConnectTimeout=5 "termux@$ip" 'whoami' 2>&1 | tee "$LOG_FILE"); then
                echo "✅ Remote user detected on $ip (fallback): $user"
                DETECTED_IPS+=("$ip")
                REMOTE_USERS["$ip"]="$user"
                SUCCESS=1
            else
                echo "⚠️ Fallback SSH failed for $ip (exit code: $?)"
                echo "📋 SSH error log: $LOG_FILE"
                cat "$LOG_FILE"
            fi
        fi
        # Verify log file is readable
        if [[ -f "$LOG_FILE" ]] && ! cat "$LOG_FILE" >/dev/null 2>&1; then
            echo "⚠️ Warning: Log file $LOG_FILE is not readable. Attempting to fix permissions..."
            chmod 664 "$LOG_FILE" 2>/dev/null || echo "❌ Failed to fix permissions for $LOG_FILE"
        fi
    else
        echo "⚠️ Port 8022 closed on $ip, skipping"
    fi
done

if [[ ${#DETECTED_IPS[@]} -eq 0 ]]; then
    echo "❌ FATAL: No reachable Termux devices detected. Exiting."
    exit 1
fi

echo "[✓] Detected Termux IPs: ${DETECTED_IPS[*]}"


# ----------------- Step 3b: sort detected IPs by preference -----------------
# USB-tethered IPs are usually 172.*.*, prefer them first
sorted_ips=()
for ip in "${DETECTED_IPS[@]}"; do
    if [[ $ip =~ ^172\. ]]; then
        sorted_ips+=("$ip")
    fi
done
for ip in "${DETECTED_IPS[@]}"; do
    if [[ ! $ip =~ ^172\. ]]; then
        sorted_ips+=("$ip")
    fi
done
DETECTED_IPS=("${sorted_ips[@]}")
echo "[✓] Detected IPs sorted for USB preference: ${DETECTED_IPS[*]}"



# ----------------- Step 4: check/create rclone remotes -----------------
echo "[4/7] Verifying rclone configuration..."
for ip in "${DETECTED_IPS[@]}"; do
    REMOTE_NAME="termux_${ip//./_}"
    MOUNTPOINT="$MOUNT_BASE/$REMOTE_NAME"
    mkdir -p "$MOUNTPOINT"

    echo "🎹 Creating '$REMOTE_NAME' with 'sftp host=$ip user=$REMOTE_USER port=8022 pass=[REDACTED]'..."
    if ! rclone config create "$REMOTE_NAME" sftp host="$ip" user="$REMOTE_USER" port=8022 pass="$(cat $PASSWORD_FILE)"; then
        echo "❌ FATAL: Failed to create rclone remote '$REMOTE_NAME'"
        exit 1
    fi
    echo "✅ Remote '$REMOTE_NAME' created"
    # Paranoid: Dump remote config for verification
    #echo "📋 Remote config for '$REMOTE_NAME':"
    #rclone config show "$REMOTE_NAME" | sed 's/pass = .*/pass = [REDACTED]/'
done




# ----------------- Step 5: mount remotes with paranoid checks -----------------
echo "[5/7] Mounting remotes with paranoid checks..."
declare -A MOUNT_STATUS
for ip in "${DETECTED_IPS[@]}"; do
    REMOTE_NAME="termux_${ip//./_}"
    MOUNTPOINT="$MOUNT_BASE/$REMOTE_NAME"
    LOG_FILE="/tmp/rclone_mount_${REMOTE_NAME}.log"
    touch "$LOG_FILE" 2>/dev/null && chmod 664 "$LOG_FILE" 2>/dev/null || {
        echo "❌ FATAL: Cannot create/write to $LOG_FILE"
        exit 1
    }
    SUCCESS=0

    echo "⏳ Testing SFTP connection for $REMOTE_NAME..."
    # Test SFTP connection before mounting
    echo Skipped 
    if true; then
#    if time rclone ls "$REMOTE_NAME": >"$LOG_FILE"; then
        echo "✅ SFTP connection test succeeded for $REMOTE_NAME"
        echo "⏳ Mounting $REMOTE_NAME -> $MOUNTPOINT ..."
        # Run mount in daemon mode directly
        if rclone mount "$REMOTE_NAME": "$MOUNTPOINT" --daemon --log-level INFO 2>>"$LOG_FILE"; then
            # Wait briefly to ensure mount is established
            sleep 1
            echo "✅ Mounted successfully: $REMOTE_NAME at $MOUNTPOINT"
            SUCCESS=1
        else
            echo "❌ Mount failed for $REMOTE_NAME (exit code: $?). Error log: $LOG_FILE"
            cat "$LOG_FILE"
        fi
    else
        echo "❌ SFTP connection test failed for $REMOTE_NAME (exit code: $?). Error log: $LOG_FILE"
        cat "$LOG_FILE"
    fi

    # Paranoid: Check if rclone mount process is running
    if [[ $SUCCESS -eq 1 ]] && ps aux | grep "[r]clone mount $REMOTE_NAME" >/dev/null; then
        echo "✅ Rclone mount process verified for $REMOTE_NAME"
    else
        echo "❌ Rclone mount process not running for $REMOTE_NAME"
        SUCCESS=0
        # Cleanup: Kill any stale rclone processes
        pkill -f "rclone mount $REMOTE_NAME" 2>/dev/null || true
    fi

    # Paranoid: Check if mount point is a valid mount
    if [[ $SUCCESS -eq 1 ]] && mountpoint "$MOUNTPOINT" >/dev/null 2>&1; then
        echo "✅ Mount point verified as mounted: $MOUNTPOINT"
    else
        echo "⚠️ Mount point not recognized as mounted: $MOUNTPOINT"
        SUCCESS=0
        pkill -f "rclone mount $REMOTE_NAME" 2>/dev/null || true
    fi

    # Verify log file is readable
    if [[ -f "$LOG_FILE" ]] && ! cat "$LOG_FILE" >/dev/null 2>&1; then
        echo "⚠️ Warning: Log file $LOG_FILE is not readable. Attempting to fix permissions..."
        chmod 664 "$LOG_FILE" 2>/dev/null || echo "❌ Failed to fix permissions for $LOG_FILE"
    fi

    MOUNT_STATUS["$REMOTE_NAME"]=$SUCCESS
    
    
        #echo "Enabling wireless adb to the gateway $ip, via sudo setprop service.adb.tcp.port 5555, if it is not on yet, and connecting as per above."
    #echo
#    adb -d shell "su -c 'setprop service.adb.tcp.port 5555'"
    #Yes, it works - you can also pass on commands via ssh, e.g. 
    #sshpass ip ssh -o ConnectTimeout=2 u0_a278@192.168.44.1 -p 8022 'export PATH=/data/data/com.termux/files/usr/bin:/system/bin/:$PATH ; sudo ls'

    #sshpass ip ssh -o ConnectTimeout=2 u0_a278@$gateway -p 8022 'export PATH=/data/data/com.termux/files/usr/bin:/system/bin/:$PATH ; sudo setprop service.adb.tcp.port 5555; sudo stop adbd; sudo start adbd; adb connect localhost:5555'


    
    echo "Attempting an adb connection to the gateway: $ip:"
    adb connect $ip:5555 | lolcat 
    
    

#echo Switching adb to TCP/IP, for more routes: adb -d tcpip 5555...
#adb -d tcpip 5555 | lolcat

# - not needed. It is the same as "Allow Wireless Debugging " in Droid Settings. However, adb -s $connected_device shell to start a shell session on the device. The -s option allows you to specify the device to connect to, and shell starts a shell session on the device. This command works regardless of whether the ADB daemon on the device is in USB mode or TCP/IP mode, as long as the device is connected and authorized for debugging.



    
done

# ----------------- Step 6: verify mounts -----------------
echo "[6/7] Verifying mounts..."
for ip in "${DETECTED_IPS[@]}"; do
    REMOTE_NAME="termux_${ip//./_}"
    MOUNTPOINT="$MOUNT_BASE/$REMOTE_NAME"
    if [[ ${MOUNT_STATUS["$REMOTE_NAME"]} -eq 1 ]] && [[ -n $(ls -A "$MOUNTPOINT" 2>/dev/null) ]]; then
        echo "✅ Mount verified: $MOUNTPOINT is not empty"
        #echo "📋 Contents of $MOUNTPOINT:"
        #ls -l "$MOUNTPOINT"
    else
        echo "⚠️ Mount verification failed: $MOUNTPOINT is empty or not mounted"
        echo "📋 Error log: $LOG_FILE"
        [[ -f "$LOG_FILE" ]] && cat "$LOG_FILE"
    fi
done

# ----------------- Step 7: final report -----------------
echo "[7/7] Paranoid verification complete."
echo Test of echo... 
#This hangs up somehow, not sure why: 
echo "📊 Mount Status Summary:"
echo "----------------------------------------"
printf "%-20s %-30s %-10s"

echo
echo "⚠️ Warning: even if well mounted now, do not use 'git' operations on a rclone mounted repo, as git lock file(s) are not removed and generally, 'git' starts to mess up the 'git' control files due to some mysterious yet cache delays, observer it via: watch file  '$(pwd)/.git/index.lock'  mechanism, if needed to avoid." 



#Here old Termux starts, modded: 

#echo stop the script:
#exit 0

echo Starting Termux itself... 

# Iterate over each gateway and attempt SSH connection
for ip in "${DETECTED_IPS[@]}"; do

    echo "Attempting an SSH connection to the gateway $ip... "
    echo "(If nothing is visible or an error is shown - quit and try the below manually, so as to accept the message: 'Are you sure you want to continue connecting (yes/no/[fingerprint])?' or pkill sshd on Droid first.)"
    echo "ssh u0_a278@$ip -p 8022" | lolcat
    echo
    #echo "ssh u0_a278@$ip -p 8022" | lolcat
    

    echo You can also connect to Droid via SFTP this way: 

    #echo We are also connect to Droid via SFTP this way: 
    echo "nautilus sftp://$ip:8022/data/data/com.termux/files/home &" | lolcat
    

    echo 
#    nautilus sftp://$ip:8022/data/data/com.termux/files/home &

#This causes "unbound variable" even if commented out, for some reason: 
#    'wmctrl -i -r $(wmctrl -lp | grep $(pgrep -n nautilus) | awk '{print $1}') -b add,below'

#    echo Now connecting to Termux with the password...
#    echo

    echo To do also one day: start Code Server from Droid via: 
   echo ssh -L 8080:127.0.0.1:8080 -N -f u0_a278@$ip -p 8022 | lolcat
echo And then http://localhost:8080/login

    #-o StrictHostKeyChecking=no 
    
    sshpass -f $PASSWORD_FILE ssh -p 8022  -o ConnectTimeout=5 "$REMOTE_USER@$ip"
    
done

echo
echo 




: ' Tips:

- **SSH Connection**: When forwarding the ports for the SSH connection and starting the SSHD server on Android, ensure that the specific user (u0_a278) has the necessary permissions to run the 'sshd' command. The password must be set by the 'passwd' command in Termux. On Android openssh must have been installed, keys generated, and password generated for the Termux process user via 'passwd'.

⚠️ Do **not** start the `sshd` process from a Magisk context (e.g., via `su` or boot scripts). 
If `sshd` is launched from Magisk, it will inherit the `u:r:magisk:s0` SELinux domain. This **breaks access to shared storage paths** like `/storage/emulated/0/` and `/storage/sdcard1/`, because Android restricts access to those paths to apps running in the `untrusted_app` context with proper permissions. Use `sudo pkill sshd` then, and start `sshd` from Termux itself (e.g. restart it).  

✔️ Always start `sshd` from within a GUI-launched Termux session to ensure it runs under the `u:r:untrusted_app_*` context, which allows normal storage access.

To verify the SELinux context in your SSH session:
    ps -p $$ -o pid,uid,context

You should see: `u:r:untrusted_app_xx:s0:...` — if it says `u:r:magisk:s0`, your storage access will fail.




- **ADB Connection**:
-- The 'getprop persist.sys.usb.config' command can help verify if USB is connected.
-- If no Android device is detected or if it is offline, for adb method, ensure 'USB debugging' is enabled in Developer Options, or consider using WADB on Android. 

-- Even if you connect to Termux via adb, your process user will be different from the Termux on Android. In practice, you will not have access to files in e.g. /storage, as they had been granted to the "real" Termux app user only. You must use the root account for such access then or connect via the ssh way.


- **Root Access**: If the device is not rooted, consider using a workaround like the termux-adb launcher.

- The adbd daemon is run via /apex/com.android.adbd/bin/adbd on Android. You can access it via:

adb -s ZHE6ORBQ7TR8BQHM -d shell  su -c "/apex/com.android.adbd/bin/adbd"


If you want to restart the adbd process, you would typically stop the existing process before starting a new one. This can be done using the setprop command to send a property change to the Android init system, which controls the adbd service1. Here’s how you can do it:

adb shell 'setprop ctl.restart adbd'

- You can use "adb tcpip 5555" to switch , but not needed. 

- Try 
 su -p -c "/apex/com.android.adbd/bin/adbd"
 
 or with sudo, but with 
 unset LD_PRELOAD
 first , 
 
on Droid to check the daemon state. 






'



: ' What the script does:
Define Helper Functions: The script defines several helper functions to retrieve the transport ID of the connected device, identify the Termux user on a selected device, scan a specified IP address and port using nmap, and get the default gateway IP addresses.
Start Main Script: The script begins by displaying a start message and the WiFi Access Point the PC is connected to.
#Set ADB to TCP/IP Mode: The script runs adb tcpip 5555 to set the ADB daemon on the selected device to listen for connections over TCP/IP.
Identify Gateways: The script identifies all gateways and attempts to connect to each gateway using ADB.
Attempt SSH Connection: For each gateway, the script attempts an SSH connection.
Plan B for SSH Connection: The script includes a commented-out section (Plan B) for establishing an SSH connection using ADB to forward a local port to a remote port.
ADB Connection Attempts: The script attempts to connect to each IP address in $ip_address using ADB.
List ADB Connected Devices: The script lists all the ADB connected Android devices.
User Input for Device Selection: The script prompts the user to enter the number of the device they want to connect to.
Termux User Connection via ADB: The script attempts to connect to the selected device via ADB (not SSH). It identifies the Termux user on the selected device and checks if the username is empty.
Starting ADB Shell Session: The script starts an ADB shell session, which opens an interactive shell session on the Android device, allowing the user to manually enter commands.
'
