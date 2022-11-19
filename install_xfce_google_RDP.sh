<<<<<<< HEAD
# Version 2.2.1, GitLab Space Opulent Space Barnacle
=======
# Version 2.3.1, online github
>>>>>>> 1141bace5f3405b5e7ad7ece8005f1970f1fac96
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

cd  ~/Download
#Install Google remote desktop
if [[ ! -f "chrome-remote-desktop_current_amd64.deb" ]] ;
then
#cd Download
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
#else
#echo "Chrome remote already exists"
fi
sudo dpkg -i chrome-remote-desktop_current_amd64.deb 
sudo apt --fix-broken install -y

# Check and fix this one via https://remotedesktop.google.com/headless
#DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0AfgeXvsfP11b9rVHZFeMR9daeFSA0ZbQ2kYmzcXxtrbFwnDEQXUzfr1E7dEZy1NS-IeK2g" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
echo Go to  https://remotedesktop.google.com/access/session/49e2ce50-33e2-4ed7-b528-6400000311f7 now and download command
#Use this to check if it is running OK:
#sudo service "chrome-remote-desktop@$USER" status
#Use this if does not restart:
sudo service "chrome-remote-desktop" start
#install teamviewer 
cd ~/Download 
if [[ ! -f "teamviewer-host_amd64.deb" ]] ;
then
wget https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb
#else 
#echo "Teamviewer already exists"
fi
sudo dpkg -i teamviewer-host_amd64.deb
sudo apt --fix-broken install -y

#Install once again, to make sure
sudo aptitude install teamviewer-host -y


# For snap etc, mostly does not work anyway:
#bash ~/demonize_system_snap.sh 

sudo teamviewer daemon start   
sudo teamviewer setup
