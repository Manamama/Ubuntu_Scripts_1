#!/bin/bash

# Check if video path is provided and handle optional scene_threshold.
# Also, if the user gives fewer than 1 argument or more than 2, the script complains.
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <video_path> [scene_threshold]"
    echo "  <video_path>      : The path to the video file."
    echo "  [scene_threshold] : Optional. A float value for scene detection sensitivity (e.g., 0.15)."
    echo "                    Higher values detect more abrupt changes, lower values are more sensitive."
    echo "                    Defaults to 0.35 if not provided."
    exit 1
fi

echo "Starting scene detection script..."

# --- CONFIGURATION ---
VIDEO_PATH="$1"
SCENE_THRESHOLD=${2:-0.35} # Default to 0.35 if not provided
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo -n "Using scene detection threshold: "
echo "$SCENE_THRESHOLD" | lolcat


# Check if video file exists
if [ ! -f "$VIDEO_PATH" ]; then
    echo "Error: Video file '$VIDEO_PATH' not found"
    exit 1
fi

# Get video basename and directory
BASENAME=$(basename "$VIDEO_PATH" | sed 's/\.[^.]*$//')
VIDEODIR=$(dirname "$VIDEO_PATH")
OUTPUT_DIR="$VIDEODIR/${BASENAME}_scenes_${SCENE_THRESHOLD}"


# Check if output directory exists and contains scene images
if [ -d "$OUTPUT_DIR" ] && [ -n "$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'scene_ffmpeg_*.png')" ]; then
    echo "Output directory '$OUTPUT_DIR' already contains scene images. Skipping scene detection and processing."
    scene_count=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'scene_ffmpeg_*.png' | wc -l)
    echo -n "⚠️  We have found 📸 the images, so we are skipping recreating them ..."
   
else

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    echo -n "⌚ Source video duration: "
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
    START_TIME=$(date +%s)
    ffmpeg -nostats -i "$VIDEO_PATH"   -vf "select='gt(scene,$SCENE_THRESHOLD)',showinfo" -fps_mode passthrough -f image2 "$OUTPUT_DIR/scene_ffmpeg_%03d.png"  -progress "$PROGRESS_LOG" 2> "$OUTPUT_DIR/showinfo.log" &

    FFMPEG_PID=$!

    # Monitor progress
    while kill -0 $FFMPEG_PID 2>/dev/null; do
        if [ -s "$PROGRESS_LOG" ]; then
            tail -n 12 "$PROGRESS_LOG" | grep -E 'frame=|speed=' | tr '\n' ' ' | tr -s ' ' | sed 's/speed= /speed=/g' | xargs -I {} echo -e "\r{}"
        fi
        sleep 1
    done

fi

# Count the number of generated scene images
scene_count=$(find "$OUTPUT_DIR" -type f -name 'scene_ffmpeg_*.png' | wc -l)

echo -n  "📸 Number of scene images found or created: "
echo "$scene_count" | lolcat

echo -n "At the output directory: " 
echo "$OUTPUT_DIR" | lolcat




# -------------------------------
# 2. Create "sped-up" video from scene images
# -------------------------------
SPEEDUP_VIDEO="$OUTPUT_DIR/${BASENAME}_spedup.mp4"
echo
echo -n "Generating sped-up video at :"
echo "$SPEEDUP_VIDEO" | lolcat

ffmpeg -y  -hide_banner  -loglevel quiet  -framerate 5 -i "$OUTPUT_DIR/scene_ffmpeg_%03d.png" -c:v libx264 -pix_fmt yuv420p "$SPEEDUP_VIDEO"

echo "Sped-up video created."


echo

# Open output directory
echo "Opening output..."
open "$SPEEDUP_VIDEO"
# open "$OUTPUT_DIR"

