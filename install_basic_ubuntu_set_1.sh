#Script to install basic set of apps manually. Use nano or Cloud Shell Editor to edit this file. 
# Ver. 1.1
# You can also do it elegantly by moving to $HOME/.customize_environment, see https://cloud.google.com/shell/docs/configuring-cloud-shell

sudo apt --fix-broken install -y
#sudo apt update && sudo aptitude upgrade -y
#Takes too long and not needed


sudo apt install aptitude -y

#For whisper
sudo apt-get -y install ffmpeg
# Run aria2c [address] to download stuff. Or outube-dl
sudo apt install aria2 -y
sudo apt install youtube-dl -y


#sudo apt install ffmpeg -y

# convert speech to text via GPU:
pip install git+https://github.com/openai/whisper.git


#For remote desktop access via google chrome https://remotedesktop.google.com/access/session/9a560954-e470-46ad-9d05-ef683f4b527b
sudo dpkg -i Download/chrome-remote-desktop_current_amd64.deb 
##sudo apt install -f
#Or use Ubuntu desktop script: bash ubuntu_server_install_ver_1.sh

#sudo dpkg -i Download/google-chrome-stable_current_amd64.deb


#For renmina RDP access : 
sudo apt install xrdp -y
#Run it:
sudo service xrdp start
sudo service xrdp status
sudo adduser xrdp ssl-cert  
sudo service restart xrdp


#Shows OS version and basic stuff
sudo apt install neofetch -y

sudo apt install geoip-bin -y
#Shows server location

neofetch
curl https://ipinfo.io/ip

#File browser. Or use mc.
sudo apt install ranger -y
sudo apt install baobab -y
sudo apt install firefox-esr -y


sudo apt --fix-broken install -y


#Tips:
#To mount it via Sshfs: sshfs abovetrans@34.147.26.51: /home/zezen/google_abovetrans_cloud_VM_1 -p 6000 -oIdentityFile=/home/zezen/.ssh/google_compute_engine -oStrictHostKeyChecking=no
# See https://cloud.google.com/sdk/gcloud/reference/cloud-shell/get-mount-command


#DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0ARtbsJrLrNVnIbdBlV5jewUOc7uhwyjRKCI0PiDnlmideyoYHgtgchSzTv1ldRfRNKL3uQ" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
