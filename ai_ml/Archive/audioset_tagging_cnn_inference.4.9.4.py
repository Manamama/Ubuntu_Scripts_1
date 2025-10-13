#!/usr/bin/env python3
#See: origin	https://github.com/qiuqiangkong/audioset_tagging_cnn , heavily modified. Uses two .py files that shoud be in the same folder, for imports : pytorch_utils.py and models.py and maybe more, q.v.  
import os
import sys
import numpy as np
import argparse
import librosa
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import torch
import csv
import datetime
import subprocess
import shutil
import moviepy
print(f"Using moviepy version: {moviepy.__version__}")
from moviepy import VideoFileClip, ImageSequenceClip, CompositeVideoClip, TextClip, concatenate_videoclips, ImageClip, VideoClip, AudioFileClip, ColorClip

import subprocess, shlex, tempfile

# Add utils directory to sys.path
sys.path.insert(1, os.path.join(os.path.dirname(__file__), '../utils'))
from utilities import create_folder, get_filename
from models import *
from pytorch_utils import move_data_to_device
import config

def is_video_file(audio_path):
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_streams', '-print_format', 'json', audio_path],
            capture_output=True, text=True, check=True
        )
        streams = json.loads(result.stdout).get('streams', [])
        return any(stream['codec_type'] == 'video' for stream in streams)
    except subprocess.CalledProcessError:
        return False

import json

def get_duration_and_fps(video_path):
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_format', '-show_streams', '-print_format', 'json', video_path],
            capture_output=True, text=True, check=True
        )
        data = json.loads(result.stdout)
        streams = data.get('streams', [])
        format_info = data.get('format', {})
        duration = float(format_info.get('duration', None))
        fps = None
        width = None
        height = None

        video_stream = next((s for s in streams if s['codec_type'] == 'video'), None)
        if video_stream:
            avg_frame_rate = video_stream.get('avg_frame_rate')
            if avg_frame_rate and '/' in avg_frame_rate:
                num, den = map(int, avg_frame_rate.split('/'))
                fps = num / den if den else None
            width = video_stream.get('width')
            height = video_stream.get('height')

        if duration is None and video_stream:
            # Fallback for duration if not in format
            num_frames = int(video_stream.get('nb_frames', 0))
            if num_frames and fps:
                duration = num_frames / fps

        if duration is None:
            audio_stream = next((s for s in streams if s['codec_type'] == 'audio'), None)
            if audio_stream:
                duration = float(audio_stream.get('duration', None))

        duration_str = str(datetime.timedelta(seconds=int(duration))) if duration else "?"

        print(f"⏲  🗃️  Input file duration: \033[1;34m{duration_str}\033[0m")
        if fps:
            print(f"🮲  🗃️  Input video FPS (avg): \033[1;34m{fps:.3f}\033[0m")
        if width and height:
            print(f"🎥 🗃️  Input video resolution: \033[1;34m{width}x{height}\033[0m")

        return duration, fps, width, height

    except Exception as e:
        print(f"\033[1;31mFailed to parse video info: {e}\033[0m")
        return None, None, None, None


