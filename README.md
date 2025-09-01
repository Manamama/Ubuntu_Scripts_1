# Ubuntu Scripts

A collection of personal scripts for system administration, development, and automation, primarily targeting Ubuntu, Debian, and Termux environments.

**Note:** This repository is currently undergoing a significant cleanup and refactoring process. Scripts are being actively developed and may change frequently.

## Key Scripts

### setup/ (Environment Setup & Installation)
*   `install_basic_ubuntu_set_1.sh`: A comprehensive script to set up a development and AI environment on a new Ubuntu/Debian system, including XFCE desktop, Chrome Remote Desktop, TeamViewer, and XRDP configuration.

### ai_ml/ (AI & Machine Learning Utilities)
*   `piperme_function.sh`: A function for Piper text-to-speech.
*   `whisperx_codespace.sh`: Script for running WhisperX in Codespaces.
*   `whisperx_me.sh`: A wrapper for the WhisperX speech recognition tool, with features for complex environments like Termux/proot-distro.

### doc_processing/ (Text & Document Processing)
*   `docling_processor.sh`: Processes documents and images with OCR and conversion tools.
*   `image_html_generator.sh`: Creates HTML reports for folders of images, using AI to generate descriptions.
*   `unhyphenate.py`: A Python script to remove hyphens from text files.
*   `wiki_feed_html_renderer.py`: Fetches a Wikipedia user's contributions and renders them as an HTML page.

### utils/ (System Utilities & Customization)
*   `bashrc-gcloud.sh`: GCloud specific bashrc configurations.
*   `git_me.sh`: Git utility scripts.
*   `puml-viewer.sh`: PlantUML viewer script.
*   `ubuntu_scripts_env.sh`: Environment variables for Ubuntu scripts.
*   `unicode_ui.sh`: Unicode UI related scripts.
*   `X11.sh`: X11 related scripts.
*   `config.sh`: A centralized configuration file for other scripts. (Now handled by `utils/ubuntu_scripts_env.sh` for persistent environment variables)

### terminal_fx/ (Terminal Effects & Customization)
*   `ansi_tests/`: A collection of scripts for testing and showcasing terminal ANSI capabilities.

## Usage

Most scripts are self-documenting. For detailed plans and context for the ongoing refactoring, please see `CLEANUP_PLAN.md` and `GEMINI.md`.

For general shell shortcuts, refer to `shortcuts.md`.