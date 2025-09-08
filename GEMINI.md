# GEMINI.md - AI Context File

**Author:** Gemini AI Agent
**Purpose:** This document provides context for AI assistants interacting with the `Ubuntu_Scripts_1` repository. It outlines the current cleanup and refactoring objectives.

---
### **Project Status**

The initial, large-scale refactoring of the main `install_basic_ubuntu_set_1.sh` script is complete. The repository has been organized into thematic modules (`ai_ml`, `doc_processing`, `utils`, etc.). The `docs/TEST_PLAN.legacy.md` file contains the test plan for the completed first phase.

---
### **Current Objective: Modular Cleanup**

The next phase of this project is to refactor and improve the individual scripts within each module. The focus is on improving code quality, consistency, and maintainability.

---
## Cleanup Plan by Module

### 1. `ai_ml/` - AI & Machine Learning Utilities

This module contains scripts for interacting with AI/ML models.

*   **`whisperx_me.sh`**:
    *   **Goal:** Refactor this complex script for clarity and robustness.
    *   **Tasks:**
        *   Break down large functions into smaller, single-purpose ones.
        *   Parameterize hardcoded paths (e.g., `~/Downloads/`).
        *   Add more robust error handling and user feedback.
        *   Improve comments to explain the script's logic.
*   **`piperme_function.sh`**:
    *   **Goal:** Improve this simple function.
    *   **Tasks:**
        *   Add comments explaining its purpose and usage.
        *   Allow the path to the Piper model to be passed as an argument.

### 2. `doc_processing/` - Text & Document Processing

This module contains scripts for text and document manipulation.

*   **`docling_processor.sh`**:
    *   **Goal:** Improve the clarity and reliability of this processing script.
    *   **Tasks:**
        *   Add comments to explain the purpose of the script and the logic of the `sed` and `awk` commands.
        *   Add error handling to gracefully manage failures from the Python scripts it calls.
*   **`unhyphenate.py` & `wiki_feed_html_renderer.py`**:
    *   **Goal:** Bring these Python scripts up to a higher standard of code quality.
    *   **Tasks:**
        *   Add type hinting for function arguments and return values.
        *   Ensure both scripts have clear docstrings and comments.

### 3. `utils/` - System & Development Utilities

This module contains various helper scripts.

*   **`gcloud_mount_login.sh`**:
    *   **Goal:** Consolidate and improve the GCloud mounting scripts.
    *   **Tasks:**
        *   There are multiple similar files (`gcloud_mount_login_test.sh`, `GCloud_mount_login.sh`). These should be reviewed and consolidated into a single, robust script.
        *   Improve error handling and user feedback messages.
*   **`git_me.sh`**:
    *   **Goal:** Make this git helper script more flexible.
    *   **Tasks:**
        *   Modify the script to accept a commit message as a command-line argument instead of using a hardcoded one.
        *   Add checks to ensure it's being run inside a git repository.
---
### **User-Specific Context**

*   **Home Directory (`~`):** The user's home directory (`/home/codespace`) contains relevant files, including audio files in the `Downloads` subdirectory. The user has indicated that this directory should be considered accessible for operations.
*   **FunASR Repository:** The `FunASR` speech recognition toolkit has been cloned to `~/Github/FunASR`.
---

---
### **FunASR Speech Recognition Toolkit**

*   **Status:** Successfully tested and confirmed working.
*   **Basic Syntax:** The command-line interface can be used for quick transcription tasks. The general syntax is:
    ```bash
    funasr ++model=<model_name> ++input=<file_path>
    ```
*   **Multi-lingual Support:** When using FunASR, it is important to select the appropriate model for the language of the audio. Hardcoding a model for a specific language (e.g., Chinese) will result in incorrect transcriptions for other languages. The `SenseVoice` model is a good option for multi-language ASR.
*   **Emotion Recognition:** FunASR includes models for speech emotion recognition (e.g., `emotion2vec+large`). This allows for the analysis of emotions in audio and video files, in addition to transcription.
---

---
### **Workflow: Analyzing Media from URLs**

*   **Objective:** Analyze the emotional content of an audio or video file from a URL.
*   **Toolchain:**
    1.  **Download:** Use the `yt-dlp` command-line tool to download the media. The tool is invoked via `run_shell_command`.
    2.  **Storage:** Downloaded files should be placed in the `~/Downloads` directory.
    3.  **Analysis:** Use a temporary Python script with the `funasr` library to perform the emotion recognition. The script should be created in the workspace and then executed.
*   **Example Command:**
    ```bash
    # 1. Download the media
    yt-dlp -P ~/Downloads <URL>

    # 2. Create and run the analysis script (see previous examples)
    ```
---