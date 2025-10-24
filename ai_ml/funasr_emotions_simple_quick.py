import os
import argparse
import json
import whisperx
from funasr import AutoModel
import plotly.graph_objects as go
import pandas as pd
import webbrowser
from pathlib import Path
from urllib.parse import quote
import subprocess
import sys



# Args parser
parser = argparse.ArgumentParser(description="Simplified emotion detection, using WhisperX and FunASR")
parser.add_argument("media_path", type=str, help="Path to the media file or a URL to download")
parser.add_argument("--language", type=str, default="", help="Language code (default: autodetect)")
args = parser.parse_args()
#Simplified version of: emotion_detector_funasr_whisperx_plotly.py, prepared for GitHub Codespace
print(f"Emotions detector via Whisperx (voice activity detection, chunking, transcription) and FunASR, version 6.2.3")
print("Still the best pipeline in 2025, see https://grok.com/c/734642ab-c01a-4661-8780-dfe09f041d46 or ./Archive folder why so. It uses: .cache/modelscope/hub/models/iic/emotion2vec_plus_large model")


# Setup paths and handle URL downloading
if args.media_path.startswith("http"):
    print("URL detected. Attempting to download using yt-dlp.")
    print("Note: This uses '--cookies-from-browser chrome' and assumes you have Chrome's cookie database available.")
    download_dir = Path.home() / "Downloads"
    command = [
        "yt-dlp",
        "--cookies-from-browser", "chrome",
        "--no-playlist",
        "--extract-audio", "--audio-format", "mp3",
        "--restrict-filenames", "--trim-filenames", "20",
        "-P", str(download_dir),
        "--print", "after_move:filepath",
        args.media_path
    ]
    print(f"Executing download command...")
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True, encoding='utf-8')
        downloaded_path = result.stdout.strip()
        if not downloaded_path:
            raise ValueError("yt-dlp did not return a file path.")
        media_path = Path(downloaded_path)
        print(f"✅ Successfully downloaded to: {media_path}")
    except (subprocess.CalledProcessError, ValueError) as e:
        print(f"❌ Error downloading URL: {e}", file=sys.stderr)
        if hasattr(e, 'stderr'):
            print(f"yt-dlp stderr: {e.stderr}", file=sys.stderr)
        sys.exit(1)
else:
    media_path = Path(args.media_path)

stem = media_path.stem
output_dir = media_path.parent / (stem + "_emotions_detected")
output_dir.mkdir(exist_ok=True)
output_html_path = output_dir / (stem + "_emotions.html")
output_json_path = output_dir / (stem + "_emotions.json")

# WhisperX setup
device = "cpu"  # Or "cuda" if available
batch_size = 2
compute_type = "float32"
whisperx_model_size = "medium"  # Or "large-v3" or "base", "tiny", the latter needed on Android
# See https://huggingface.co/openai/whisper-large-v3
#whisperx_model_size = "base"  

# Load WhisperX model
model = whisperx.load_model(whisperx_model_size, device, compute_type=compute_type)

# Step 1: Transcribe with WhisperX to get sentence timecodes
audio = whisperx.load_audio(media_path)
result = model.transcribe(audio, batch_size=batch_size, language=args.language if args.language else None)

# Align for word-level timestamps, then aggregate to sentences
model_a, metadata = whisperx.load_align_model(language_code=result["language"], device=device)
result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False, print_progress=True)

# Extract sentence-level segments (start/end in seconds, text)
sentences_data = []
for seg in result["segments"]:
    start = seg["start"]
    end = seg["end"]
    text = seg["text"]
    sentences_data.append({"start": start, "end": end, "text": text})

# Step 2: Chunk audio based on timestamps using a direct ffmpeg call
chunks = []
print("Chunking audio using ffmpeg...")
for i, seg in enumerate(sentences_data):
    start_s = seg["start"]
    end_s = seg["end"]
    # Revert to mp3, as we are now using a reliable encoder
    chunk_file = output_dir / f"{stem}_segment_{i:03d}.mp3"
    
    command = [
        "ffmpeg",
        "-i", str(media_path),
        "-ss", str(start_s),
        "-to", str(end_s),
        "-c:a", "libmp3lame",  # Explicitly use libmp3lame encoder
        "-vn",                # No video stream
        "-loglevel", "error", # Suppress verbose output
        "-y",                 # Overwrite output file if it exists
        str(chunk_file)
    ]
    
    try:
        # Using subprocess to call ffmpeg directly is more robust than relying on pydub's wrapper
        subprocess.run(command, check=True, capture_output=True, text=True)
        chunks.append(chunk_file)
    except FileNotFoundError:
        print("❌ Error: ffmpeg not found. Please install ffmpeg and ensure it is in your system's PATH.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error during ffmpeg execution for segment {i}:", file=sys.stderr)
        print(f"ffmpeg stderr: {e.stderr}", file=sys.stderr)
        print("Please ensure ffmpeg is installed and the libmp3lame codec is available.", file=sys.stderr)
        sys.exit(1)