# --- Integration: Describe Generated Scene Images ---
echo
echo "--- Starting automatic description for generated scenes ---"
DESCRIBE_SCRIPT_PATH="$SCRIPT_DIR/describe_images.sh"
if [ -f "$DESCRIBE_SCRIPT_PATH" ]; then
    bash "$DESCRIBE_SCRIPT_PATH" "$OUTPUT_DIR"
    echo "--- Finished automatic description ---"
else
    echo "Warning: Description script not found at $DESCRIBE_SCRIPT_PATH"
fi
echo 


END_TIME=$(date +%s)

echo "Video processing finished."

# Print processing time
echo -n "Processing time: "
echo "$((END_TIME - START_TIME)) s" | lolcat


# -------------------------------
# 1. Generate HTML Scene Browser
# -------------------------------

#echo OUTPUT_DIR: $OUTPUT_DIR, BASENAME: $BASENAME
HTML_FILE="$OUTPUT_DIR/${BASENAME}_ffmpeg_scenes_index.html"
echo "Generating HTML scene browser at $HTML_FILE..."

# Extract timestamps from showinfo.log
declare -a TS_LIST
while IFS= read -r line; do
    if [[ $line =~ pts_time:([0-9]+\.[0-9]+) ]]; then
        TS_LIST+=("${BASH_REMATCH[1]}")
    fi
done < "$OUTPUT_DIR/showinfo.log"

# Get list of scene images sorted
IMG_LIST=($"$OUTPUT_DIR"/scene_ffmpeg_*.png)
IMG_COUNT=${#IMG_LIST[@]}
TS_COUNT=${#TS_LIST[@]}

VIDEO_TOTAL=$(mediainfo --Inform='Video;%Duration%' "$VIDEO_PATH")
VIDEO_TOTAL=$(echo "scale=3; $VIDEO_TOTAL/1000" | bc)


# If timestamps are fewer than images, extend TS_LIST with VIDEO_TOTAL
if (( TS_COUNT < IMG_COUNT )); then
    for ((i=TS_COUNT; i<IMG_COUNT; i++)); do
        TS_LIST+=("$VIDEO_TOTAL")
    done
fi

# Generate HTML header
cat > "$HTML_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Scene Browser - $BASENAME</title>
<style>
body { font-family: sans-serif; background: #111; color: #eee; }
video { max-width: 80%; margin: 1em 0; display: block; }
table { border-collapse: collapse; width: 100%; }
td, th { border: 1px solid #444; padding: 0.5em; text-align: left; }
img { max-width: 450px; cursor: pointer; }
</style>
</head>
<body>
<h1>Scene Browser - $BASENAME</h1>
<video id="mainVideo" controls>
<source src="../$(basename "$VIDEO_PATH")" type="video/mp4">

  Your browser does not support HTML5 video.
</video>

<table>
<tr><th>Scene Image</th><th>Timestamp (s): Duration (s)</th><th>Description</th></tr>
EOF

# Loop through images and timestamps
for i in "${!IMG_LIST[@]}"; do
    img="${IMG_LIST[i]}"
    ts=${TS_LIST[i]}

    # Compute duration
    if (( i < IMG_COUNT - 1 )); then
        next_ts=${TS_LIST[i+1]}
    else
        next_ts=$VIDEO_TOTAL  # last image uses video total
    fi
    duration=$(echo "$next_ts - $ts" | bc -l)

    # Extract description from image EXIF
    description=$(exiftool -s3 -Description "$img")

    # Write table row
echo "<tr>
<td><img src=\"$(basename "$img")\" onclick=\"document.getElementById('mainVideo').currentTime=$ts; document.getElementById('mainVideo').play();\"></td>
<td>$ts: $duration</td>
<td>$description</td>
</tr>" >> "$HTML_FILE"
done

cat >> "$HTML_FILE" << EOF
</table>
</body>
</html>
EOF

echo "HTML scene browser generated."



# Open output directory
echo "Opening output directory..."
open "$OUTPUT_DIR"
