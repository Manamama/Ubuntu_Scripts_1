import os
import argparse
import json
import whisperx
from funasr import AutoModel
from pydub import AudioSegment
import plotly.graph_objects as go
import pandas as pd
import webbrowser
from pathlib import Path
from urllib.parse import quote
import re
import torch


#Version by Grok AI. https://grok.com/c/734642ab-c01a-4661-8780-dfe09f041d46

# Args parser
parser = argparse.ArgumentParser(description="Simplified emotion detection using WhisperX and FunASR")
parser.add_argument("media_path", type=str, help="Path to the media file")
parser.add_argument("--language", type=str, default="", help="Language code (default: autodetect)")
parser.add_argument("--hf_token", type=str, default=os.getenv("HF_TOKEN", ""), help="Hugging Face token for pyannote")
args = parser.parse_args()
#Simplified version of: emotion_detector_funasr_whisperx_plotly.py, prepared for GitHub Codespace
print(f"Emotions detector via Whisperx (voice activity detection, chunking, transcription) and FunASR, version 6.0.2")


# Setup paths
media_path = Path(args.media_path)
stem = media_path.stem
output_dir = media_path.parent / (stem + "_emotions_detected")
output_dir.mkdir(exist_ok=True)
output_html_path = output_dir / (stem + "_emotions.html")
output_json_path = output_dir / (stem + "_emotions.json")

# WhisperX setup
device = "cuda" if torch.cuda.is_available() else "cpu"  # Use GPU if available
batch_size = 16 if device == "cuda" else 2
compute_type = "float16" if device == "cuda" else "float32"
whisperx_model_size = "large-v3"  # Upgraded to better ASR model

# Load WhisperX model
model = whisperx.load_model(whisperx_model_size, device, compute_type=compute_type)

# Step 1: Transcribe with WhisperX to get sentence timecodes
audio = whisperx.load_audio(media_path)
result = model.transcribe(audio, batch_size=batch_size, language=args.language if args.language else None)

# Align for word-level timestamps, then aggregate to sentences
model_a, metadata = whisperx.load_align_model(language_code=result["language"], device=device)
result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False)

# Add speaker diarization with improved pyannote model
if args.hf_token:
    diarize_model = whisperx.DiarizationPipeline(model_name="pyannote/speaker-diarization-3.1", use_auth_token=args.hf_token, device=device)
    diarization = diarize_model(audio)
    result = whisperx.assign_word_speakers(diarization, result)
else:
    print("Warning: No HF_TOKEN provided; skipping diarization.")

# Extract sentence-level segments (start/end in seconds, text, speaker)
sentences_data = []
for seg in result["segments"]:
    start = seg["start"]
    end = seg["end"]
    text = seg["text"]
    speaker = seg.get("speaker", "Unknown")
    sentences_data.append({"start": start, "end": end, "text": text, "speaker": speaker})

# Load full audio once for chunking
full_audio = AudioSegment.from_file(media_path)

# Step 2: Chunk audio based on timestamps
chunks = []
for i, seg in enumerate(sentences_data):
    start_ms = int(seg["start"] * 1000)
    end_ms = int(seg["end"] * 1000)
    chunk_audio = full_audio[start_ms:end_ms]
    chunk_file = output_dir / f"{stem}_segment_{i:03d}.mp3"
    chunk_audio.export(chunk_file, format="mp3")
    chunks.append(chunk_file)

# Create SCP file for FunASR batch input
scp_path = output_dir / (stem + "_chunks.scp")
with open(scp_path, "w") as f:
    for i, chunk in enumerate(chunks):
        f.write(f"segment_{i:03d}\t{chunk}\n")

# Step 3: Load improved emotion model (SenseVoice) and analyze chunks (utterance level)
emotion_model = AutoModel(model="iic/SenseVoiceSmall")
rec_result = emotion_model.generate(input=str(scp_path), output_dir=output_dir, granularity="utterance")

# Possible emotion labels from SenseVoice
possible_labels = ["angry", "happy", "neutral", "sad", "unknown"]

# Collect results with timestamps/text/speaker
emotion_results = []
for i, res in enumerate(rec_result):
    seg = sentences_data[i]
    text_output = res["text"]
    
    # Parse emotion label from SenseVoice output (e.g., <|SAD Sad|>)
    emotion_match = re.search(r'<\|[A-Z]+ (\w+)\|>', text_output)
    emotion_label = emotion_match.group(1).lower() if emotion_match else "unknown"
    
    # Create emotions list with score 1.0 for predicted, 0.0 for others (for visualization compatibility)
    emotions = [{"label": l, "score": 1.0 if l == emotion_label else 0.0} for l in possible_labels]
    
    emotion_results.append({
        "speaker": seg["speaker"],
        "sentence": seg["text"],
        "start_time_s": seg["start"],
        "end_time_s": seg["end"],
        "emotions": emotions
    })

# Save JSON
with open(output_json_path, "w", encoding="utf-8") as f:
    json.dump(emotion_results, f, ensure_ascii=False, indent=4)
print(f"Results saved as JSON to: {output_json_path}")

# Step 4: Generate HTML with Plotly line graph
with open(output_html_path, "w", encoding="utf-8") as f:
    f.write('<html><head><meta charset="UTF-8"><title>Emotion Visualization</title>')
    f.write('<script src="https://cdn.plot.ly/plotly-latest.min.js"></script></head><body>')
    f.write(f'<h1>Emotion Scores for {media_path.name}</h1>')

    # Prepare Plotly data
    times = [res["start_time_s"] for res in emotion_results]
    if emotion_results:
        # Use possible labels
        labels = possible_labels
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

    # Table of results with speaker
    f.write("<table border='1'><tr><th>Speaker</th><th>Time</th><th>Sentence</th><th>Emotions</th></tr>")
    for res in emotion_results:
        emotions_str = ", ".join([f"{emo['label']}: {emo['score']:.3f}" for emo in res["emotions"]])
        f.write(f"<tr><td>{res['speaker']}</td><td>{res['start_time_s']:.2f}-{res['end_time_s']:.2f}</td><td>{res['sentence']}</td><td>{emotions_str}</td></tr>")
    f.write("</table></body></html>")

print(f"Results saved as HTML to: {output_html_path}")

# Open HTML in browser
webbrowser.open(f"file://{os.path.abspath(output_html_path)}")