# Create SCP file for FunASR batch input
scp_path = output_dir / (stem + "_chunks.scp")
with open(scp_path, "w") as f:
    for i, chunk in enumerate(chunks):
        f.write(f"segment_{i:03d}\t{chunk}\n")

# Step 3: Load emotion model and analyze chunks (utterance level)
emotion_model = AutoModel(model="iic/emotion2vec_plus_large")
rec_result = emotion_model.generate(input=str(scp_path), output_dir=output_dir, granularity="utterance", use_itn=True, extract_embedding=False)

# Collect results with timestamps/text
emotion_results = []
for i, res in enumerate(rec_result):
    seg = sentences_data[i]
    # Extract English label part after "/"
    emotions = [{"label": label.split("/")[-1], "score": round(score, 3)} for label, score in zip(res["labels"], res["scores"])]
    emotion_results.append({
        "sentence": seg["text"],
        "start_time_s": seg["start"],
        "end_time_s": seg["end"],
        "emotions": emotions
    })

# Save JSON
with open(output_json_path, "w", encoding="utf-8") as f:
    json.dump(emotion_results, f, ensure_ascii=False, indent=4)
print(f"Results saved as JSON to: {output_json_path}")

# Create and save the AI-friendly flattened JSON
flattened_data = []
for entry in emotion_results:
    new_entry = {
        "sentence": entry["sentence"],
        "start_time_s": entry["start_time_s"],
        "end_time_s": entry["end_time_s"]
    }
    for emotion in entry["emotions"]:
        label = emotion["label"].replace("<", "").replace(">", "")
        new_entry[label] = emotion["score"]
    flattened_data.append(new_entry)

output_ai_json_path = output_dir / (stem + "_emotions_ai_friendly.json")
with open(output_ai_json_path, "w", encoding="utf-8") as f:
    json.dump(flattened_data, f, ensure_ascii=False, indent=4)

print(f"AI-friendly flattened JSON saved to: {output_ai_json_path}")

# Step 4: Generate HTML with Plotly line graph
with open(output_html_path, "w", encoding="utf-8") as f:
    f.write('<html><head><meta charset="UTF-8"><title>Emotion Visualization</title>')
    f.write('<script src="https://cdn.plot.ly/plotly-latest.min.js"></script></head><body>')
    f.write(f'<h1>Emotion Scores for {media_path.name}</h1>')

    # Prepare Plotly data
    times = [res["start_time_s"] for res in emotion_results]
    if emotion_results:
        # Get all unique labels (English only)
        labels = [emo["label"] for emo in emotion_results[0]["emotions"]]
        scores = [[emo["score"] for emo in res["emotions"]] for res in emotion_results]

        fig = go.Figure()
        for i, label in enumerate(labels):
            emotion_scores = [score[i] for score in scores]
            fig.add_trace(go.Scatter(x=times, y=emotion_scores, name=label, mode="lines+markers"))

        fig.update_layout(
            title="Emotion Scores Over Time",
            xaxis_title="Time (s)",
            yaxis_title="Probability",
            hovermode="closest",
            legend=dict(orientation="h", yanchor="bottom", y=-0.5, xanchor="center", x=0.5)
        )
        f.write(fig.to_html(full_html=False, include_plotlyjs="cdn"))

    # Table of results
    f.write("<table border='1'><tr><th>Time</th><th>Sentence</th><th>Emotions</th></tr>")
    for res in emotion_results:
        emotions_str = ", ".join([f"{emo['label']}: {emo['score']:.3f}" for emo in res["emotions"]])
        f.write(f"<tr><td>{res['start_time_s']:.2f}-{res['end_time_s']:.2f}</td><td>{res['sentence']}</td><td>{emotions_str}</td></tr>")
    f.write("</table></body></html>")

print(f"Results saved as HTML to: {output_html_path}")

# Open HTML in browser
#webbrowser.open(f"file://{os.path.abspath(output_html_path)}")
