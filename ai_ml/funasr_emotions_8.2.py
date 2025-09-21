import os
import argparse
import json
import re
import torch
from funasr import AutoModel
from funasr.utils.postprocess_utils import rich_transcription_postprocess
import plotly.graph_objects as go
import webbrowser
from pathlib import Path

# Args parser
parser = argparse.ArgumentParser(description="Integrated emotion detection with SenseVoice")
parser.add_argument("media_path", type=str, help="Path to the media file")
parser.add_argument("--language", type=str, default="en", help="Language code (default: en)")
parser.add_argument("--hf_token", type=str, default=os.getenv("HF_TOKEN", ""), help="Hugging Face token for pyannote diarization")
args = parser.parse_args()
print(f"Emotions detector via SenseVoice-Small, version 2025, integrated pipeline")

# Setup paths
media_path = Path(args.media_path)
stem = media_path.stem
output_dir = media_path.parent / (stem + "_emotions_detected")
output_dir.mkdir(exist_ok=True)
output_html_path = output_dir / (stem + "_emotions.html")
output_json_path = output_dir / (stem + "_emotions.json")

# SenseVoice setup with VAD for sentence-level segmentation
model_dir = "iic/SenseVoiceSmall"
emotion_model = AutoModel(
    model=model_dir,
    trust_remote_code=True,
    vad_model="fsmn-vad",
    vad_kwargs={"max_single_segment_time": 5000, "min_silence_duration": 500},  # 5s max segments, 0.5s silence
    disable_update=True
)

# Add diarization if token provided
if args.hf_token:
    emotion_model.diarization_model = "pyannote/speaker-diarization-3.1"
    emotion_model.use_auth_token = args.hf_token

# Step 1: Process audio with SenseVoice (transcription, timestamps, speakers, emotions)
results = emotion_model.generate(
    input=str(media_path),
    cache={},
    language=args.language,
    use_itn=True,
    batch_size_s=30,
    merge_vad=True,
    merge_length_s=5,  # Tighter merging for sentence-level granularity
    ban_emo_unk=False
)

# Possible emotion labels
possible_labels = ["angry", "happy", "neutral", "sad", "unknown"]

# Step 2: Parse results into structured format
emotion_results = []
for res in results:
    text = rich_transcription_postprocess(res["text"])
    # Extract emotion from <|EMOTION Label|> tags
    emotion_match = re.search(r'<\|[A-Z]+ ([a-zA-Z]+)\|>', text)
    emotion_label = emotion_match.group(1).lower() if emotion_match else "unknown"
    # Clean text
    clean_text = re.sub(r'<\|.*?\|>', '', text).strip()
    
    # Emotions list with score 1.0 for predicted, 0.0 for others
    emotions = [{"label": l, "score": 1.0 if l == emotion_label else 0.0} for l in possible_labels]
    
    # Timestamps from CTC alignment
    start_time = res["timestamp"][0][0] / 1000.0 if "timestamp" in res and res["timestamp"] else 0.0
    end_time = res["timestamp"][-1][1] / 1000.0 if "timestamp" in res and res["timestamp"] else len(clean_text.split()) * 0.5
    speaker = res.get("speaker", "Unknown")
    
    emotion_results.append({
        "speaker": speaker,
        "sentence": clean_text,
        "start_time_s": float(start_time),
        "end_time_s": float(end_time),
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
#webbrowser.open(f"file://{os.path.abspath(output_html_path)}")
