
import os
import argparse
import json
import re
import torch
from funasr import AutoModel
import plotly.graph_objects as go
import pandas as pd
import webbrowser
from pathlib import Path
from urllib.parse import quote

#Version by Grok AI. https://grok.com/c/734642ab-c01a-4661-8780-dfe09f041d46


# Args parser
parser = argparse.ArgumentParser(description="Integrated emotion detection with SenseVoice")
parser.add_argument("media_path", type=str, help="Path to the media file")
parser.add_argument("--language", type=str, default="", help="Language code (default: autodetect)")
parser.add_argument("--hf_token", type=str, default=os.getenv("HF_TOKEN", ""), help="Hugging Face token for pyannote")
args = parser.parse_args()
#print(f"Emotions detector via SenseVoice-Small, version 2025, integrated pipeline" )
print(f"Emotions detector via SenseVoice-Small (voice activity detection, chunking, transcription) and FunASR, version 8.0.1")

# Setup paths
media_path = Path(args.media_path)
stem = media_path.stem
output_dir = media_path.parent / (stem + "_emotions_detected")
output_dir.mkdir(exist_ok=True)
output_html_path = output_dir / (stem + "_emotions.html")
output_json_path = output_dir / (stem + "_emotions.json")

# SenseVoice setup
device = "cuda" if torch.cuda.is_available() else "cpu"
emotion_model = AutoModel(
    model="iic/SenseVoiceSmall",
    device=device,
    vad_model="fsmn-vad",
    diarization_model="pyannote/speaker-diarization-3.1" if args.hf_token else None,
    hub="hf"
)

# Step 1: Process audio with SenseVoice (transcription, timestamps, speakers, emotions)
results = emotion_model.generate(
    input=str(media_path),
    output_dir=output_dir,
    granularity="utterance",
    language=args.language if args.language else "auto"
)

# Possible emotion labels
possible_labels = ["angry", "happy", "neutral", "sad", "unknown"]

# Step 2: Parse results into structured format
emotion_results = []
for res in results:
    text = res["text"]
    # Extract emotion from <|EMOTION Label|> tags
    emotion_match = re.search(r'<\|[A-Z]+ (\w+)\|>', text)
    emotion_label = emotion_match.group(1).lower() if emotion_match else "unknown"
    # Clean text by removing tags
    clean_text = re.sub(r'<\|.*?\|>', '', text).strip()
    
    # Create emotions list with score 1.0 for predicted, 0.0 for others
    emotions = [{"label": l, "score": 1.0 if l == emotion_label else 0.0} for l in possible_labels]
    
    # Get timestamps and speaker (if diarization enabled)
    start_time = res.get("start_time", 0.0)
    end_time = res.get("end_time", start_time + 1.0)  # Fallback if end_time missing
    speaker = res.get("speaker", "Unknown") if args.hf_token else "Unknown"
    
    emotion_results.append({
        "speaker": speaker,
        "sentence": clean_text,
        "start_time_s": start_time,
        "end_time_s": end_time,
        "emotions": emotions
    })

# Save JSON
with open(output_json_path, "w", encoding="utf-8") as f:
    json.dump(emotion_results, f, ensure_ascii=False, indent=4)
print(f"Results saved as JSON to: {output_json_path}")

# Step 3: Generate HTML with Plotly line graph
with open(output_html_path, "w", encoding="utf-8") as f:
    f.write('<html><head><meta charset="UTF-8"><title>Emotion Visualization</title>')
    f.write('<script src="https://cdn.plot.ly/plotly-latest.min.js"></script></head><body>')
    f.write(f'<h1>Emotion Scores for {media_path.name}</h1>')

    # Prepare Plotly data
    times = [res["start_time_s"] for res in emotion_results]
    if emotion_results:
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

    # Table of results
    f.write("<table border='1'><tr><th>Speaker</th><th>Time</th><th>Sentence</th><th>Emotions</th></tr>")
    for res in emotion_results:
        emotions_str = ", ".join([f"{emo['label']}: {emo['score']:.3f}" for emo in res["emotions"]])
        f.write(f"<tr><td>{res['speaker']}</td><td>{res['start_time_s']:.2f}-{res['end_time_s']:.2f}</td><td>{res['sentence']}</td><td>{emotions_str}</td></tr>")
    f.write("</table></body></html>")

print(f"Results saved as HTML to: {output_html_path}")

# Open HTML in browser
webbrowser.open(f"file://{os.path.abspath(output_html_path)}")