def audio_tagging(args):
    sample_rate = args.sample_rate
    window_size = args.window_size
    hop_size = args.hop_size
    mel_bins = args.mel_bins
    fmin = args.fmin
    fmax = args.fmax
    model_type = args.model_type
    checkpoint_path = args.checkpoint_path
    audio_path = args.audio_path
    device = torch.device('cuda') if args.cuda and torch.cuda.is_available() else torch.device('cpu')

    classes_num = config.classes_num
    labels = config.labels

    Model = eval(model_type)
    model = Model(sample_rate=sample_rate, window_size=window_size, 
                  hop_size=hop_size, mel_bins=mel_bins, fmin=fmin, fmax=fmax, 
                  classes_num=classes_num)
    
    checkpoint = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(checkpoint['model'])

    if device.type == 'cuda':
        model.to(device)
        print(f'GPU number: {torch.cuda.device_count()}')
        model = torch.nn.DataParallel(model)
    else:
        print('Using CPU.')

    (waveform, _) = librosa.core.load(audio_path, sr=sample_rate, mono=True)
    waveform = waveform[None, :]
    waveform = move_data_to_device(waveform, device)

    with torch.no_grad():
        model.eval()
        batch_output_dict = model(waveform, None)

    clipwise_output = batch_output_dict['clipwise_output'].data.cpu().numpy()[0]
    sorted_indexes = np.argsort(clipwise_output)[::-1]

    print('Sound events detection result (time_steps x classes_num): {}'.format(clipwise_output.shape))

    for k in range(10):
        print('{}: {}'.format(np.array(labels)[sorted_indexes[k]], clipwise_output[sorted_indexes[k]]))

    if 'embedding' in batch_output_dict:
        embedding = batch_output_dict['embedding'].data.cpu().numpy()[0]
        print('embedding: {}'.format(embedding.shape))

    return clipwise_output, labels

