#Backup:
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.




#neofetch --off


#!/usr/bin/env bash

mkdir -p "$HOME/.local/bin"

for cmd in neofetch ncdu plocate; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd not found, installing..."
        sudo apt install -y "$cmd"
        cp "/usr/bin/$cmd" "$HOME/.local/bin/"
    fi
done


 neofetch --off 
 echo -n 'This box IP:' && curl -s https://ipinfo.io/ip || echo '⚠️ IP fetch failed.' && echo && echo 

: '

#nothing here now

' 


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
source /google/devshell/bashrc.google






export PATH="$PATH:$HOME/.local/usr/bin"
mkdir -p "$HOME/.local/var/lib/dpkg"

mkdir -p $HOME/Downloads/GitHub 

#idempotent init run: 

REPO_URL="https://github.com/Manamama/Ubuntu_Scripts_1/"
REPO_DIR="$HOME/Downloads/GitHub/Ubuntu_Scripts_1"
INSTALL_SCRIPT="$REPO_DIR/install_basic_ubuntu_set_1.sh"
MARKER_FILE="$REPO_DIR/.installed_basic_set_1"

# --- Ensure repo directory exists ---
mkdir -p "$(dirname "$REPO_DIR")"

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[ACTION] Cloning repo into $REPO_DIR ..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "[ACTION] Updating repo in $REPO_DIR ..."
    (cd "$REPO_DIR" && git pull --rebase --autostash)
fi

# --- Run install script if marker missing ---
if [ ! -f "$MARKER_FILE" ]; then
    echo "[ACTION] Running install script: $INSTALL_SCRIPT"
    bash "$INSTALL_SCRIPT"
   
else
    echo "[SKIP] Install script already run (marker exists: $MARKER_FILE)"
fi




# And install there for permanence: sudo dpkg --instdir=/home/abovetrans/.local --admindir=/home/abovetrans/.local/var/lib/dpkg --no-triggers -i gotop_v4.2.0_linux_amd64.deb

#You can bind /home, but not advised, as it is a temp, ephemeral folder:
# sudo mount --bind /root/home2 /home


export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$PATH:$HOME/.local/bin
export PATH="$HOME/.npm-global/bin:$PATH"

#!/usr/bin/env bash

# --- Ensure user bin dir ---
mkdir -p "$HOME/.local/bin"
echo "[INFO] Ensured bin dir exists at: $HOME/.local/bin"







# --- Python site-packages relocation ---
PYTHON_LIB=$(python -m site --user-site)
PERSISTENT_DEST_BASE="/root/home_extended"
CUR_USER=$(whoami)
CUR_HOME="$HOME"
PYTHON_LIB_DEST="${PYTHON_LIB/$HOME/$PERSISTENT_DEST_BASE}"

# Ensure source and destination exist
mkdir -p "$PYTHON_LIB"
sudo mkdir -p "$PYTHON_LIB_DEST"
sudo chown "$CUR_USER:$CUR_USER" "$PYTHON_LIB_DEST"

# Unmount any previous mounts at the source
while mountpoint -q "$PYTHON_LIB"; do
    echo "[RESET] Unmounting $PYTHON_LIB ..."
    sudo umount -l "$PYTHON_LIB"
done

#Wipe the current ones, sic! :
rm - rf $PYTHON_LIB
mkdir -p "$PYTHON_LIB"

# Bind and remount with exec
echo "[ACTION] Binding $PYTHON_LIB_DEST -> $PYTHON_LIB ..."
sudo mount --bind "$PYTHON_LIB_DEST" "$PYTHON_LIB"
sudo mount -o remount,rw,exec "$PYTHON_LIB"
echo "[DONE] Bound with exec: $PYTHON_LIB_DEST -> $PYTHON_LIB"

# --- Cache relocation ---
CACHE_SRC="$CUR_HOME/.cache"
CACHE_DEST="$PERSISTENT_DEST_BASE/.cache"

mkdir -p "$CACHE_SRC"
sudo mkdir -p "$CACHE_DEST"
sudo chown "$CUR_USER:$CUR_USER" "$CACHE_DEST"

# Reset stacked mounts if any
while mountpoint -q "$CACHE_SRC"; do
    echo "[RESET] Unmounting $CACHE_SRC ..."
    sudo umount -l "$CACHE_SRC"
done

#Wipe the current ones, sic! :
rm - rf $CACHE_SRC
mkdir -p "$CACHE_SRC"


# Bind and remount with exec
echo "[ACTION] Binding $CACHE_DEST -> $CACHE_SRC ..."
sudo mount --bind "$CACHE_DEST" "$CACHE_SRC"
sudo mount -o remount,rw,exec "$CACHE_SRC"
echo "[DONE] Bound with exec: $CACHE_DEST -> $CACHE_SRC"

# --- Sanity check ---
echo
echo "Final mount state:"
#findmnt -R "$PYTHON_LIB"
#findmnt -R "$CACHE_SRC"

mount | grep /home
echo
echo "Space free on /home (persistent storage):" 
df -h | grep Use%
df -h | grep /home


# --- End of relocation ---

# Note: For persistent mounts, consider adding it to /etc/fstab. Also maybe: 
# sudo chown -R abovetrans:abovetrans $CACHE_DEST

# The 'exec' option is crucial here. Without it, shared libraries (.so files) # and other executables in $LIB_SRC cannot be loaded or run. This was # causing the 'failed to map segment from shared object' error when running # applications like whisperx that rely on libraries in this directory


# this below is nonsense that it's not the cause of the problem of GCloud shell running out of space, only the mounts above which are hiding the real files left behind. The stragglers is the problem. Here we are leaving it for legacy reasons.
# --- Overlayfs /home ghost usage check ---
# This warns the user if ephemeral overlay upper-layer usage is high


if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

echo ver. 2.7.3
echo 

