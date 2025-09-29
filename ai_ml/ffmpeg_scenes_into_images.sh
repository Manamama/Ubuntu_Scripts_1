#!/bin/bash

# Check if video path is provided and handle optional scene_threshold
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <video_path> [scene_threshold]"
    echo "  <video_path>      : The path to the video file."
    echo "  [scene_threshold] : Optional. A float value for scene detection sensitivity (e.g., 0.15)."
    echo "                    Higher values detect more abrupt changes, lower values are more sensitive."
    echo "                    Defaults to 0.15 if not provided."
    exit 1
fi

echo "Starting scene detection script..."

VIDEO_PATH="$1"
SCENE_THRESHOLD=${2:-0.15} # Default to 0.15 if not provided

echo "Using scene detection threshold: $SCENE_THRESHOLD"

# Check if video file exists
if [ ! -f "$VIDEO_PATH" ]; then
    echo "Error: Video file '$VIDEO_PATH' not found"
    exit 1
fi

# Get video basename and directory
BASENAME=$(basename "$VIDEO_PATH" | sed 's/\.[^.]*$//')
VIDEODIR=$(dirname "$VIDEO_PATH")
OUTPUT_DIR="$VIDEODIR/${BASENAME}_scenes_${SCENE_THRESHOLD}"

#echo "Video path: $VIDEO_PATH"
#echo "Basename: $BASENAME"
#echo "Video directory: $VIDEODIR"
echo "Output directory: $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -n "⌚ Duration: "
#echo "Extracting audio duration..."
if duration=$(mediainfo --Inform='Audio;%Duration/String2%' "$VIDEO_PATH" 2>/dev/null); then
    
    echo "$duration" | lolcat
else
    echo "⚠️ Could not extract duration (proceeding anyway)" 
fi
echo

PROGRESS_LOG="$OUTPUT_DIR/ffmpeg_progress.log"

# Create the progress log file beforehand to prevent errors
touch "$PROGRESS_LOG"

echo "Starting FFmpeg scene detection... (This may take a while)"
echo "Progress will be shown below:"

# Run FFmpeg with scene detection, saving PNGs at native resolution
# Redirect showinfo output to a log file for parsing
START_TIME=$(date +%s)
ffmpeg -nostats -i "$VIDEO_PATH" \
    -vf "select='gt(scene,$SCENE_THRESHOLD)',showinfo" -fps_mode passthrough -f image2 "$OUTPUT_DIR/scene_ffmpeg_%03d.png" \
    -progress "$PROGRESS_LOG" 2> "$OUTPUT_DIR/showinfo.log" &

FFMPEG_PID=$!

# Monitor progress
while kill -0 $FFMPEG_PID 2>/dev/null; do
    if [ -s "$PROGRESS_LOG" ]; then
        tail -n 12 "$PROGRESS_LOG" | grep -E 'frame=|speed=' | tr '\n' ' ' | tr -s ' ' | sed 's/speed= /speed=/g' | xargs -I {} echo -e "\r{}"
    fi
    sleep 1
done

# Print a newline to move to the next line after the progress indicator
echo

END_TIME=$(date +%s)

echo "FFmpeg processing finished."

# Clean up the progress log
#rm "$PROGRESS_LOG"

# Print processing time
echo -n "Processing time: "
echo $((END_TIME - START_TIME))s | lolcat

# Run Python script to parse showinfo.log and generate scene summary


# Count the number of generated scene images
scene_count=$(find "$OUTPUT_DIR" -type f -name 'scene_ffmpeg_*.png' | wc -l)

echo -n  "📸 Number of scene images created: "
echo "$scene_count" | lolcat

du -h "$OUTPUT_DIR" | lolcat
echo "Opening the output directory: "
echo "$OUTPUT_DIR" | lolcat
termux-open "$OUTPUT_DIR"

#python3 parse_ffmpeg_scenes.py "$OUTPUT_DIR/showinfo.log" "$VIDEO_PATH"