def sound_event_detection(args):
    sample_rate = args.sample_rate
    window_size = args.window_size
    hop_size = args.hop_size
    mel_bins = args.mel_bins
    fmin = args.fmin
    fmax = args.fmax
    model_type = args.model_type
    checkpoint_path = args.checkpoint_path
    audio_path = args.audio_path
    device = torch.device('cuda' if args.cuda and torch.cuda.is_available() else 'cpu')

    print(f"Using device: {device}")
    if device.type == 'cuda':
        print(f"GPU device name: {torch.cuda.get_device_name(0)}")

    classes_num = config.classes_num
    labels = config.labels
    
    # Paths
    audio_dir = os.path.dirname(audio_path)
    create_folder(audio_dir)
    base_filename = get_filename(audio_path) + '_audioset_tagging_cnn'
    fig_path = os.path.join(audio_dir, f'{base_filename}.png')
    csv_path = os.path.join(audio_dir, f'{base_filename}.csv')
    srt_path = os.path.join(audio_dir, f'{base_filename}.srt')
    video_path = os.path.join(audio_dir, f'{base_filename}_eventogram.mp4')
    
    # Check disk space
    disk_usage = shutil.disk_usage(audio_dir)
    if disk_usage.free < 1e9:  # Less than 1GB free
        print(f"\033[1;31mError: Insufficient disk space ({disk_usage.free / 1e9:.2f} GB free). Exiting.\033[0m")
        return
    
    # Model
    Model = eval(model_type)
    model = Model(sample_rate=sample_rate, window_size=window_size, 
                  hop_size=hop_size, mel_bins=mel_bins, fmin=fmin, fmax=fmax, 
                  classes_num=classes_num)
    
    checkpoint = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(checkpoint['model'])

    if device.type == 'cuda':
        model.to(device)
        print(f'GPU number: {torch.cuda.device_count()}')
        model = torch.nn.DataParallel(model)
    else:
        print('Using CPU.')

    # Audio loading
    duration, video_fps, video_width, video_height = get_duration_and_fps(audio_path)
    if duration is None:
        print("\033[1;31mError: Could not determine audio duration. Exiting.\033[0m")
        return
    is_video = is_video_file(audio_path)
    
    # Fallback for video dimensions if None (only for video files)
    if is_video and (video_width is None or video_height is None):
        video_width = 1280
        video_height = 720
        print(f"\033[1;33mWarning: Video dimensions not detected, using default {video_width}x{video_height}.\033[0m")
    
    # Check if VFR and re-encode to CFR if necessary
    video_input_path = audio_path
    temp_video_path = None
    if is_video:
        # Get r_frame_rate and avg_frame_rate
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=r_frame_rate,avg_frame_rate', '-of', 'json', audio_path],
            capture_output=True, text=True, check=True
        )
        data = json.loads(result.stdout)
        if data['streams']:
            stream = data['streams'][0]
            r_frame_rate = stream.get('r_frame_rate')
            avg_frame_rate = stream.get('avg_frame_rate')
            if r_frame_rate != avg_frame_rate:
                print("\033[1;33mDetected potential VFR video. Re-encoding to CFR for compatibility.\033[0m")
                temp_video_path = os.path.join(audio_dir, f'temp_cfr_{get_filename(audio_path)}.mp4')
                subprocess.run([
                    'ffmpeg', '-loglevel', 'warning', '-i', audio_path, '-r', str(video_fps), '-fps_mode', 'cfr', '-c:a', 'copy', temp_video_path, '-y'
                ], check=True)
                video_input_path = temp_video_path
                print(f"Re-encoded to: {temp_video_path}")

    # Downsample for long files
    #if duration > 300:  # 5 minutes
    #    sample_rate = 16000
    #    args.sample_rate = sample_rate
    #    print(f"Using reduced sample rate {sample_rate} Hz for long file.")
    
    # Load audio
    (waveform, _) = librosa.core.load(audio_path, sr=sample_rate, mono=True)
    
    # Chunking for long files to avoid OOM
    chunk_duration = 300  # 5 minutes
    chunk_samples = int(chunk_duration * sample_rate)
    framewise_outputs = []
    
    for start in range(0, len(waveform), chunk_samples):
        chunk = waveform[start:start + chunk_samples]
        if len(chunk) < sample_rate // 10:  # Skip small chunks
            continue
        chunk = chunk[None, :]
        chunk = move_data_to_device(chunk, device)
        
        with torch.no_grad():
            model.eval()
            batch_output_dict = model(chunk, None)
        framewise_output_chunk = batch_output_dict['framewise_output'].data.cpu().numpy()[0]
        framewise_outputs.append(framewise_output_chunk)
    
    # Concatenate results
    framewise_output = np.concatenate(framewise_outputs, axis=0)
    print(f'Sound event detection result (time_steps x classes_num): {framewise_output.shape}')

    # --- Png visualization ---
    frames_per_second = sample_rate // hop_size
    stft = librosa.core.stft(y=waveform, n_fft=window_size, 
                             hop_length=hop_size, window='hann', center=True)
    frames_num = int(duration * frames_per_second)  # Match duration
    
    # Pad framewise_output if necessary
    if framewise_output.shape[0] < frames_num:
        pad_width = frames_num - framewise_output.shape[0]
        framewise_output = np.pad(framewise_output, ((0, pad_width), (0, 0)), mode='constant')
    
    sorted_indexes = np.argsort(np.max(framewise_output, axis=0))[::-1]
    top_k = 10
    top_result_mat = framewise_output[:frames_num, sorted_indexes[0:top_k]]

    # --- Smart, adaptive plotting that yields an axes bbox we can trust ---
    # Create a reasonably sized figure (will be rasterized as PNG). We don't hard-code margins here.
    # We'll measure the renderer and then adjust the left margin in pixels to fit the y-labels.
    fig_width_px = 1280   # base pixel width for PNG — can be changed; MoviePy scales PNG later if needed
    fig_height_px = 480
    dpi = 100
    fig = plt.figure(figsize=(fig_width_px / dpi, fig_height_px / dpi), dpi=dpi)

    # Create two axes occupying the full width for now; we'll adjust left fraction shortly.
    # Control the height ratio of spectrogram (upper) to eventogram (lower) here
    gs = fig.add_gridspec(2, 1, height_ratios=[1, 1], left=0.0, right=1.0, top=0.95, bottom=0.08, hspace=0.05)
    axs = [fig.add_subplot(gs[0]), fig.add_subplot(gs[1])]

    # Plot (first pass)
    axs[0].matshow(np.log(np.abs(stft[:, :frames_num]) + 1e-10), origin='lower', aspect='auto', cmap='jet')
    axs[0].set_ylabel('Frequency bins', fontsize=14)
    axs[0].set_title('Log spectrogram', fontsize=14)
    axs[1].matshow(top_result_mat.T, origin='upper', aspect='auto', cmap='jet', vmin=0, vmax=1)

    # X-axis ticks (seconds)
    tick_interval = max(5, int(duration / 20))  # At most 20 ticks
    x_ticks = np.arange(0, frames_num + 1, frames_per_second * tick_interval)
    x_labels = np.arange(0, int(duration) + 1, tick_interval)
    axs[1].xaxis.set_ticks(x_ticks)
    axs[1].xaxis.set_ticklabels(x_labels[:len(x_ticks)], rotation=45, ha='right', fontsize=14)
    axs[1].set_xlim(0, frames_num)

    # Y-axis labels and formatting
    top_labels = np.array(labels)[sorted_indexes[0:top_k]]
    axs[1].set_yticks(np.arange(0, top_k))
    axs[1].set_yticklabels(top_labels, fontsize=14, rotation=0, ha='right', va='center')  # rotate if needed

    axs[1].yaxis.grid(color='k', linestyle='solid', linewidth=0.3, alpha=0.3)
    axs[1].set_xlabel('Seconds', fontsize=14)
    axs[1].xaxis.set_ticks_position('bottom')
        
    # Ensure layout doesn't overlap
    plt.tight_layout()

    # Force a draw to get a renderer (we need it to measure label extents)
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()

    # Measure widest y-tick label in pixels
    max_label_width_px = 0
    for lbl in axs[1].yaxis.get_majorticklabels():
        bbox = lbl.get_window_extent(renderer=renderer)
        w = bbox.width
        if w > max_label_width_px:
            max_label_width_px = w

    # Add some padding in pixels
    pad_px = 8
    left_margin_px = int(max_label_width_px + pad_px + 6)  # small extra safety

    # Compute left fraction (figure coords) and adjust gridspec to reserve that many pixels on the left
    fig_w_in = fig.get_size_inches()[0]
    fig_w_px = fig_w_in * dpi
    left_frac = left_margin_px / fig_w_px
    if left_frac < 0:
        left_frac = 0.0
    if left_frac > 0.45:
        left_frac = 0.45  # avoid eating too much width

    # Adjust gridspec with the new left fraction; right edge stays at 1.0 (flush)
    # Control the height ratio of spectrogram (upper) to eventogram (lower) here
    gs = fig.add_gridspec(2, 1, height_ratios=[1, 1],
                          left=left_frac, right=1.0, top=0.95, bottom=0.08, hspace=0.05)
    # Recreate axes with the new gridspec
    # Clear the old axes to avoid double-draw artifacts
    fig.clear()
    axs = [fig.add_subplot(gs[0]), fig.add_subplot(gs[1])]

    # Plot again into new axes (final)
    axs[0].matshow(np.log(np.abs(stft[:, :frames_num]) + 1e-10), origin='lower', aspect='auto', cmap='jet')
    axs[0].set_ylabel('Frequency bins', fontsize=14)
    axs[0].set_title('Spectrogram and Eventogram', fontsize=14)
    axs[1].matshow(top_result_mat.T, origin='upper', aspect='auto', cmap='jet', vmin=0, vmax=1)

    # Reapply ticks/labels
    axs[1].xaxis.set_ticks(x_ticks)
    axs[1].xaxis.set_ticklabels(x_labels[:len(x_ticks)], rotation=45, ha='right', fontsize=10)
    axs[1].set_xlim(0, frames_num)
    axs[1].yaxis.set_ticks(np.arange(0, top_k))
    axs[1].yaxis.set_ticklabels(top_labels, fontsize=14)
    axs[1].yaxis.grid(color='k', linestyle='solid', linewidth=0.3, alpha=0.3)
    axs[1].set_xlabel('Seconds', fontsize=14)
    axs[1].xaxis.set_ticks_position('bottom')
    

    # Final draw and fetch axes bbox (fractional coordinates within the figure)
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    axes_bbox = axs[1].get_position()  # Bbox in figure fraction coords: x0,x1,y0,y1

    # Save the PNG as-is (no 'tight' cropping)
    plt.savefig(fig_path, bbox_inches=None, pad_inches=0)
    plt.close(fig)
    print(f'Saved sound event detection visualization to: {fig_path}')
    print(f'Computed left margin (px): {left_margin_px}, axes bbox (fig-fraction): {axes_bbox}')

    # --- CSV output  ---
    threshold = 0.5
    all_events = []
    for j in range(framewise_output.shape[1]):
        is_active = False
        start_frame = 0
        for i in range(frames_num):
            if framewise_output[i, j] > threshold and not is_active:
                is_active = True
                start_frame = i
            elif framewise_output[i, j] <= threshold and is_active:
                is_active = False
                end_frame = i
                start_seconds = start_frame / frames_per_second
                end_seconds = end_frame / frames_per_second
                all_events.append({
                    'start_time': datetime.timedelta(seconds=start_seconds),
                    'end_time': datetime.timedelta(seconds=end_seconds),
                    'label': labels[j],
                    'probability': np.max(framewise_output[start_frame:end_frame, j])
                })
        if is_active:
            end_frame = frames_num
            start_seconds = start_frame / frames_per_second
            end_seconds = end_frame / frames_per_second
            all_events.append({
                'start_time': datetime.timedelta(seconds=start_seconds),
                'end_time': datetime.timedelta(seconds=end_seconds),
                'label': labels[j],
                'probability': np.max(framewise_output[start_frame:end_frame, j])
            })

    all_events.sort(key=lambda x: x['start_time'])

    with open(csv_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['start_time', 'end_time', 'sound', 'probability'])
        for event in all_events:
            writer.writerow([event['start_time'].total_seconds(), event['end_time'].total_seconds(), event['label'], event['probability']])
    print(f'Saved CSV results to {csv_path}')

    # --- MoviePy Video output ---
    fps = video_fps if video_fps else 24

    # Create static image clip
    static_eventogram_clip = ImageClip(fig_path, duration=duration)

    # Now compute pixel start/end for the marker using the axes_bbox we measured earlier.
    # axes_bbox is in fractional figure coords; we saved a PNG of fig_width_px x fig_height_px.
    # But MoviePy will load the PNG and may resize it. Using the fractional bbox we can compute
    # the marker positions for any resized width.
    ax_x0_frac = axes_bbox.x0
    ax_x1_frac = axes_bbox.x1

    def marker_position(t):
        # compute in the current (possibly resized) image pixels
        w = static_eventogram_clip.w
        x_start = int(ax_x0_frac * w)
        x_end = int(ax_x1_frac * w)
        # clamp and linear interpolate across duration
        frac = np.clip(t / max(duration, 1e-8), 0.0, 1.0)
        x_pos = x_start + (x_end - x_start) * frac
        return (x_pos, 0)

    # Create moving time marker (thin vertical bar)
    # Height should match the static image height; width of marker is small (2 px)
    marker = ColorClip(size=(2, static_eventogram_clip.h), color=(255, 0, 0)).with_duration(duration)
    marker = marker.with_position(marker_position)

    # Composite and add audio
    eventogram_visual_clip = CompositeVideoClip([static_eventogram_clip, marker])
    audio_clip = AudioFileClip(audio_path)
    eventogram_with_audio_clip = eventogram_visual_clip.with_audio(audio_clip)






    if is_video:
        # Overlay on original video
        original_video_clip = VideoFileClip(video_input_path, fps_source='fps')

        eventogram_with_audio_clip = eventogram_with_audio_clip.with_fps(original_video_clip.fps)

        # Resize overlay: preserve aspect ratio, height = fraction of video height
        overlay_height = int(original_video_clip.h * args.overlay_size)
        overlay_width = original_video_clip.w
        eventogram_with_audio_clip = eventogram_with_audio_clip.resized((overlay_width, overlay_height))

        # Set translucency
        eventogram_with_audio_clip = eventogram_with_audio_clip.with_opacity(args.translucency)

        # Position overlay bottom-right
        overlayed_video = CompositeVideoClip([
            original_video_clip,
            eventogram_with_audio_clip.with_position(("right", "bottom"))
        ]).without_audio()

        # Write overlayed video **without audio** to a temporary file
        tmp_overlay_path = tempfile.mktemp(suffix="_overlay.mp4")
        print(f"🎞  Rendering overlay video (no audio) → {tmp_overlay_path}")
        overlayed_video.write_videofile(
            tmp_overlay_path,
            codec="libx264",
            audio=False,
            fps=original_video_clip.fps,
            threads=os.cpu_count()
        )

        # Now re-mux using ffmpeg to copy original audio bit-for-bit
        print(f"🎧  Muxing original audio (no re-encode)…")
        cmd = f"""
        ffmpeg -y -i "{tmp_overlay_path}" -i "{video_input_path}" \
            -map 0:v:0 -map 1:a:0 \
            -c:v copy -c:a copy -shortest "{video_path}"
        """
        result = subprocess.run(shlex.split(cmd), capture_output=True, text=True)

        if result.returncode == 0:
            print(f"🎹 Saved final video to: {video_path}")
        else:
            print(f"\033[1;31mError muxing audio:\033[0m\n{result.stderr}")

        # Clean up
        os.remove(tmp_overlay_path)
        print(f"🧹 Removed temporary file: {tmp_overlay_path}")

    else:
        # Full-screen eventogram (audio tagging only)
        print(f"🎞  Rendering full eventogram video (includes AAC audio encode)…")
        eventogram_with_audio_clip.write_videofile(
            video_path,
            codec='libx264',
            audio_codec='aac',
            fps=fps,
            threads=os.cpu_count()
        )
        print(f"🎹 Saved video to: {video_path}")
        #You may check it with: ffmpeg -v error -i {video_path}  -f null -
        #Or with: -vn -f wav - | soxi -





