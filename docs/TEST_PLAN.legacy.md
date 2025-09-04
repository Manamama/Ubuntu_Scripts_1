### **Project Status: Cleanup and Refactoring Completed**

**Overall Goal:** The primary goal of organizing the repository structure and refactoring the core installation scripts (`install_basic_ubuntu_set_1.sh`) has been completed. The script is now more robust, idempotent, and installs packages to userland.

**Testing Status:** All non-skipped functions in `install_basic_ubuntu_set_1.sh` have been individually tested and verified. The script runs from start to finish without critical errors or interactive prompts.

---
# TEST PLAN for `install_basic_ubuntu_set_1.sh`

## Testing Philosophy: Pragmatic Outcome Verification in Codespace/GCloud

Given the stable nature of GitHub Codespace and GCloud environments, our testing approach prioritizes efficient, manual verification of the `install_basic_ubuntu_set_1.sh` script's intended outcomes.

### Key Principles:
*   **Environment Trust:** We assume the underlying system utilities are present and functional in the Codespace/GCloud environment, thus eliminating the need for redundant system-level checks.
*   **Outcome-Focused Verification:** Testing will concentrate on manually sanity-checking the final system state and the successful execution of the script's internal functions. This involves verifying the *outcome* of function calls, which directly reflects changes to the system state.
*   **Manual Sanity Checks:** Verification will primarily be performed by hand, observing the system's configuration and installed components after the script runs. This "paranoid" double-checking ensures the script achieves its goals.

This approach streamlines testing by leveraging the environment's stability and focusing on direct, observable results.

---

## Detailed Test Cases for `install_basic_ubuntu_set_1.sh`

These test cases are designed for manual verification in a GitHub Codespace or GCloud environment. Run the `install_basic_ubuntu_set_1.sh` script and then perform the following checks.

### Function: `check_dependencies()`

**Purpose:** Verifies the presence of essential system commands (`sudo`, `apt-get`, `wget`, `dpkg`, `usermod`, `systemctl`). Provides warnings if `node` or `npm` are missing.

**Testing Status:** Skipped for direct testing within this plan.
**Reason for Skipping:** The `check_dependencies` function is a preliminary check designed to ensure the environment is suitable for script execution. Its primary output is informative, and critical failures would halt the script. Comprehensive testing of this function is implicitly covered by the successful execution of subsequent functions that rely on these dependencies.

### Function: `configure_system_resources()`

**Purpose:** Manages disk space, swap, Python `site-packages` and cache relocation, and ensures the repository is updated.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f configure_system_resources); configure_system_resources"` (or the full script).
2.  **Verification Steps:**
    *   **Python site-packages bind mount:**
        *   `mount | grep "$(python -m site --user-site)"` (should show a bind mount from `/root/home_extended` or `/tmp`).
        *   `ls -ld "$(python -m site --user-site)"` (should show permissions for the current user).
    *   **Cache bind mount:**
        *   `mount | grep "$HOME/.cache"` (should show a bind mount from `/root/home_extended` or `/tmp`).
        *   `ls -ld "$HOME/.cache"` (should show permissions for the current user).
    *   **Swap file:**
        *   `swapon --show` (should list `/tmp/swapfile` with a size of 16GB).
        *   `free -h` (should show 16GB swap space).
    *   **Repository Management:**
        *   `ls -ld ~/Downloads/GitHub/Ubuntu_Scripts_1` (should exist and be a git repository).
        *   `cd ~/Downloads/GitHub/Ubuntu_Scripts_1 && git status` (should show a clean working tree or "Already up to date.").
3.  **Expected Outcome:** Python site-packages and cache directories are bind-mounted to persistent storage, a 16GB swap file is active, and the `Ubuntu_Scripts_1` repository is cloned/updated.

### Function: `configure_persistent_environment()`

**Purpose:** Creates `utils/ubuntu_scripts_env.sh` and ensures it's sourced in `~/.bashrc` for persistent environment variables.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f configure_persistent_environment); configure_persistent_environment"` (or the full script).
2.  **Verification Steps:**
    *   Check if `utils/ubuntu_scripts_env.sh` exists and contains expected content: `cat /workspaces/Ubuntu_Scripts_1/utils/ubuntu_scripts_env.sh` (verify `PATH`, `LD_LIBRARY_PATH`, `NVM_DIR`, `NO_BROWSER` exports).
    *   Check if `~/.bashrc` sources the file: `grep -q "source \"/workspaces/Ubuntu_Scripts_1/utils/ubuntu_scripts_env.sh\"" ~/.bashrc && echo "Sourcing line found"`
    *   Open a new terminal session and verify environment variables: `echo $PATH`, `echo $LD_LIBRARY_PATH`, `echo $NVM_DIR`, `echo $NO_BROWSER`.
