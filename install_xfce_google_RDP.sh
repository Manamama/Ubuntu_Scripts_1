sudo DEBIAN_FRONTEND=noninteractive apt install -y xfce4 desktop-base
sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
sudo aptitude install -y xscreensaver
sudo apt install dbus-x11 -y
sudo apt-get install gconf-service -y
sudo apt-get update
#sudo add-apt-repository ppa:saiarcot895/chromium-beta
#sudo apt-get install chromium-browser -y
sudo apt install firefox-esr -y

#sudo apt install chromium - y

#Install Google remote desktop
if [[ ! -f "chrome-remote-desktop_current_amd64.deb" ]] ;
#cd Download
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
fi
sudo dpkg -i chrome-remote-desktop_current_amd64.deb 
# Check and fix this one via https://remotedesktop.google.com/headless
#DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0AfgeXvsfP11b9rVHZFeMR9daeFSA0ZbQ2kYmzcXxtrbFwnDEQXUzfr1E7dEZy1NS-IeK2g" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
echo Go to  https://remotedesktop.google.com/access/session/49e2ce50-33e2-4ed7-b528-6400000311f7 now and download command
#Use this to check if it is running OK:
#service "chrome-remote-desktop@$USER" status
#install teamviewer 
#cd Download 
if [[ ! -f "teamviewer-host_amd64.deb" ]] ;
wget https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb
fi
sudo dpkg -i teamviewer-host_amd64.deb
apt --fix-broken install
<<<<<<< HEAD
sudo aptitude install teamviewer-host -y

bash ~/demonize_system_snap.sh 
=======
# For snap etc, mostly does not work:
#bash ~/demonize_system_snap.sh 
>>>>>>> 919856b81b5332daa7f565bb4bbecac6db0838e6
sudo teamviewer daemon start   
sudo teamviewer setup
