#!/usr/bin/env python3
# See: origin https://github.com/qiuqiangkong/audioset_tagging_cnn, heavily modified.
# Uses two .py files that should be in the same folder for imports: pytorch_utils.py and models.py.

import os
import sys
import numpy as np
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import torch
import torchaudio
import csv
import datetime
import subprocess
import shutil
import moviepy
import warnings
import platform
print(f"Using moviepy version: {moviepy.__version__}")
from moviepy import ImageClip, CompositeVideoClip, AudioFileClip, ColorClip, VideoClip
import json
from scipy.stats import entropy

# Suppress torchaudio deprecation warnings
warnings.filterwarnings("ignore", category=UserWarning, module="torchaudio")

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
        return any(stream['codec_type'] == 'video' and stream.get('codec_name') not in ['mjpeg', 'png'] for stream in streams)
    except subprocess.CalledProcessError:
        return False
    except Exception:
        return False

def get_duration_and_fps(input_media_path):
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_format', '-show_streams', '-print_format', 'json', input_media_path],
            capture_output=True, text=True, check=True
        )
        data = json.loads(result.stdout)
        streams = data.get('streams', [])
        format_info = data.get('format', {})
        duration = float(format_info.get('duration', None)) if format_info.get('duration', None) else None
        fps = None
        width = None
        height = None

        video_stream = next((s for s in streams if s['codec_type'] == 'video'), None)
        if video_stream:
            avg_frame_rate = video_stream.get('avg_frame_rate')
            if avg_frame_rate and '/' in avg_frame_rate:
                num, den = map(int, avg_frame_rate.split('/'))
                fps = num / den if den else None
            width = int(video_stream.get('width')) if video_stream.get('width') else None
            height = int(video_stream.get('height')) if video_stream.get('height') else None

        if duration is None and video_stream:
            nb_frames = video_stream.get('nb_frames')
            if nb_frames and fps:
                duration = int(nb_frames) / fps

        if duration is None:
            audio_stream = next((s for s in streams if s['codec_type'] == 'audio'), None)
            if audio_stream:
                duration = float(audio_stream.get('duration', None))

        duration_str = str(datetime.timedelta(seconds=int(duration))) if duration else "?"

        print(f"⏲  🗃️  Input file duration: \033[1;34m{duration_str}\033[0m")
        if fps:
            print(f"🮲  🗃️  Input video FPS (avg): \033[1;34m{fps:.3f}\033[0m")
        if width and height:
            print(f"📽  🗃️  Input video resolution: \033[1;34m{width}x{height}\033[0m")

        return duration, fps, width, height

    except Exception as e:
        print(f"\033[1;31mFailed to parse video info: {e}\033[0m")
        return None, None, None, None

def compute_kl_divergence(p, q, eps=1e-10):
    """Compute KL divergence between two probability distributions."""
    p = np.clip(p, eps, 1)
    q = np.clip(q, eps, 1)
    return np.sum(p * np.log(p / q))

