# This script sets up environment variables and sources NVM for Ubuntu_Scripts_1 project.
# It is sourced by ~/.bashrc to ensure persistence across shell sessions.

# Add local bin directories to PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
# This path is complex and might be slow on every shell start.
# Consider if it's truly needed on every shell start or if tools are installed elsewhere.
# For now, including as per original script.
export PATH="$HOME/.local/usr/bin:$PATH"

# Add local lib directories to LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Gemini CLI specific: so that you can log in to Google to use token in headless environment
export NO_BROWSER=1


