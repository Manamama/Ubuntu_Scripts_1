# Ubuntu Scripts

A powerful and comprehensive collection of scripts for system administration, development, and automation, with a strong focus on AI-powered media analysis. This toolkit is primarily designed for Ubuntu/Debian systems, with adaptations for Termux on Android and remote development environments like GitHub Codespaces.

## Key Features

This repository provides a suite of tools for a wide range of tasks, from setting up a complete development environment to performing sophisticated AI-driven analysis of video and audio files.

### 🤖 AI & Machine Learning

A collection of scripts for advanced media analysis and processing.

*   `ai_ml/ffmpeg_scenes_into_images_and_describe.sh`: A powerful script that performs a deep analysis of video files. It detects scene changes, extracts keyframes as images, and then uses a local Vision Language Model (VLM) to generate detailed, human-like descriptions for each scene.
*   `ai_ml/audioset_tagging_cnn_inference.py`: This script analyzes the audio track of a video to perform sound event detection. It can identify instruments, singing, and the overall musical genre, providing a detailed breakdown of the audio landscape.
*   `ai_ml/emotion_detector_funasr_whisperx_plotly.py`: A sophisticated pipeline that transcribes speech, identifies different speakers (diarization), and performs emotion detection on the vocal tone of the speech. It can generate interactive HTML reports with visualizations of the emotional arc of a conversation.
*   `ai_ml/whisperx_me_functions.sh`, `ai_ml/whisperx_codespace.sh`, `ai_ml/whisperx_codespace_url.sh`: A suite of scripts for high-quality speech-to-text transcription using WhisperX, with options for local execution or offloading the task to a remote GitHub Codespace.
*   `ai_ml/piper_me.sh`: A utility for text-to-speech synthesis using the Piper TTS engine.

### 🛠️ System & Development Utilities

Scripts for setting up and managing your development environment.

*   `setup/install_basic_ubuntu_set_1.sh`: A comprehensive script to bootstrap a new Ubuntu/Debian system with a full development and AI environment.
*   `utils/`: A collection of utility scripts for various tasks, including:
    *   `gh_codespace_mount_login.sh`: For connecting to and managing GitHub Codespaces.
    *   `gcloud_mount_login.sh`: For connecting to Google Cloud Shell.
    *   `stabilize_video_gait.sh` & `stabilize_video_handheld.sh`: For stabilizing shaky video footage.
    *   `puml-viewer.sh`: A viewer for PlantUML diagrams.

### 📄 Document Processing

Tools for working with documents and text.

*   `doc_processing/docling_me.sh`: A script for processing PDFs and images with OCR and converting them to Markdown.
*   `doc_processing/unhyphenate.py`: A Python script to remove hyphens from text files.
*   `doc_processing/wiki_feed_html_renderer.py`: A script to fetch and render a Wikipedia user's contributions as an HTML page.

### 🎨 Terminal FX

A collection of fun and useful scripts for showcasing the power of the terminal.

*   `terminal_fx/ansi_tests/`: A suite of scripts that demonstrate various ANSI terminal capabilities, from text attributes and colors to animations.

## Usage

Most scripts are self-documenting. For more detailed information on the project's structure and capabilities, please see the `GEMINI.md` file.

For general shell shortcuts and tips, refer to `docs/shortcuts.md`.