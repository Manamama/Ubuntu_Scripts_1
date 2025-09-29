#!/bin/bash
#
# Simple two-pass video stabilizer using FFmpeg + vid.stab
# Detects camera shake, reports average/max motion, and outputs stabilized video.
#

# --- Usage check ---
if [ -z "$1" ]; then
  echo "Usage: $0 <video_file>"
  echo "Example: $0 MOVI0015.avi"
  exit 1
fi

video_filename="$1"
if [ ! -f "$video_filename" ]; then
  echo "Error: file not found: $video_filename"
  exit 2
fi

# Generate stabilized output filename
video_filename_stabilized="${video_filename%.*}_stabilized_handheld.mp4"

# --- Intro / goal message ---
echo
echo "-----------------------------------------------"
echo " VIDEO STABILIZATION PIPELINE, version 2.2.0"
echo "-----------------------------------------------"
echo "Goal: Detect and reduce random handheld camera shake. Script assumes chaotic, jittery motion and performs full statistical smoothing."
echo "      This script performs two passes:"
echo "        1) Motion analysis (vidstabdetect)"
echo "        2) Motion correction (vidstabtransform)"
echo
echo "Input:  $video_filename"
echo "Output: $video_filename_stabilized"
echo "-----------------------------------------------"
echo

# Show media info (optional)
mediainfo "$video_filename" | grep -E "Format/Info|Duration|Width|Height|Frame rate" | lolcat


echo It takes about 10 times longer than the video duration, on mobile, to process.

# --- Step 1: Detect camera motion ---
echo
echo "[1/3] Detecting motion..."
time ffmpeg -hide_banner -loglevel warning \
  -i "$video_filename" \
  -vf vidstabdetect=shakiness=5:accuracy=15 \
  -f null -

if [ ! -f transforms.trf ]; then
  echo "Error: transforms.trf not found. Motion detection failed."
  exit 3
fi

# --- Step 2: Analyze motion data ---
echo
echo "[2/3] Analyzing detected motion..."

awk '/^#/ {next} {x=$2; y=$3; mag=sqrt(x*x + y*y); print mag}' transforms.trf > motion_magnitudes.txt

avg_shake=$(awk '{sum+=$1; n++} END {if (n>0) print sum/n; else print 0}' motion_magnitudes.txt)
max_shake=$(sort -nr motion_magnitudes.txt | head -n1)

echo
echo "Average motion magnitude: ${avg_shake:-N/A} pixels"
echo "Maximum motion magnitude: ${max_shake:-N/A} pixels"
echo

# --- Step 3: Apply stabilization ---
echo "[3/3] Applying stabilization..."
time ffmpeg -hide_banner -loglevel warning \
  -i "$video_filename" \
  -vf vidstabtransform=input=transforms.trf:smoothing=30:zoom=5:optzoom=1,unsharp=5:5:0.8:3:3:0.4 \
  -c:v libx264 -crf 18 -c:a copy \
  "$video_filename_stabilized"

# --- Summary ---
echo
echo "-----------------------------------------------"
echo " STABILIZATION SUMMARY"
echo "-----------------------------------------------"
echo "Input file:       $video_filename"
echo "Output file:      $video_filename_stabilized"
echo "Avg shake (px):   ${avg_shake:-N/A}"
echo "Max shake (px):   ${max_shake:-N/A}"
echo "Method:           Two-pass vid.stab (detect + transform)"
echo "Parameters:       shakiness=5, accuracy=15, smoothing=30, zoom=5%"
echo "Output codec:     H.264 (CRF 18, near-lossless)"
echo "-----------------------------------------------"
echo
echo "Done. The stabilized file is ready."
echo