if __name__ == '__main__':
    print(f"Eventogrammer, version 4.9.4, see the original here: https://github.com/qiuqiangkong/audioset_tagging_cnn")
    print(f"")

    parser = argparse.ArgumentParser(description='Audio tagging and Sound event detection.')

    # main positional argument
    parser.add_argument('audio_path', type=str, help='Path to audio or video file')

    # shared arguments
    parser.add_argument('--mode', choices=['audio_tagging', 'sound_event_detection'],
                        default='sound_event_detection', help='Select processing mode')
    parser.add_argument('--sample_rate', type=int, default=32000)
    parser.add_argument('--window_size', type=int, default=1024)
    parser.add_argument('--hop_size', type=int, default=320)
    parser.add_argument('--mel_bins', type=int, default=64)
    parser.add_argument('--fmin', type=int, default=50)
    parser.add_argument('--fmax', type=int, default=14000)
    parser.add_argument('--model_type', type=str, required=True)
    parser.add_argument('--checkpoint_path', type=str, required=True)
    parser.add_argument('--cuda', action='store_true', default=False)

    # eventogram / overlay args (used only in sound_event_detection mode)
    parser.add_argument('--translucency', type=float, default=0.7,
                        help='Overlay translucency (0 to 1)')
    parser.add_argument('--overlay_size', type=float, default=0.2,
                        help='Overlay size as fraction of video height')
    parser.add_argument('--eventogram_mode', action='store_true', default=False,
                        help='Use eventogram instead of text-based video')

    args = parser.parse_args()

    if args.mode == 'audio_tagging':
        audio_tagging(args)
    else:
        sound_event_detection(args)
