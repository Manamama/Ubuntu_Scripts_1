import os
import argparse
import json
import whisperx
from transformers import AutoModelForAudioClassification, AutoFeatureExtractor
from pydub import AudioSegment
import plotly.graph_objects as go
import webbrowser
from pathlib import Path
import torch
import librosa

# Args parser
parser = argparse.ArgumentParser(description="2025 Free Pipeline: WhisperX Turbo + Pyannote + Whisper-SER")
parser.add_argument("media_path", type=str, help="Path to the media file")
parser.add_argument("--language", type=str, default="en", help="Language code (default: en)")
parser.add_argument("--hf_token", type=str, default=os.getenv("HF_TOKEN", ""), help="Hugging Face token for pyannote")
args = parser.parse_args()
print(f"Free 2025 Pipeline: WhisperX Turbo + Pyannote + Whisper-SER for {args.media_path}")

# Setup paths
media_path = Path(args.media_path)
stem = media_path.stem
output_dir = media_path.parent / (stem + "_emotions_detected")
output_dir.mkdir(exist_ok=True)
output_html_path = output_dir / (stem + "_emotions.html")
output_json_path = output_dir / (stem + "_emotions.json")

# WhisperX setup (large-v3-turbo: 6% WER, 50ms timestamps)
device = "cuda" if torch.cuda.is_available() else "cpu"
batch_size = 16 if device == "cuda" else 4
compute_type = "float16" if device == "cuda" else "int8"
whisperx_model_size = "large-v3-turbo"

# Load WhisperX model
model = whisperx.load_model(whisperx_model_size, device, compute_type=compute_type)

# Step 1: Transcribe with WhisperX turbo for sentence-level timestamps
audio = whisperx.load_audio(str(media_path))
result = model.transcribe(audio, batch_size=batch_size, language=args.language)

# Align for word-level timestamps, aggregate to sentences
model_a, metadata = whisperx.load_align_model(language_code=args.language, device=device)
result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False)

# Add speaker diarization with pyannote 3.1 (10% DER)
if args.hf_token:
    diarize_model = whisperx.DiarizationPipeline(model_name="pyannote/speaker-diarization-3.1", use_auth_token=args.hf_token, device=device)
    diarize_result = diarize_model(audio, min_speakers=1, max_speakers=10)
    result = whisperx.assign_word_speakers(diarize_result, result)

# Extract sentence-level segments
segments = []
for seg in result["segments"]:
    segments.append({
        "start": seg["start"],
        "end": seg["end"],
        "text": seg["text"].strip(),
        "speaker": seg.get("speaker", "Unknown")
    })

# Step 2: Emotion detection with firdhokk Whisper-large-v3 SER (80% accuracy)
ser_model = AutoModelForAudioClassification.from_pretrained("firdhokk/speech-emotion-recognition-with-openai-whisper-large-v3")
ser_extractor = AutoFeatureExtractor.from_pretrained("firdhokk/speech-emotion-recognition-with-openai-whisper-large-v3")
id2label = ser_model.config.id2label
possible_labels = ["angry", "happy", "neutral", "sad", "unknown"]
ser_model.to(device)

full_audio = AudioSegment.from_file(media_path)
emotion_results = []
for i, seg in enumerate(segments):
    start_ms = int(seg["start"] * 1000)
    end_ms = int(seg["end"] * 1000)
    chunk_audio = full_audio[start_ms:end_ms]
    chunk_file = output_dir / f"{stem}_segment_{i:03d}.wav"
    chunk_audio.export(chunk_file, format="wav")
    
    # Load chunk for SER
    audio_chunk, sr = librosa.load(chunk_file, sr=16000)
    inputs = ser_extractor(audio_chunk, sampling_rate=sr, return_tensors="pt").to(device)
    with torch.no_grad():
        logits = ser_model(**inputs).logits
    predicted_id = logits.argmax(-1).item()
    emotion_label = id2label[predicted_id].lower()
    if emotion_label not in possible_labels:
        emotion_label = "unknown"
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

# Step 3: Generate HTML with Plotly
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
    
    f.write("<table border='1'><tr><th>Speaker</th><th>Time</th><th>Sentence</th><th>Emotions</th></tr>")
    for res in emotion_results:
        emotions_str = ", ".join([f"{emo['label']}: {emo['score']:.3f}" for emo in res["emotions"]])
        f.write(f"<tr><td>{res['speaker']}</td><td>{res['start_time_s']:.2f}-{res['end_time_s']:.2f}</td><td>{res['sentence']}</td><td>{emotions_str}</td></tr>")
    f.write("</table></body></html>")

print(f"Results saved as HTML to: {output_html_path}")
webbrowser.open(f"file://{os.path.abspath(output_html_path)}")
