# GEMINI.md - Video and Audio Processing Capabilities

This document outlines the powerful suite of scripts available for analyzing and processing video and audio files. These scripts are located in `/home/zezen/Downloads/GitHub/Ubuntu_Scripts_1/ai_ml/`, but be aware that script names may be updated or have slight variations. The focus should be on the capabilities these scripts provide.

## 1. Comprehensive Video Analysis

To understand the content of a video, I can leverage a two-pronged approach that analyzes both its visual and audio components.

### Visual Scene Analysis

*   **Capability:** I can extract key visual scenes from a video and generate rich, human-like descriptions of what is happening in each scene. This allows me to build a narrative and understand the story of the video.
*   **Primary Scripts:**
    *   `ffmpeg_scenes_into_images_and_describe.sh`: This is the main script that orchestrates the scene detection and description process.
    *   `describe_images.sh`: This script is called by the main script to perform the actual image description using a local Vision Language Model (VLM).
*   **Output:** The process generates a set of scene images, and an HTML report that combines these images with their descriptions and timestamps, creating a browsable summary of the video.

### Audio Content Analysis

*   **Capability:** I can analyze the audio track of a video to identify the instruments being played, the presence of singing, and the overall musical genre.
*   **Primary Script:** `audioset_tagging_cnn_inference.py`
*   **Output:** This script produces a CSV file with detailed, time-stamped audio event data and a corresponding PNG spectrogram that visualizes the audio landscape of the video.

By combining the visual and audio analyses, I can provide a comprehensive and nuanced summary of any given video.

## 2. Advanced Audio and Speech Processing

Beyond the general analysis, I have access to scripts for more specific and advanced audio processing tasks.

### High-Quality Transcription

*   **Capability:** I can transcribe speech from audio and video files with high accuracy using WhisperX. For very large files or computationally intensive tasks, I can offload the processing to a remote GitHub Codespace.
*   **Primary Scripts:**
    *   `whisperx_me_functions.sh`: For local transcription.
    *   `whisperx_codespace.sh` and `whisperx_codespace_url.sh`: For remote transcription from a file or a URL.

### Emotion and Lyric Analysis

*   **Capability:** I can perform detailed emotion and lyric analysis on video and audio files. This involves transcribing the speech to get the lyrics and then analyzing the vocal tone to detect the emotional content.
*   **Primary Script:** `emotion_detector_funasr_whisperx_plotly.py`
*   **Process:** The script first uses WhisperX to transcribe the audio and get accurate timestamps for the lyrics. It then uses the FunASR model to analyze the emotional content of each spoken segment.
*   **Output:** This process generates several useful files:
    *   An `.srt` file containing the transcribed lyrics with timestamps.
    *   A `.json` file with structured data, linking the lyrics to the detected emotions and their probabilities.
    *   A comprehensive `.html` report that includes interactive Plotly graphs visualizing the emotional arc of the audio, alongside the lyrics and video clips for each segment.
*   **Note on Interpretation:** The emotion detection is based purely on the tonal qualities of the voice (pitch, energy, etc.). It does not understand the meaning of the words. As a result, the emotional labels can sometimes be paradoxical. For example, a calm or melodic singing style might be interpreted as "sad," while high-energy or intense speech might be labeled as "happy," regardless of the actual sentiment of the lyrics. I should use this analysis as a guide to the vocal delivery, not as a definitive measure of the speaker's true feelings.

## 3. Video and Audio Utilities

I also have access to a set of utility scripts for common video and audio manipulation tasks.

### Video Stabilization

*   **Capability:** I can stabilize shaky video footage, with different scripts optimized for different types of motion (e.g., walking vs. general handheld shake).
*   **Primary Scripts:**
    *   `stabilize_video_gait.sh`
    *   `stabilize_video_handheld.sh`

### Text-to-Speech

*   **Capability:** I can synthesize speech from text.
*   **Primary Script:** `piper_me.sh`