def get_dynamic_top_events(framewise_output, start_idx, end_idx, top_k=10):
    """Get top k events for a given window of framewise_output."""
    window_output = framewise_output[start_idx:end_idx]
    if window_output.shape[0] == 0:
        return np.array([]), np.array([])
    max_probs = np.max(window_output, axis=0)
    sorted_indexes = np.argsort(max_probs)[::-1][:top_k]
    return window_output[:, sorted_indexes], sorted_indexes

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
    
    try:
        checkpoint = torch.load(checkpoint_path, map_location=device)
        model.load_state_dict(checkpoint['model'])
    except Exception as e:
        print(f"\033[1;31mError loading model checkpoint: {e}\033[0m")
        return

    if device.type == 'cuda':
        model.to(device)
        print(f'GPU number: {torch.cuda.device_count()}')
        model = torch.nn.DataParallel(model)

    waveform, sr = torchaudio.load(audio_path)
    print(f"Loaded waveform shape: {waveform.shape}, sample rate: {sr}")
    if sr != sample_rate:
        waveform = torchaudio.transforms.Resample(orig_freq=sr, new_freq=sample_rate)(waveform)
    waveform = waveform.mean(dim=0, keepdim=True)  # Convert to mono
    waveform = waveform[None, :]  # Shape: [1, samples] for model input
    waveform = move_data_to_device(waveform, device)

    with torch.no_grad():
        model.eval()
        try:
            batch_output_dict = model(waveform, None)
        except Exception as e:
            print(f"\033[1;31mError during model inference: {e}\033[0m")
            return

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
    else:
        print('Using CPU.')

    classes_num = config.classes_num
    labels = config.labels
    
    audio_dir = os.path.dirname(audio_path)
    create_folder(audio_dir)
    base_filename = get_filename(audio_path) + '_audioset_tagging_cnn'
    fig_path = os.path.join(audio_dir, f'{base_filename}.png')
    csv_path = os.path.join(audio_dir, f'{base_filename}.csv')
    if args.dynamic_eventogram:
        output_video_path = os.path.join(audio_dir, f'{base_filename}_eventogram_dynamic.mp4')
    else:
        output_video_path = os.path.join(audio_dir, f'{base_filename}_eventogram.mp4')
    
    disk_usage = shutil.disk_usage(audio_dir)
    if disk_usage.free < 1e9:
        print(f"\033[1;31mError: Insufficient disk space ({disk_usage.free / 1e9:.2f} GB free). Exiting.\033[0m")
        return
    
    Model = eval(model_type)
    model = Model(sample_rate=sample_rate, window_size=window_size, 
                  hop_size=hop_size, mel_bins=mel_bins, fmin=fmin, fmax=fmax, 
                  classes_num=classes_num)
    
    try:
        checkpoint = torch.load(checkpoint_path, map_location=device)
        model.load_state_dict(checkpoint['model'])
    except Exception as e:
        print(f"\033[1;31mError loading model checkpoint: {e}\033[0m")
        return

    duration, video_fps, video_width, video_height = get_duration_and_fps(audio_path)
    if duration is None:
        print("\033[1;31mError: Could not determine audio duration. Exiting.\033[0m")
        return
    is_video = is_video_file(audio_path)
    
    if is_video and (video_width is None or video_height is None):
        video_width = 1280
        video_height = 720
        print(f"\033[1;33mWarning: Video dimensions not detected, using default {video_width}x{video_height}.\033[0m")
    
    video_input_path = audio_path
    temp_video_path = None
    if is_video:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=r_frame_rate,avg_frame_rate', '-of', 'json', audio_path],
            capture_output=True, text=True, check=True
        )
        data = json.loads(result.stdout)
        if data.get('streams'):
            stream = data['streams'][0]
            r_frame_rate = stream.get('r_frame_rate')
            avg_frame_rate = stream.get('avg_frame_rate')
            if r_frame_rate and avg_frame_rate:
                r_num, r_den = map(int, r_frame_rate.split('/'))
                avg_num, avg_den = map(int, avg_frame_rate.split('/'))
                r_fps = r_num / r_den if r_den else 0
                avg_fps = avg_num / avg_den if avg_den else 0
                if abs(r_fps - avg_fps) > 0.01:
                    print("\033[1;33mDetected VFR video (r_frame_rate={r_fps:.3f}, avg_frame_rate={avg_fps:.3f}). Re-encoding to CFR.\033[0m")
                    temp_video_path = os.path.join(audio_dir, f'temp_cfr_{get_filename(audio_path)}.mp4')
                    try:
                        subprocess.run([
                            'ffmpeg', '-loglevel', 'warning', '-i', audio_path, '-r', str(video_fps), '-fps_mode', 'cfr', '-c:a', 'copy', temp_video_path, '-y'
                        ], check=True)
                        video_input_path = temp_video_path
                        print(f"Re-encoded to: \033[1;34m{temp_video_path}\033[1;0m")
                    except subprocess.CalledProcessError as e:
                        print(f"\033[1;31mError during VFR-to-CFR conversion: {e}\033[0m")
                        return

    waveform, sr = torchaudio.load(video_input_path)
    print(f"Loaded waveform shape: {waveform.shape}, sample rate: {sr}")
    if sr != sample_rate:
        waveform = torchaudio.transforms.Resample(orig_freq=sr, new_freq=sample_rate)(waveform)
    waveform = waveform.mean(dim=0, keepdim=True)  # Convert to mono
    waveform = waveform.squeeze(0).numpy()  # Convert to numpy for STFT
    print(f"Processed waveform shape: {waveform.shape}")

    chunk_duration = 180  # 3 minutes
    chunk_samples = int(chunk_duration * sample_rate)
    framewise_outputs = []
    
    for start in range(0, len(waveform), chunk_samples):
        chunk = waveform[start:start + chunk_samples]
        if len(chunk) < sample_rate // 10:
            print(f"Skipping small chunk at start={start}, len={len(chunk)}")
            continue
        chunk = chunk[None, :]  # Shape: [1, samples]
        chunk = move_data_to_device(torch.from_numpy(chunk).float(), device)
        print(f"Processing chunk: start={start}, len={len(chunk)}")
        
        with torch.no_grad():
            model.eval()
            try:
                batch_output_dict = model(chunk, None)
                framewise_output_chunk = batch_output_dict['framewise_output'].data.cpu().numpy()[0]
                print(f"Chunk output shape: {framewise_output_chunk.shape}")
                framewise_outputs.append(framewise_output_chunk)
            except Exception as e:
                print(f"\033[1;31mError processing chunk at start={start}: {e}\033[0m")
                continue
    
    if not framewise_outputs:
        print("\033[1;31mError: No valid chunks processed. Cannot generate eventogram.\033[0m")
        return
    
    framewise_output = np.concatenate(framewise_outputs, axis=0)
    print(f'Sound event detection result (time_steps x classes_num): \033[1;34m{framewise_output.shape}\033[1;0m')

    frames_per_second = sample_rate // hop_size
    waveform_tensor = torch.from_numpy(waveform).to(device)
    stft = torch.stft(
        waveform_tensor,
        n_fft=window_size,
        hop_length=hop_size,
        window=torch.hann_window(window_size).to(device),
        center=True,
        return_complex=True
    )
    stft = stft.abs().cpu().numpy()
    frames_num = int(duration * frames_per_second)
    
    if framewise_output.shape[0] < frames_num:
        pad_width = frames_num - framewise_output.shape[0]
        framewise_output = np.pad(framewise_output, ((0, pad_width), (0, 0)), mode='constant')
    
    # Static PNG visualization
    sorted_indexes = np.argsort(np.max(framewise_output, axis=0))[::-1]
    top_k = 10
    top_result_mat = framewise_output[:frames_num, sorted_indexes[0:top_k]]

    fig_width_px = 1280
    fig_height_px = 480
    dpi = 100
    fig = plt.figure(figsize=(fig_width_px / dpi, fig_height_px / dpi), dpi=dpi)

    gs = fig.add_gridspec(2, 1, height_ratios=[1, 1], left=0.0, right=1.0, top=0.95, bottom=0.08, hspace=0.05)
    axs = [fig.add_subplot(gs[0]), fig.add_subplot(gs[1])]

    axs[0].matshow(np.log(stft + 1e-10), origin='lower', aspect='auto', cmap='jet')
    axs[0].set_ylabel('Frequency bins', fontsize=14)
    axs[0].set_title('Spectrogram and Eventogram', fontsize=14)
    axs[1].matshow(top_result_mat.T, origin='upper', aspect='auto', cmap='jet', vmin=0, vmax=1)

    tick_interval = max(5, int(duration / 20))
    x_ticks = np.arange(0, frames_num + 1, frames_per_second * tick_interval)
    x_labels = np.arange(0, int(duration) + 1, tick_interval)
    axs[1].xaxis.set_ticks(x_ticks)
    axs[1].xaxis.set_ticklabels(x_labels[:len(x_ticks)], rotation=45, ha='right', fontsize=10)
    axs[1].set_xlim(0, frames_num)
    top_labels = np.array(labels)[sorted_indexes[0:top_k]]
    axs[1].set_yticks(np.arange(0, top_k))
    axs[1].set_yticklabels(top_labels, fontsize=14)
    axs[1].yaxis.grid(color='k', linestyle='solid', linewidth=0.3, alpha=0.3)
    axs[1].set_xlabel('Seconds', fontsize=14)
    axs[1].xaxis.set_ticks_position('bottom')
    
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    max_label_width_px = 0
    for lbl in axs[1].yaxis.get_majorticklabels():
        bbox = lbl.get_window_extent(renderer=renderer)
        w = bbox.width
        if w > max_label_width_px:
            max_label_width_px = w

    pad_px = 8
    left_margin_px = int(max_label_width_px + pad_px + 6)
    fig_w_in = fig.get_size_inches()[0]
    fig_w_px = fig_w_in * dpi
    left_frac = left_margin_px / fig_w_px
    if left_frac < 0:
        left_frac = 0.0
    if left_frac > 0.45:
        left_frac = 0.45

    gs = fig.add_gridspec(2, 1, height_ratios=[1, 1], left=left_frac, right=1.0, top=0.95, bottom=0.08, hspace=0.05)
    fig.clear()
    axs = [fig.add_subplot(gs[0]), fig.add_subplot(gs[1])]

    axs[0].matshow(np.log(stft + 1e-10), origin='lower', aspect='auto', cmap='jet')
    axs[0].set_ylabel('Frequency bins', fontsize=14)
    axs[1].matshow(top_result_mat.T, origin='upper', aspect='auto', cmap='jet', vmin=0, vmax=1)
    axs[1].xaxis.set_ticks(x_ticks)
    axs[1].xaxis.set_ticklabels(x_labels[:len(x_ticks)], rotation=45, ha='right', fontsize=10)
    axs[1].set_xlim(0, frames_num)
    axs[1].yaxis.set_ticks(np.arange(0, top_k))
    axs[1].yaxis.set_ticklabels(top_labels, fontsize=14)
    axs[1].yaxis.grid(color='k', linestyle='solid', linewidth=0.3, alpha=0.3)
    axs[1].set_xlabel('Seconds', fontsize=14)
    axs[1].xaxis.set_ticks_position('bottom')
    
    plt.savefig(fig_path, bbox_inches='tight', pad_inches=0)
    plt.close(fig)
    print(f'Saved sound event detection visualization to: \033[1;34m{fig_path}\033[1;0m')
    print(f'Computed left margin (px): \033[1;34m{left_margin_px}\033[1;00m, axes bbox (fig-fraction): \033[1;34m{axs[1].get_position()}\033[1;00m')

    with open(csv_path, 'w', newline='') as csvfile:
        threshold = 0.2
        writer = csv.writer(csvfile)
        writer.writerow(['time', 'sound', 'probability'])
        for i in range(frames_num):
            timestamp = i / frames_per_second
            for j, label in enumerate(labels):
                prob = framewise_output[i, j]
                if prob > threshold:
                    writer.writerow([round(timestamp, 3), label, float(prob)])
    print(f'Saved full framewise CSV to: \033[1;34m{csv_path}\033[1;0m')

    # Video rendering
    fps = video_fps if video_fps else 24
    if args.dynamic_eventogram:
        print(f"🎞  Rendering dynamic eventogram video …")
        window_duration = args.window_duration
        window_frames = int(window_duration * frames_per_second)
        half_window_frames = window_frames // 2

        # Precompute unique window frames to improve performance
        frame_times = np.arange(0, duration, 1/fps)
        unique_windows = {}
        for t in frame_times:
            current_frame = int(t * frames_per_second)
            start_frame = max(0, current_frame - half_window_frames)
            end_frame = min(frames_num, current_frame + half_window_frames)
            window_key = (start_frame, end_frame)
            if window_key not in unique_windows:
                window_output, window_indexes = get_dynamic_top_events(framewise_output, start_frame, end_frame, top_k)
                if window_output.size == 0:
                    window_output = np.zeros((end_frame - start_frame, top_k))
                    window_indexes = sorted_indexes[:top_k]
                unique_windows[window_key] = (window_output, window_indexes)

        def make_frame(t):
            current_frame = int(t * frames_per_second)
            start_frame = max(0, current_frame - half_window_frames)
            end_frame = min(frames_num, current_frame + half_window_frames)
            
            # Adaptive window size (if enabled)
            if args.use_adaptive_window:
                kl_threshold = 0.5
                for offset in range(half_window_frames, half_window_frames + int(30 * frames_per_second), int(frames_per_second)):
                    if start_frame - offset >= 0:
                        prev_prob = np.mean(framewise_output[start_frame - offset:start_frame], axis=0)
                        curr_prob = np.mean(framewise_output[start_frame:start_frame + offset], axis=0)
                        kl_div = compute_kl_divergence(prev_prob, curr_prob)
                        if kl_div > kl_threshold:
                            start_frame = max(0, start_frame - offset // 2)
                            break
                    if end_frame + offset < frames_num:
                        curr_prob = np.mean(framewise_output[end_frame - offset:end_frame], axis=0)
                        next_prob = np.mean(framewise_output[end_frame:end_frame + offset], axis=0)
                        kl_div = compute_kl_divergence(curr_prob, next_prob)
                        if kl_div > kl_threshold:
                            end_frame = min(frames_num, end_frame + offset // 2)
                            break
            
            window_output, window_indexes = unique_windows.get((start_frame, end_frame), (np.zeros((end_frame - start_frame, top_k)), sorted_indexes[:top_k]))
            
            # Create frame
            fig = plt.figure(figsize=(fig_width_px / dpi, fig_height_px / dpi), dpi=dpi)
            gs = fig.add_gridspec(2, 1, height_ratios=[1, 1], left=left_frac, right=1.0, top=0.95, bottom=0.08, hspace=0.05)
            axs = [fig.add_subplot(gs[0]), fig.add_subplot(gs[1])]

            # Spectrogram for window
            stft_window = stft[:, start_frame:end_frame]
            axs[0].matshow(np.log(stft_window + 1e-10), origin='lower', aspect='auto', cmap='jet')
            axs[0].set_ylabel('Frequency bins', fontsize=14)
            axs[0].set_title(f'Spectrogram and Eventogram (t={t:.1f}s)', fontsize=14)
            print(f'Spectrogram and Eventogram (t={t:.1f}s)')
            # Eventogram for window
            axs[1].matshow(window_output.T, origin='upper', aspect='auto', cmap='jet', vmin=0, vmax=1)
            window_labels = np.array(labels)[window_indexes]
            axs[1].yaxis.set_ticks(np.arange(0, top_k))
            axs[1].yaxis.set_ticklabels(window_labels, fontsize=14)
            axs[1].yaxis.grid(color='k', linestyle='solid', linewidth=0.3, alpha=0.3)
            axs[1].set_xlabel('Seconds', fontsize=14)
            axs[1].xaxis.set_ticks_position('bottom')

            # Adjust x-axis ticks for both plots
            window_seconds = (end_frame - start_frame) / frames_per_second
            tick_interval_window = max(1, int(window_seconds / 5))
            x_ticks_window = np.arange(0, end_frame - start_frame + 1, frames_per_second * tick_interval_window)
            x_labels_window = np.arange(int(start_frame / frames_per_second), int(end_frame / frames_per_second) + 1, tick_interval_window)
            
            for ax in axs:
                ax.xaxis.set_ticks(x_ticks_window)
                ax.xaxis.set_ticklabels(x_labels_window[:len(x_ticks_window)], rotation=45, ha='right', fontsize=10)
                ax.set_xlim(0, end_frame - start_frame)

            # Add marker
            marker_x = current_frame - start_frame
            for ax in axs:
                ax.axvline(x=marker_x, color='red', linewidth=2, alpha=0.8)

            fig.canvas.draw()
            img = np.frombuffer(fig.canvas.buffer_rgba(), dtype=np.uint8)
            img = img.reshape((fig_height_px, fig_width_px, 4))[:, :, :3]  # Drop alpha channel
            plt.close(fig)
            return img

        # Generate dynamic video
        eventogram_clip = VideoClip(make_frame, duration=duration)
        audio_clip = AudioFileClip(video_input_path)
        eventogram_with_audio_clip = eventogram_clip.with_audio(audio_clip)
        eventogram_with_audio_clip.fps = fps

        eventogram_with_audio_clip.write_videofile(
            output_video_path,
            codec="libx264",
            fps=fps,
            threads=os.cpu_count()
        )
        print(f"🎹 Saved the dynamic eventogram video to: \033[1;34m{output_video_path}\033[1;0m")
    else:
        print(f"🎞  Rendering static eventogram video …")
        static_eventogram_clip = ImageClip(fig_path, duration=duration)

        def marker_position(t):
            w = static_eventogram_clip.w
            x_start = int(left_frac * w)
            x_end = w
            frac = np.clip(t / max(duration, 1e-8), 0.0, 1.0)
            x_pos = x_start + (x_end - x_start) * frac
            return (x_pos, 0)

        marker = ColorClip(size=(2, static_eventogram_clip.h), color=(255, 0, 0)).with_duration(duration)
        marker = marker.with_position(marker_position)
        eventogram_visual_clip = CompositeVideoClip([static_eventogram_clip, marker])
        audio_clip = AudioFileClip(video_input_path)
        eventogram_with_audio_clip = eventogram_visual_clip.with_audio(audio_clip)
        eventogram_with_audio_clip.fps = fps

        eventogram_with_audio_clip.write_videofile(
            output_video_path,
            codec="libx264",
            fps=fps,
            threads=os.cpu_count()
        )
        print(f"🎹 Saved the static eventogram video to: \033[1;34m{output_video_path}\033[1;0m")

    if is_video:
        print("🎬  Overlaying source media with the eventogram…")
        root, ext = os.path.splitext(output_video_path)
        final_output_path = f"{root}_overlay{ext}"
        print(f"🎬  Source resolution:")
        _, _, base_w, base_h = get_duration_and_fps(audio_path)
        print(f"💁  Overlay resolution:")
        _, _, ovr_w, ovr_h = get_duration_and_fps(output_video_path)
        if base_w >= ovr_w:
            target_width, target_height = base_w, base_h
        else:
            target_width = ovr_w
            target_height = int(base_h * ovr_w / base_w)
            if target_height % 2:
                target_height += 1
        print(f"🎯 Target resolution: {target_width}x{target_height}")
        main_input, overlay_input = audio_path, output_video_path

        overlay_cmd = [
            "time", "-v",
            "ffmpeg", "-y",
            "-i", main_input,
            "-i", overlay_input,
            "-loglevel", "warning",
            "-filter_complex",
            (
                f"[0:v]scale={target_width}:{target_height}[main];"
                f"[1:v]scale={target_width}:{int(target_height * args.overlay_size)}[ovr];"
                f"[ovr]format=rgba,colorchannelmixer=aa={args.translucency}[ovr_t];"
                "[main][ovr_t]overlay=x=0:y=H-h[v]"
            ),
            "-map", "[v]",
            "-map", "0:a?",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
        ]
        if args.bitrate:
            overlay_cmd.extend(["-b:v", args.bitrate])
        else:
            overlay_cmd.extend(["-crf", str(args.crf)])
        overlay_cmd.extend([
            "-c:a", "copy",
            "-shortest",
            final_output_path
        ])

        try:
            subprocess.run(overlay_cmd, check=True)
            print(f"✅ 🎥 The new overlaid video has been saved to: \033[1;34m{final_output_path}\033[1;0m")
        except subprocess.CalledProcessError as e:
            print(f"\033[1;31mError during FFmpeg overlay: {e}\033[0m")
            return
        
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
                print(f"Deleted temporary CFR video: \033[1;34m{temp_video_path}\033[1;0m")
            except Exception as e:
                print(f"\033[1;33mWarning: Failed to delete temporary CFR video {temp_video_path}: {e}\033[0m")
    else:
        print("🎧 Source is audio-only — the eventogram video is the final output.")

if __name__ == '__main__':
    print(f"Eventogrammer, version 5.0.3, with dynamic window rendering, see the original here: https://github.com/qiuqiangkong/audioset_tagging_cnn")
    print(f"")

    parser = argparse.ArgumentParser(description='Audio tagging and Sound event detection.')
    parser.add_argument('audio_path', type=str, help='Path to audio or video file')
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
    parser.add_argument('--translucency', type=float, default=0.7,
                        help='Overlay translucency (0 to 1)')
    parser.add_argument('--overlay_size', type=float, default=0.2,
                        help='Overlay size as fraction of video height')
    parser.add_argument('--dynamic_eventogram', action='store_true', default=False,
                        help='Generate dynamic eventogram with scrolling window')
    parser.add_argument('--crf', type=int, default=23, help='FFmpeg CRF value (0-51, lower is higher quality)')
    parser.add_argument('--bitrate', type=str, default=None, help='FFmpeg video bitrate (e.g., "2000k" for 2 Mbps)')
    parser.add_argument('--window_duration', type=float, default=30.0,
                        help='Duration of sliding window for dynamic eventogram (seconds)')
    parser.add_argument('--use_adaptive_window', action='store_true', default=False,
                        help='Use adaptive window size based on event boundaries')

    args = parser.parse_args()

    if args.mode == 'audio_tagging':
        audio_tagging(args)
    else:
        sound_event_detection(args)
