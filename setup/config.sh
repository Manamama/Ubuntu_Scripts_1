#!/bin/bash
#
# Description: Centralized configuration file for specific environment variables used by various scripts.
#              This file defines paths for LLM models and sound alerts, primarily for local/mobile environments.
#              Note: General persistent environment variables are now managed by `utils/ubuntu_scripts_env.sh`.
#
# Usage:
#   This file is typically sourced by other scripts that require these specific configurations.
#   Example: source /path/to/config.sh
#
# Last Modified: August 31, 2025

# LLM Model Paths for image_html_generator.sh
# These paths are typically found in /storage/emulated/0/LLMs/ on Android/Termux
export LLAVA_MODEL_PATH="/storage/emulated/0/LLMs/MobileVLM-3B-Q4_K_M.gguf"
export LLAVA_MMPROJ_PATH="/storage/emulated/0/LLMs/MobileVLM-3B-mmproj-f16.gguf"

# Sound Alert Path for docling_processor.sh
export SOUND_ALERT_PATH="/home/zezen/Music/Timer_and_sounds/ping_finished_ocrpdf-ing.wav"