3.  **Expected Outcome:** `utils/ubuntu_scripts_env.sh` is created/updated with correct environment variables, and `~/.bashrc` sources it, making the variables persistent across sessions.

### Function: `install_core_utilities()`

**Purpose:** Performs `apt update`, configures keyboard, and installs fundamental `apt` packages.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f install_core_utilities); install_core_utilities"` (or the full script).
2.  **Verification Steps:**
    *   Check for `no-apt-get-warning` marker: `ls ~/.cloudshell/no-apt-get-warning`
    *   Verify `aptitude` installation: `aptitude --version`
    *   Verify `plocate` installation: `plocate --version`
    *   Verify `ffmpeg` installation: `ffmpeg -version`
    *   Verify `aria2` installation: `aria2c --version`
    *   Check keyboard configuration (may require visual inspection or `cat /etc/default/keyboard`).
3.  **Expected Outcome:** Specified core utilities are installed, `apt` is updated, and keyboard configuration is set to non-interactive.

### Function: `install_modern_cmake()`

**Purpose:** Ensures the latest version of CMake is installed from Kitware. This is a prerequisite for several subsequent build processes.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f install_modern_cmake); install_modern_cmake"` (or the full script).
2.  **Verification Steps:**
    *   Check Kitware GPG key: `ls /usr/share/keyrings/kitware-archive-keyring.gpg`
    *   Check Kitware repository entry: `cat /etc/apt/sources.list.d/kitware.list` (should contain the correct codename).
    *   Verify CMake version: `cmake --version` (should show a recent version, e.g., 3.20+).
3.  **Expected Outcome:** The Kitware repository is added, and a modern version of CMake is installed.

### Function: `install_deb_local()`

**Purpose:** Installs a `.deb` package into `$HOME/.local/bin` and `$HOME/.local/lib` without `sudo dpkg -i`.

**Test Steps (Manual Verification):**

1.  **Pre-condition:** Ensure a `.deb` file (e.g., `gotop_3.0.0_linux_amd64.deb` downloaded by `install_system_tools`) is available.
2.  **Execution:** The `install_system_tools` function calls this. To test in isolation: `bash -c "$(declare -f install_deb_local); install_deb_local /path/to/downloaded/gotop_3.0.0_linux_amd64.deb"`
3.  **Verification Steps:**
    *   Check for the installed binary: `ls -l $HOME/.local/bin/gotop`
    *   Check if `gotop` is executable: `gotop --version` (should display version info).
    *   Check if the local bin directory is in PATH: `echo $PATH | grep "$HOME/.local/bin"`
    *   Check for libraries (if applicable to the deb): `ls -l $HOME/.local/lib/`
4.  **Expected Outcome:** The specified `.deb` package's binaries are installed in `$HOME/.local/bin`, are executable, and the local bin path is correctly added to `PATH`.

### Function: `install_ai_tools()`

**Purpose:** Installs `rust-just` and various Python AI/ML packages.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f install_ai_tools); install_ai_tools"` (or the full script).
2.  **Verification Steps:**
    *   Verify `rust-just` installation: `just --version`
    *   Verify Python packages:
        *   `python -c "import whisperx"`
        *   `python -c "import torch"`
        *   `python -c "import tensorflow"`
        *   `python -c "import jax"`
        *   `python -c "import numpy"`
        *   (Each command should execute without import errors).
3.  **Expected Outcome:** `rust-just` is installed globally, and all specified Python AI/ML libraries are successfully installed and importable.

### Function: `configure_xrdp()`

**Purpose:** Installs and configures XRDP for remote desktop access.

**Testing Status:** Skipped.
**Reason for Skipping:** This function is currently commented out in the `main_setup_orchestrator` within `install_basic_ubuntu_set_1.sh`. It is not executed as part of the standard setup process.

### Function: `install_system_tools()`

