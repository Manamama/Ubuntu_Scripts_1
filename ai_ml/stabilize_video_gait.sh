#!/bin/bash
#
# Low-Frequency Walking Stabilizer (FFmpeg + vid.stab)
# Targets rhythmic sway from walking or body-mounted cameras.
# Designed for subtle, periodic motion — not random handheld jitter.
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

video_filename_stabilized="${video_filename%.*}_stabilized_gait.mp4"

# --- Intro / goal message ---
echo
echo "----------------------------------------------------"
echo " WALKING MOTION STABILIZATION PIPELINE, version 2.1.0"
echo "----------------------------------------------------"
echo "Goal: Reduce rhythmic sway and gentle bobbing caused  by footsteps or body-mounted camera movement. Script assumes periodic sway, analyzes low-frequency patterns, and applies delicate correction"
echo
echo "Contrast with version 1:"
echo "  - Version 1: tripod-style stabilization for random handheld jitter (strong smoothing, heavy zoom)."
echo "  - This version: preserves gait rhythm, corrects   low-frequency oscillations (light smoothing,  adaptive zoom, fine motion detection)."
echo
echo "Input:  $video_filename"
echo "Output: $video_filename_stabilized"
echo "----------------------------------------------------"
echo

# Optional quick media info
mediainfo "$video_filename" | grep -E "Format/Info|Duration|Width|Height|Frame rate" | lolcat

# --- Step 1: Detect walking motion (commented, optional) ---
echo
echo "[1/3] Detecting periodic walking motion..."
time ffmpeg -hide_banner -loglevel warning \
  -i "$video_filename" \
  -vf vidstabdetect=shakiness=8:accuracy=15:stepsize=2:mincontrast=0.05:tripod=0 \
  -f null -

if [ ! -f transforms.trf ]; then
  echo "Error: transforms.trf not found. Motion detection failed."
  exit 3
fi

# --- Step 2: Analyze motion data in 1s windows ---
echo
echo "[2/3] Analyzing low-frequency motion (1s windows)..."

awk '/^#/ {next} {
  x=$2; y=$3; rot=$4;
  abs_rot = (rot >= 0 ? rot : -rot);
  mag = sqrt(x*x + y*y) + 0.1*abs_rot;
  frame = $1;
  if (frame % 30 == 0 || frame == 1) {
    if (sum > 0) { print sum/30 > "motion_magnitudes.txt" }
    sum = mag; count = 1
  } else {
    sum += mag; count += 1
  }
}
END { if (count > 0) { print sum/count > "motion_magnitudes.txt" } }' transforms.trf

avg_shake=$(awk '{sum+=$1; n++} END {if (n>0) print sum/n; else print 0}' motion_magnitudes.txt)
max_shake=$(sort -nr motion_magnitudes.txt | head -n1)

echo
echo "Average walking motion amplitude (px, per 1s): ${avg_shake:-N/A}"
echo "Maximum amplitude (px, per 1s): ${max_shake:-N/A}"
echo

# --- Step 3: Apply stabilization tuned for walking motion ---
echo "[3/3] Applying walking stabilization..."
time ffmpeg -hide_banner -loglevel warning \
  -i "$video_filename" \
  -vf vidstabtransform=input=transforms.trf:smoothing=10:zoom=1:optzoom=2:interpol=bicubic,unsharp=3:3:0.4:3:3:0.2 \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy \
  "$video_filename_stabilized"

# --- Summary ---
echo
echo "----------------------------------------------------"
echo " STABILIZATION SUMMARY"
echo "----------------------------------------------------"
echo "Input file:       $video_filename"
echo "Output file:      $video_filename_stabilized"
echo "Avg motion (px):  ${avg_shake:-N/A}"
echo "Max motion (px):  ${max_shake:-N/A}"
echo
echo "Motion type:      Low-frequency (walking sway)"
echo "Detection params: shakiness=8, accuracy=15, stepsize=2"
echo "Transform params: smoothing=10 (~0.3s), zoom=1%, optzoom=2"
echo "Interpolation:    Bicubic (smooth subpixel warps)"
echo "Sharpening:       Mild (3x3 kernel, low strength)"
echo "Output codec:     H.264 CRF18 (visually lossless)"
echo "----------------------------------------------------"
echo
echo "Done. Stabilized walking-motion video generated."
echo
