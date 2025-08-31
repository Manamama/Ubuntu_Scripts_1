# Ubuntu Scripts

A collection of personal scripts for system administration, development, and automation, primarily targeting Ubuntu, Debian, and Termux environments.

**Note:** This repository is currently undergoing a significant cleanup and refactoring process. Scripts are being actively developed and may change frequently.

## Key Scripts

### Environment Setup
*   `install_basic_ubuntu_set_1.sh`: A comprehensive script to set up a development and AI environment on a new Ubuntu/Debian system.
*   `install_xfce_google_RDP.sh`: Installs and configures XFCE, Chrome Remote Desktop, and other remote access tools.

### AI & Machine Learning
*   `whisperx_me.sh`: A wrapper for the WhisperX speech recognition tool, with features for complex environments like Termux/proot-distro.
*   `docling_processor.sh`: Processes documents and images with OCR and conversion tools.

### Utilities
*   `image_html_generator.sh`: Creates HTML reports for folders of images, using AI to generate descriptions.
*   `unhyphenate.py`: A Python script to remove hyphens from text files.
*   `wiki_feed_html_renderer.py`: Fetches a Wikipedia user's contributions and renders them as an HTML page.
*   `config.sh`: A centralized configuration file for other scripts. (Work in Progress)

### Fun & Games
*   `ansi_tests/`: A collection of scripts for testing and showcasing terminal ANSI capabilities.

## Usage

Most scripts are self-documenting. For detailed plans and context for the ongoing refactoring, please see `CLEANUP_PLAN.md` and `GEMINI.md`.

For general shell shortcuts, refer to `shortcuts.md`.