**Purpose:** Installs a broad range of system and development tools, including building `cpufetch` and `fastfetch` from source, and installing `gotop`.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f install_system_tools); install_system_tools"` (or the full script).
2.  **Verification Steps:**
    *   **Core dev tools:** Verify installation of `pciutils`, `build-essential`, `cmake`, `curl`, `libomp-dev`, `libssl-dev`, `adb`, `fastboot`, `neofetch`, `geoip-bin`, `ranger`, `baobab`, `firefox`, `python3-pip`, `ncdu`, `mediainfo`, `grub-customizer`, `scrcpy`, `glow`. (e.g., `command -v <tool_name>`, `dpkg -l | grep <package_name>`)
    *   **`cpufetch`:** `command -v cpufetch` and `cpufetch` (should display CPU info).
    *   **`fastfetch`:** `command -v fastfetch` and `fastfetch` (should display system info).
    *   **`gotop`:** `command -v gotop` and `gotop --version` (should display version).
    *   **`yt-dlp` / `youtube-dl`:** `command -v yt-dlp` and `yt-dlp --version`.
    *   **`peakperf`:** `command -v peakperf` and `peakperf --help`.
    *   **Android Platform Tools:** `command -v adb` and `adb devices`.
    *   **Charm APT key/repo:** `ls /etc/apt/keyrings/charm.gpg` and `cat /etc/apt/sources.list.d/charm.list`.
3.  **Expected Outcome:** All specified system and development tools are installed and accessible, with `cpufetch`, `fastfetch`, and `peakperf` built from source if necessary.

### Function: `build_llama()`

**Purpose:** Clones and builds the `llama.cpp` project.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f build_llama); build_llama"` (or the full script).
2.  **Verification Steps:**
    *   Check `llama.cpp` repository: `ls -ld ~/Downloads/GitHub/llama.cpp`
    *   Check build directory: `ls -ld ~/Downloads/GitHub/llama.cpp/build`
    *   Check for built binaries (e.g., `main`, `quantize`): `ls ~/Downloads/GitHub/llama.cpp/build/bin/`
    *   Verify installation in local bin: `ls $HOME/.local/bin/llama.cpp` (or similar, depending on `CMAKE_INSTALL_PREFIX` effectiveness).
3.  **Expected Outcome:** `llama.cpp` is cloned, built successfully, and relevant binaries are available.

### Function: `install_gemini_cli()`

**Purpose:** Installs the Google Gemini CLI.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f install_gemini_cli); install_gemini_cli"` (or the full script).
2.  **Verification Steps:**
    *   Verify `gemini` CLI installation: `command -v gemini`
    *   Check `gemini` version: `gemini --version`
    *   Verify `NO_BROWSER` environment variable: `echo $NO_BROWSER` (should output `1`).
3.  **Expected Outcome:** The Google Gemini CLI is installed globally and the `NO_BROWSER` environment variable is set.

### Function: `install_nodejs_nvm()`

**Purpose:** Installs Node.js and npm using NVM for flexible version management.

**Testing Status:** Skipped.
**Reason for Skipping:** This function is currently commented out in the `main_setup_orchestrator` within `install_basic_ubuntu_set_1.sh`. It is not executed as part of the standard setup process.

### Function: `display_system_info()`

**Purpose:** Displays system information and creates the installation marker file.

**Test Steps (Manual Verification):**

1.  **Execution:** Run `bash -c "$(declare -f display_system_info); display_system_info"` (or the full script).
2.  **Verification Steps:**
    *   Observe the console output for `cpufetch`, `peakperf`, `neofetch`, `fastfetch` output.
    *   Verify external IP display: `curl -s https://ipinfo.io/ip` (should show your public IP).
    *   Check for marker file: `ls "$(dirname "$0")/.installed_basic_set_1"` (should exist).
3.  **Expected Outcome:** System information is displayed, and the `.installed_basic_set_1` marker file is created.

### Main Orchestration: `main_setup_orchestrator()`

**Purpose:** Orchestrates the execution of core setup functions in a defined logical sequence.

**Testing Status:** Skipped for isolated testing.
**Reason for Skipping:** The `main_setup_orchestrator` function's primary role is to call other functions. Its successful operation is implicitly verified by the successful execution and verification of all the individual functions it calls. Testing the orchestrator directly would involve running the entire script, which is covered by the overall test strategy.

### Function: `replit_adapt()` (Conditional/Optional)

**Purpose:** Contains specific adaptations for the Replit environment.

**Testing Status:** Skipped.
**Reason for Skipping:** This function is not called by default in the `main_setup_orchestrator` and is specific to the Replit environment, which is not the primary testing environment (GitHub Codespace/GCloud) for this plan.