#!/bin/bash

# config.sh
# Centralized configuration for Ubuntu_Scripts_1

# LLM Model Paths for image_html_generator.sh
# These paths are typically found in /storage/emulated/0/LLMs/ on Android/Termux
export LLAVA_MODEL_PATH="/storage/emulated/0/LLMs/MobileVLM-3B-Q4_K_M.gguf"
export LLAVA_MMPROJ_PATH="/storage/emulated/0/LLMs/MobileVLM-3B-mmproj-f16.gguf"

# Sound Alert Path for docling_processor.sh
export SOUND_ALERT_PATH="/home/zezen/Music/Timer_and_sounds/ping_finished_ocrpdf-ing.wav"
