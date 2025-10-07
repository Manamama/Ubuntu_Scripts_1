#First global variables:
tool_name_and_version = "Emotion Detector for Media Files: using WhisperX for speech recognition and diarization (detection of the speakers), FunASR for emotion detection, Plotly for visualizing results. Current Version: 5.4.1 | Author: ManamaMa"
#Note to self : the extraction for the HTML rendering of the chunks in 'def extract_media_segments' may need fixing: use the SRT files, not the TSV files or check if .bak is same as the new TSV file.

#Select the whisperx_model size here - "medium" runs relatively fast, but crashes Android. "small" does not crash Android, but may be too small. "large" or "large-v3" is best, but the slowest  
#whisperx_model_size="medium"
device = "cpu"
#Whisperx arguments, see its Github page or help:
batch_size = 2  # Adjust based on available resources
compute_type = "float32"  # Adjust based on available resources
disable_update=False # Disable update of the funasr models. But then they must be downloaded at least once, so set to : False at start. 

#Divisor for the share of the CPU cores to use, e.g. "2" meanas that 4 of the 8 CPU cores shall be available 
num_cores_divisor=2

import os
import subprocess
#Set your Hugging Face token here, for diarization, if needed (if not in the environment variable already):

# Accessing the HF_TOKEN environment variable safely
YOUR_HF_TOKEN=os.getenv('HF_TOKEN')







# List of required packages with specific versions
required_packages = [
    "playsound==1.2.2",
    "numpy",
    "whisperx",
    "pyannote.audio",
    "moviepy",
    "srt",
    "pymediainfo",
    "plotly",
    "funasr",
    "pydub",
    "onnx",
    "onnxconverter_common"
]

# Function to install packages
def install_packages(packages):
    import sys
    for package in packages:
        try:
            # Check if the package is already installed
            __import__(package.split("==")[0])  # Split to handle versioning
        except ImportError:
            # If not installed, install the package
            print(f"Installing {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# Install required packages
install_packages(required_packages)

# Additional commands for system packages (requires sudo)
def install_system_packages():
    print("Installing system packages: libmediainfo0v5, mediainfo, ffmpeg...")
    #subprocess.check_call(["sudo", "apt", "install", "-y", "libmediainfo0v5", "mediainfo", "ffmpeg"])

# Call the function to install system packages
install_system_packages()



'''
#You must use : 
pip install playsound==1.2.2
# see https://github.com/TaylorSMarks/playsound/issues/160 why so. 

#You must either 
#A. install: 
#pip install -U whisperx && pip  install numpy==1.26.4 

#with numpy not over 2.0

#Or:
#B. install any new numpy but reinstall all onnxruntime, spacy, pyannote.audio etc. to make them conform to newer numpy format
pip install -U whisperx && pip install -U pyannote.audio numpy

#You must install moviepy over 2.0
sudo apt install libmediainfo0v5 mediainfo ffmpeg
pip install -U moviepy

#Also these: 
pip install srt pymediainfo plotly funasr  playsound==1.2.2  pydub onnx onnxconverter_common

# The translate-shell package (optional), from : https://www.soimort.org/translate-shell/  , via wget https://www.soimort.org/translate-shell/trans and move it to a folder in your $PATH. Use this to update: 
# wget https://www.soimort.org/translate-shell/trans -O trans && chmod +x trans && sudo mv trans $(which trans)   

'''

#Imports of Python modules that do not take time:
import sys
import time
import datetime
import json

  
# Start measuring time
start_time = time.time()
import importlib.metadata
import subprocess

import argparse

from dataclasses import dataclass
import csv
import shutil
from pathlib import Path

from urllib.parse import quote
from pymediainfo import MediaInfo

import mimetypes





def generate_color_palette(num_shades):
    return [f"\033[38;5;{i}m" for i in range(196, 196 + num_shades)]

# Number of shades to use
num_shades = 20  # Adjust this number as needed

# Generate the color palette
colors = generate_color_palette(num_shades)

def rainbow_text(text):
    """Prints the given text in rainbow colors."""
    # Ascend through colors
    for i, char in enumerate(text):
        sys.stdout.write(colors[i % len(colors)] + char)
        sys.stdout.flush()
        time.sleep(0.005)  # Optional: Add delay for effect

    '''
    print()
    # Descend through colors
    for i, char in enumerate(text):
        sys.stdout.write(colors[(len(colors) - 1 - (i % len(colors))) % len(colors)] + char)
        sys.stdout.flush()
        time.sleep(0.005)  # Optional: Add delay for effect
    '''
    print("\033[0m")  # Reset color at the end
    print()  # New line after the text





 


def write_results(result, options, stage_suffix):

    """Helper function to write results in different formats."""
    # Create a subfolder for chunked files in the same directory as the video file
    #output_dir = media_path.parent / media_path.stem  # Create a folder named after the video file
    output_dir.mkdir(exist_ok=True)  # Create the folder if it doesn't exist

    
    get_writer_srt = whisperx.utils.get_writer("srt", output_dir)
    get_writer_tsv = whisperx.utils.get_writer("tsv", output_dir)
    get_writer_json = whisperx.utils.get_writer("json", output_dir)

    # Use Path to get the stem directly
    #stem = Path(media_path).stem  # Get stem directly from media_path
    # Construct filenames based on stage suffix
    srt_filename = f"{stem}_{stage_suffix}.srt"
    
    tsv_filename = f"{stem}_{stage_suffix}.tsv"
    json_filename = f"{stem}_{stage_suffix}.json"

    # Update output directory paths for each format
    get_writer_srt(result, os.path.join(output_dir, srt_filename), options)
    get_writer_tsv(result, os.path.join(output_dir, tsv_filename), options)
    get_writer_json(result, os.path.join(output_dir, json_filename), options)
    print(f"Debug info: we have created:  {srt_filename}, {tsv_filename}, {json_filename}")


def whisperx_transcribe(args):
    # Access additional arguments using kwargs if needed
    #global media_path, output_dir
    
    '''
    else:
        language_code = 'en'
    '''
    #These must be checked if exist now: 
    #verbose_mode = args.verbose
    #model = args.model
    '''
    
    for key, value in args.items():
        print(f"Argument {key}: {value}")
        
    language_code = args.get('--language')  # Default to none if not provided
    print(f"Language code passed as args:  `{language_code}`")
    '''    

    

    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Process the media file directly with WhisperX
    #print("\033[92mStage: Whisperx Process Audio in Python module\033[0m")
    


 
    #print(f"Processing: {media_path}")
    
    # and then check the speakers recognized by e.g. `grep "SPEAKER_[0-9][0-9]" "{output_dir}/*.srt" | cut -c -12 | sort | uniq`
    #print(f"Processing media file: {media_path}")

    print()

    # Additional asr_options required for a Whisperx bug. Or downgrade whisperx to 3.1.5 . It may also depend on Numpy version (Numpy over 2.0 does not require these options set, sic). 
    
    # Options for alignment and formatting
    #See: https://github.com/m-bain/whisperX/blob/main/whisperx/transcribe.py for defaults
    
    '''
    #Full options, some not yet implemented:
    

    So full syntax maybe:  model = load_model(model_name, device=device, device_index=device_index, download_root=model_dir, compute_type=compute_type, language=args['language'], asr_options=asr_options, vad_options={"vad_onset": vad_onset, "vad_offset": vad_offset}, task=task, threads=faster_whisper_threads)

        
 
    '''
    
   
  
    asr_options = {
        #"hotwords": None,
        #"multilingual:": True,
        #"vad_onset": 0.3,  # Lower value to detect speech earlier, default=0.500, Onset threshold for VAD (see pyannote.audio), reduce this if speech is not being detected 
        #"vad_offset": 0.4,  # Higher value to capture speech longer, default=0.363, Offset threshold for VAD (see pyannote.audio), reduce this if speech is not being detected. 
  
        #"chunk_size": 60,               # Increase chunk size to 60 seconds to reduce excessive chunking, default: 30
        #"min_duration_on": 0.5,         # Increase minimum duration for speech detection
        #"min_duration_off": 0.1,        # Increase minimum duration for silence detection
        #"segment_resolution": "chunk",  # Set to "sentence" or "chunk"
    }

    # Check if the language argument is provided
    if args.language != "":
        # User provided --language as an argument
        language_code = args.language  # Get the specified language code
        print(f"Language code passed on as argument: {language_code}. We shall pass it on to whisperx transcribe.")
        
        # Load the WhisperX model with the specified language
        model = whisperx.load_model(
            whisperx_model_size,
            device,
            compute_type=compute_type,
            language=language_code,
            threads=faster_whisper_threads,
            #This one is for newer whisperx versions only:
            asr_options=asr_options
            
        )
    else:
        # User did not provide the --language argument 
        #print("No language code passed on as argument. Autodetecting language...")
        
        # Load the WhisperX model without specifying a language (autodetect the language) 
        model = whisperx.load_model(
            whisperx_model_size,
            device,
            compute_type=compute_type,
            threads=faster_whisper_threads,
            #This one is for newer whisperx versions only:
            asr_options=asr_options
            
        )
    #For the older version use this without specifying these asr_options: 
    #model = whisperx.load_model(whisperx_model_size, device, compute_type=compute_type, language=language_code, asr_options=asr_options)

 

    
    
    
    audio = whisperx.load_audio(media_path)

    #Full: result = model.transcribe(audio, batch_size=batch_size, chunk_size=chunk_size, print_progress=print_progress)

    result = model.transcribe(audio, batch_size=batch_size, print_progress=True)

    print("Transcription Result:", result)
    
    language_code = result.get("language")  # Safely get the language key
    #These options are for the writer only:
    writer_options = {
        "max_line_width": None,
        "max_line_count": None,
        "highlight_words": False,
        "segment_resolution": "sentence",  # Set to "sentence" or "chunk" - the maximum number of characters in a line before breaking the line (default: sentence)
    }

    # Compute output directory from media_path
    write_results(result, writer_options, "transcription")

    return language_code  # Return the language code





def whisperx_align(args, language_code):
    # 2. Align whisper output
    print(f"We are starting alignment of the source file using the language: \033[94m{language_code}\033[0m ...")  # Blue
    


    # Construct filename for transcription results
    transcription_result_file = output_dir / f"{stem}_transcription.json"  # Update this if using a different suffix

    # Load the result from the alignment file
    try:
        with open(transcription_result_file, 'r') as f:
            result = json.load(f)  # Load the saved transcription results
    except FileNotFoundError:
        print(f"Error: The file {transcription_result_file} does not exist.")
        return  # Exit if file not found
    except json.JSONDecodeError:
        print("Error: Could not decode JSON from the transcription result file.")
        return  # Exit if there's an error in decoding
        
        

    # Load audio file directly from media_path
    audio = whisperx.load_audio(media_path)  # Use media_path directly


    
 
 
    # Load the alignment model and perform alignment
    model_a, metadata = whisperx.load_align_model(language_code=language_code, device=device)
    
    
    #Full:                 result = align(result["segments"], align_model, align_metadata, input_audio, device, interpolate_method=interpolate_method, return_char_alignments=return_char_alignments, print_progress=print_progress)

    result = whisperx.align(result["segments"], model_a, metadata, audio, device,
                             return_char_alignments=False, print_progress=True)
                             
        

    '''
    #We may print the results for debugging:
    print("\033[94mAlignment results:\033[0m")  # Blue
    print(result)  # Print result after setting the language manually
    '''

    result["language"] = language_code  # Set this manually after the previous detection
 
    #These options are for the writer only:
    writer_options = {
        "max_line_width": None,
        "max_line_count": None,
        "highlight_words": False,
        "segment_resolution": "sentence",  # Set to "sentence" or "chunk" - the maximum number of characters in a line before breaking the line (default: sentence)

    }
    
    write_results(result, writer_options, "alignment")
    



def whisperx_diarize(args, language_code):  
    # Construct filename for alignment results
    alignment_result_file = output_dir / f"{stem}_alignment.json"  # Update this if using a different suffix
    print (f"For the diarization step we are using this alignment_result_file: \033[94m{alignment_result_file}\033[0m") 
    # Load the result from the alignment file
    try:
        with open(alignment_result_file, 'r') as f:
            result = json.load(f)  # Load the saved alignment results
    except FileNotFoundError:
        print(f"Error: The file {alignment_result_file} does not exist.")
        return  # Exit if file not found
    except json.JSONDecodeError:
        print("Error: Could not decode JSON from the alignment result file.")
        return  # Exit if there's an error in decoding    # Initialize diarization model with authentication token

#Old:     diarize_model = whisperx.DiarizationPipeline(use_auth_token=YOUR_HF_TOKEN, device=device)
diarize_model = whisperx.diarize.DiarizationPipeline(use_auth_token=YOUR_HF_TOKEN, device=device)


    # add min/max number of speakers if known
    audio = whisperx.load_audio(media_path)
    diarize_segments = diarize_model(audio)

    print(f"Min speakers: \033[94m{min_speakers}\033[0m") 
    print(f"Max speakers: \033[94m{max_speakers}\033[0m") 
 
    
    #Use global args 
    #min_speakers=3
    #max_speakers=3
    
    
    diarize_model(audio, min_speakers=min_speakers, max_speakers=max_speakers)

    result = whisperx.assign_word_speakers(diarize_segments, result)
    
    print("Debugging info: the diarize_segments and speakers found:")
    print(diarize_segments)
    
    #Not needed, too much cruft shown on screen:
    #print("Debugging info: assigned segments only:")
    #print(result["segments"]) # segments are now assigned speaker IDs, but sometimes badly
    writer_options = {
    "max_line_width": None,
    "max_line_count": None,
    "highlight_words": False,
    "segment_resolution": "sentence",  # Set to "sentence" or "chunk" - the maximum number of characters in a line before breaking the line (default: sentence)
    }
    write_results(result, writer_options, "diarization")
    

    # Assuming output_dir and stem are defined globally
    diarization_result_file = output_dir / f"{stem}_diarization.json"  # Update this if using a different suffix

    try:
        # Read the diarization file JSON 
        with open(diarization_result_file, 'r') as file:
            data = json.load(file)

        # Extract segments information
        segments = []
        for segment in data.get('segments', []):
            try:
                # Check if 'speaker' key exists; if not, assign a pseudo speaker value
                if 'speaker' in segment:
                    speaker = segment['speaker']
                else:
                    speaker = 'SPEAKER_missing'  # We can assign a placeholder value if 'speaker' is not present. But ignore it for now - these are weird segments with the end timestamp earlier than the start timestamp. 
                    print(f"\033[91mWarning: Missing speaker key in segment starting at {segment['start']}\033[0m. We are either adding a 'missing' speaker, just in case.")  # Print in red
                
                segments.append({
                    'start': segment['start'],
                    'end': segment['end'],
                    'speaker': speaker  # Assign the speaker value or 'missing'
                })
            except KeyError as e:
                print(f"Error: Missing key '{e}' in segment data. Check this file for errors: '{diarization_result_file}'. Use e.g. jq '.segments[] | select(.speaker == null) | {start: .start, end: .end}' '{diarization_result_file}' ")
                sys.exit(1)  # Exit with a non-zero status to indicate an error

    except FileNotFoundError:
        print(f"Error: The file '{diarization_result_file}' was not found.")
        sys.exit(1)  # Exit with a non-zero status to indicate an error
    except json.JSONDecodeError:
        print(f"Error: Failed to decode JSON from the file '{diarization_result_file}'.")
        sys.exit(1)  # Exit with a non-zero status to indicate an error
        
      
    # Create DataFrame
    df = pd.DataFrame(segments)
    print(f"Debug info: the dataframe with the list of the speakers: ")
    print(f"{df['speaker']}")

    # Get unique speakers and assign y-positions
    unique_speakers = df['speaker'].unique()
    speaker_y_positions = {speaker: i for i, speaker in enumerate(sorted(unique_speakers))}

    # Prepare colors (using a color palette for multiple speakers)
    colors = px.colors.qualitative.Plotly[:len(unique_speakers)]
    speaker_colors = dict(zip(sorted(unique_speakers), colors))

    # Prepare traces for visualization
    traces = []
    legend_items = set()

    for speaker in unique_speakers:
        speaker_data = df[df['speaker'] == speaker]
        
        # Create separate line segments for each segment
        for _, segment in speaker_data.iterrows():
            # Create unique legend label with timestamp range
            legend_label = f"{speaker} ({segment['start']:.2f}-{segment['end']:.2f})"
            
            trace = go.Scatter(
                x=[segment['start'], segment['end']],
                y=[speaker_y_positions[speaker], speaker_y_positions[speaker]],
                mode='lines',
                #Case when over 10 speakers found:
                line=dict(color=speaker_colors.get(speaker, 'gray'), width=10),  # Default to gray if no color found
                name=legend_label if legend_label not in legend_items else None,
                showlegend=legend_label not in legend_items,
                hoverinfo='text',
                text=f"Speaker: {segment['speaker']}<br>Start: {segment['start']:.2f}<br>End: {segment['end']:.2f}"
            )
            traces.append(trace)
            
            # Track legend items to prevent duplicates
            legend_items.add(legend_label)

    # Create the layout with the media path included directly
    layout = go.Layout(
        title=f'Interim visualization of the WhisperX Speaker Diarization pass - "who says when", file: {media_path.name}',
        xaxis=dict(title='Timestamp (in seconds)'),
        yaxis=dict(
            title='Speakers identified', 
            tickvals=list(speaker_y_positions.values()), 
            ticktext=list(speaker_y_positions.keys()),
            tickmode='linear',
            dtick=1,
            range=[-0.5, len(unique_speakers)-0.5]
        ),
        height=400,
        width=None,
        margin=dict(l=50, r=50, t=50, b=50),
        autosize=True,
        showlegend=True
    )
    # Create figure and show
    fig = go.Figure(data=traces, layout=layout)

    # Update layout to make it responsive
    fig.update_layout(
        # Ensure the plot takes full width of the container
        xaxis_rangeslider_visible=False
    )

    fig.show()


def convert_ms_to_ffmpeg_format(ms):
    """Converts milliseconds to ffmpeg's HH:MM:SS.mmm format. Not used now, as pydub is better, but let us leave it, just in case."""
    seconds, milliseconds = divmod(ms, 1000)
    minutes, seconds = divmod(seconds, 60)
    hours, minutes = divmod(minutes, 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}"
    

def extract_media_segments(stage_suffix):
    """Extract audio segments from the video based on timestamps from a TSV file."""

    print()
    print("\033[92mStage: Extracting (chunking) the media segments from the original file, as per the TSV file with the sentence timestamps\033[0m")
    print(f"Loading the media file: \033[94m {media_path}\033[0m and chunking it as per the data created at pass: \033[94m{stage_suffix}\033[0m")  # Blue
    print("\033[94mThis may take some time, especially for larger files. You may use 'gnome-system-monitor', 'gotop' or the like tools to check the RAM and CPU usage of the Operating System. Once the file is loaded, we shall slice it into segments based on the timestamps provided in the TSV file.\033[0m")  # Blue
    print("")
    #print("\nHere's what going on behind the scenes:")
    #print("* The entire media file is loaded into RAM, which allows for quick access but requires significant memory.")
    #print("* Media extractor (MoviePy or ffmpeg) stores all media data as a Segment object.")
    #print("* We slice this object to create smaller segments without duplicating data until export.")
    print("* Ballpark figure what to expect: on a 3 GHz CPU, with 8 GB RAM, notebook it takes twice as much time to chunk the input media file as the file duration.")

    # Validate TSV file path in the output directory
    tsv_path_local = output_dir / (stem + '_' + stage_suffix + '.tsv')
    if not tsv_path_local.exists():
        raise FileNotFoundError(f"TSV file not found: {tsv_path_local}. Please ensure it exists.")
    # Count lines in the TSV file
    with open(tsv_path_local, 'r') as file:
        tsv_line_count = sum(1 for line in file) -1

    print(f"Number of lines in the TSV file that shall be processed: {tsv_line_count}")

    # Start timer for loading
    start_time = time.time()



    # Validate media file path
    if not media_path.exists():
        raise FileNotFoundError(f"Media file not found: {media_path}")
    #try:

    #MoviePy below. Relatively fast: 3 seconds per segment, on average. Speed does not degrade as we go on. It takes time but produces very well aligned audio and video chunks, which simple ffmpeg fails to do.  

    # Attempt to load as a VideoFileClip, fallback to AudioFileClip
    try:
        clip = VideoFileClip(str(media_path)).with_memoize(True) # Sets whether the clip should keep the last frame read in memory, see https://zulko.github.io/moviepy/reference/reference/moviepy.Clip.Clip.html#moviepy.Clip.Clip.with_memoize
        is_video = True  # If it loads as a VideoFileClip, it's a video
        print(f"Loading as media type: Video")
    except:
        clip = AudioFileClip(str(media_path))
        is_video = False  # Fallback to audio-only clip
        print(f"Loading as media type: Audio")


    
    '''
    #Not needed now:
    #print(original_extension)
    if original_extension==".webm":
        print("We are dealing with the WebM file and we shall apply special codecs in the output for that one.")
        video_codec = 'libvpx'      # Use VP8 codec for WebM
        audio_codec = 'libvorbis'    # Use Vorbis codec for audio in WebM
    else:
        video_codec = 'libx264'      # Default to H.264 codec for other formats
        audio_codec = 'aac'           # Default to AAC codec for audio in other formats

    #exit(1)
    '''


    load_time = time.time() - start_time  # Calculate load time
    print(f"Loaded media file in {load_time:.2f} seconds.")




    # Create media_chunks.scp file for Kaldi format
    media_chunks_scp_path = output_dir / (stem+"_"+ stage_suffix + '_media_chunks.scp')
    with open(media_chunks_scp_path, 'w') as media_chunks_scp:


        # Backup the original TSV file
        tsv_backup_path = str(tsv_path_local) + '.bak'  # Convert to string for concatenation
        shutil.copyfile(tsv_path_local, tsv_backup_path)

        # Read and process the TSV file
        updated_tsv_data = []
        with open(tsv_path_local, 'r') as tsv_file:
            lines = list(csv.reader(tsv_file, delimiter='\t'))
            header = lines[0]  # Save header if needed
            updated_tsv_data.append(header)  # Include header in updated data

            for i in range(1, len(lines)):
                start_ms = int(lines[i][0])
                end_ms = int(lines[i][1])
                duration_ms = end_ms - start_ms
                
                if duration_ms < 500:
                    print(f"\033[91m{duration_ms}\033[0m - Duration (ms) in the\033[91m TSV file segment {i}:\033[0m - Start Time (ms): {start_ms}, End Time (ms): {end_ms}, which is too short, so:") 

                    
                    if i + 1 < len(lines):
                        new_end_ms = int(lines[i + 1][0])   # Get start time of next segment 
                        new_duration_ms = new_end_ms - start_ms  # Calculate new duration
                        
                        print(f"\033[94m{new_duration_ms}\033[0m - is the new value of Duration that we have fixed the original duration to.")  
                        updated_tsv_data.append([start_ms, new_end_ms, lines[i][2]])  # Update with new end time
                      

                    else:
                        print(f"The last segment remains unchanged: {lines[i]}")
                        updated_tsv_data.append(lines[i])  # Last segment remains unchanged
                else:
                    updated_tsv_data.append(lines[i])  # Append segments with acceptable durations

                        
                        
        # Write updated data back to a new TSV file or overwrite original if preferred
        with open(tsv_path_local, 'w', newline='') as tsv_file:
            writer = csv.writer(tsv_file, delimiter='\t')
            writer.writerows(updated_tsv_data)

        #"""
        #Manual way to chunk TSV file, via loop: 

        # Read the TSV file for timestamps
        line_count = 0
        with open(tsv_path_local, 'r') as tsv_file:
            next(tsv_file)  # Skip the header
            
            for line in csv.reader(tsv_file, delimiter='\t'):
                start_ms = int(line[0])
                end_ms = int(line[1])
                line_count += 1  # Increment the line counter for each processed line
                
                # Convert milliseconds to seconds for FFmpeg
                start_time_sec = start_ms / 1000.0
                end_time_sec = end_ms / 1000.0
                #'''
                       # Calculate duration, as sometimes the end time was before the start time: 
                duration = end_time_sec - start_time_sec
                
                # Debugging output for timestamps
                print()
                print(f"Segment {line_count} out of {tsv_line_count}: Duration (sec): \033[94m{duration:.3f}\033[0m, Start Time (sec): {start_time_sec:.3f}, End Time (sec): {end_time_sec:.3f} - processing it...")
                #'''
                
                # Create an output file name for the segment
                #segment_output_file = output_dir / f"{stem}_{stage_suffix}_segment_{line_count:03d}{media_path.suffix}"
                #Naah, let us save and recode all media to mp4:
                segment_output_file = output_dir / f"{stem}_{stage_suffix}_segment_{line_count:03d}.mp4"

                # Start timer for exporting
                export_start_time = time.time()



                # Determine the MIME type of the input file
                mime_type, _ = mimetypes.guess_type(media_path)
                    
                # Extract the subclip
                segment_clip = clip.subclipped(start_time_sec, end_time_sec)

                # Write the segment to a file directly
                
                
                if is_video:
                    #This preview theoretically works, but : `AttributeError: 'FFPLAY_AudioPreviewer' object has no attribute 'logfile'`, so we skip it
                    #segment_clip.preview(fps=20)
                    segment_clip.write_videofile(
                        str(segment_output_file),
                        audio=True,
                        #codec=video_codec,
                        #audio_codec=audio_codec
                    )
                else:
                    segment_clip.write_audiofile(
                        str(segment_output_file),
                        #,
                        codec='aac'
                    )  



                export_time = time.time() - export_start_time  # Calculate export time
                # Add each segment to the media_chunks.scp file in Kaldi format
                media_chunks_scp.write(f"segment_{line_count:03d}\t{segment_output_file}\n")

                print(f"Segment \033[94m{line_count:03d} out of {tsv_line_count} \033[0m, saved in (sec): \033[94m{export_time:.2f}.\033[0m to file: {segment_output_file}")  # Blue  # Print path and time

                    
                    
                #""" 
                
        '''
        #Or do  it elegantly (?) via a class
        # Process all chunks directly using the processor
        print("Debug info: we are using the TsvChunkProcessor(tsv_path_local, tsv_line_count, clip, stage_suffix, is_video,  video_codec, audio_codec, media_chunks_scp) method...")
 
        tsv_processor = TsvChunkProcessor(tsv_path_local, tsv_line_count, clip, stage_suffix, is_video,  video_codec, audio_codec, media_chunks_scp)
       
        # Process all chunks by consuming the iterator
        all_segments = list(tsv_processor)  # This processes all segments and stores output file paths in a list
        print(f"Debug info: all filepaths chunked: {all_segments}")
        '''


        
        '''
        # If MoviePy failes, then use FFmpeg. Add # to the three quote signs. Initialize the FFmpeg command instead, with copy original streams:
        Here a possible trick: find P or B frames some seconds before the chunk: it makes the video appear then, but dangerous as it just adds some time:

        lead_time = 0.5 
        #But it creates audio sync problems ... 
        #            '-async', '1',  # it does nothing, nor some '-accurate_seek', nor '-seek_timestamp', '1',  # Enable seeking by timestamp 

    
        start_time = max(row['start'] - lead_time, 0)  # Adjust start time with lead time

        ffmpeg_command = [
            'ffmpeg',
            '-ss', str(start_time_sec),       # Start time in seconds,  to specify -ss timestart before -i input_file.ext, because it sets (or so I understand) the beginning of the generated video to the nearest keyframe found before your specified timestamp.
            '-to', str(end_time_sec),         # End time in seconds
            '-i', str(media_path),            # Input media path

            '-y',                              # Overwrite output files without asking
            str(segment_output_file),         # Output file path (should have .mp4 extension)
            '-c:v', 'copy',                   # Copy video stream without re-encoding
            '-c:a', 'copy'                    # Copy audio stream without re-encoding
        ]
        # Execute the FFmpeg command
        subprocess.run(ffmpeg_command)
        '''



 
        #print("Chunking complete.")

    # Final load time calculation and message
    total_load_time = time.time() - start_time  # Calculate total load time
    print()
    print(f"Finished media chunking in \033[94m{total_load_time:.2f}\033[0m seconds.")   





        
@dataclass
class Emotion:
    label: str
    score: float

    @property
    def scaled_score(self):
        #Modify the number here to make the emotion bar line longer or shorter:  
        return int(round(self.score * 50))

    def get_bar_representation(self):
        return '█' * self.scaled_score


# Function to read TSV file and extract timestamps and sentences
def read_tsv_file(tsv_path_local):
    try:
        # Read the TSV file into a DataFrame
        df = pd.read_csv(tsv_path_local, delimiter='\t')
        
        # Extract start, end timestamps, and text
        return df[['start', 'end', 'text']].values.tolist()
    
    except Exception as e:
        print(f"An error occurred while reading the TSV file: {e}")
        return []


def read_srt_file(srt_path_local):
    try:
        # Read the SRT file into a string
        with open(srt_path_local, 'r', encoding='utf-8') as f:
            srt_content = f.read()
        
        # Parse the SRT content into subtitle objects
        subtitles = list(srt.parse(srt_content))
        
        # Extract start, end timestamps (in seconds), and text
        return [[sub.start, sub.end, sub.content] for sub in subtitles]
    
    except Exception as e:
        print(f"An error occurred while reading the SRT file: {e}")
        return []
        
        

def display_result_temp_html(stage_suffix, language_code):


    print()
    #extract_media_segments(stage_suffix)
    print(f"\033[92mStage: Processing the emotions after: \033[0m{stage_suffix}\033[92m; visualizing the emotions in terminal and as a static HTML file with a plotly graph\033[0m")
    print(f"\033[94mThis stage should be relatively quick. The files for the emotion detection model (the 'electronic brain' behind it all) may be downloaded now, too. Go and take a coffee then.\033[0m")  # Blue
    print()
    output_html_path = output_dir / (stem +  '_' + stage_suffix +  '_emotions.html')

    # Validate TSV or SRT file path in the output directory
    '''
    tsv_path_local = output_dir / (stem + '_' + stage_suffix + '.tsv')
    if not tsv_path_local.exists():
        raise FileNotFoundError(f"TSV file not found: {tsv_path_local}. Please ensure it exists.")
        '''
    srt_path_local = output_dir / (stem + '_' + stage_suffix + '.srt')
    if not srt_path_local.exists():
        raise FileNotFoundError(f"SRT file not found: {srt_path_local}. Please ensure it exists.")


    # Command to execute to run translation 
    #print("Rough translation to English, Internet access is required. The sentences shown may be duplicated - do look at the last set of strings then:")
    print(f"\033[94m") #Blue
    command = f"trans {language_code}:en -i {srt_path_local} -e google"
    try:
        # Execute the command that requires Internet access
        print()
        #subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        # Handle the error if the command fails
        print(f"\033[91m") # Red color for error message
        print(f"Error occurred while executing the translation command: {e}")
        print("Check your Internet connection and try again.")
        print(f"\033[0m") # Reset text color

    print(f"\033[0m") # Reset text color to default


    #original_extension = media_path.suffix

    # Validate TSV file path in the output directory
     

    #sentences_data = read_tsv_file(tsv_path_local)
    #We must read the SRT file now, as only this contains diarized sentences:
    sentences_data = read_srt_file(srt_path_local)

    # Define a mapping of emotion labels to emoticons
    emotion_emoticons = {
        '生气/angry': '😠',
        '厌恶/disgusted': '🤢',
        '恐惧/fearful': '😨',
        '开心/happy': '😊',
        '中立/neutral': '😐',
        '其他/other': '🤷‍♂️',
        '难过/sad': '😢',
        '吃惊/surprised': '😲',
        '<unk>': '❓'
    }

    # Open media_chunks.scp for reading in the new output directory
    media_chunks_scp_path = output_dir / (stem+"_"+ stage_suffix + '_media_chunks.scp')

    print()
    
    print(f"Emotion detection of the chunks listed in: {media_chunks_scp_path}...")
    
    #Download of a models at first is needed, see https://github.com/ddlBoJack/emotion2vec
    """
from modelscope.pipelines import pipeline
from modelscope.utils.constant import Tasks

inference_pipeline = pipeline(
    task=Tasks.emotion_recognition,
    model="iic/emotion2vec_base_finetuned", # Alternative: iic/emotion2vec_plus_seed, iic/emotion2vec_plus_base, iic/emotion2vec_plus_large and iic/emotion2vec_base_finetuned
    model_revision="master")

rec_result = inference_pipeline('https://isv-data.oss-cn-hangzhou.aliyuncs.com/ics/MaaS/ASR/test_audio/asr_example_zh.wav', output_dir="./outputs", granularity="utterance", extract_embedding=False)
print(rec_result)

"""

    # Process the media_chunks.scp file with FunASR or any other model.
    #If offline  - modify the filepath:
    #model = AutoModel(model=str(Path.home() / ".cache" / "modelscope" / "hub" / "iic" / "emotion2vec_base_finetuned"), device=device)
    #If online - it will be downloaded and checked each time, but requires Net connection always:
    '''
    
from funasr import AutoModel

model = AutoModel(model="iic/emotion2vec_base_finetuned", disable_update=disable_update) # Alternative: iic/emotion2vec_plus_seed, iic/emotion2vec_plus_base, iic/emotion2vec_plus_large and iic/emotion2vec_base_finetuned

wav_file = f"{model.model_path}/example/test.wav"
rec_result = model.generate(wav_file, output_dir="./outputs", granularity="utterance", extract_embedding=False)
print(rec_result)


Or, in command line:
funasr ++model='iic/emotion2vec_base_finetuned' ++vad_model="fsmn-vad" ++punc_model="ct-punc" ++input=""
funasr ++model='iic/emotion2vec_base_finetuned' ++vad_model="fsmn-vad"   ++input=""

'''
    

    # Check if the media_chunks.scp file exists
    if not media_chunks_scp_path.exists():
        raise FileNotFoundError(f"The chunks list file does not exist at: {media_chunks_scp_path}. Please ensure that it has been created correctly. You may need to reset the steps completed manually in the 'tracker.json' in the output folder, too.")

    # If it exists, print out which files are being passed to the model
    print(f"We are passing this list of files in the Kaldi format to the model: {media_chunks_scp_path}")
    

    #Either online, download once only, it throws an error if no Net:    
    #model = AutoModel(model="iic/emotion2vec_base_finetuned", device=device, disable_update=False)
    # Or offline - load the model using the universal cache directory in one line

    model = AutoModel(model=str(Path.home() / ".cache" / "modelscope" / "hub" / "iic" / "emotion2vec_base_finetuned"), device=device, disable_update=True)

        
    # Load the model and generate results
    rec_result = model.generate(input=str(media_chunks_scp_path), output_dir="./outputs", granularity="utterance", extract_embedding=False)
    
    #print(rec_result)
    
    output_path = output_dir / (stem +  '_' + stage_suffix + '_recognized_emotions_dictionaries.txt')
    
    # Save the results to the specified output path without using a loop
    with open(output_path, 'w') as f:
        f.write(str(rec_result))  # Write the entire result as a string
    

    with open(output_html_path, 'w', encoding='utf-8') as output_file:
    # Write HTML content
        # Write HTML content
        output_file.write(f'<html>\n<head>\n<meta charset="UTF-8">\n<title>Emotion Scores Visualization: {media_path.name}</title>\n')
        output_file.write("<style>\nbody { font-family: Arial, sans-serif; margin: 20px; }\nh1 { color: #333; }\n")
        output_file.write("h2 { color: #555; }\np { margin: 5px 0; }\n")
        output_file.write(".video-small { height: 300px; cursor: pointer; }\n")

        # Table styling
        output_file.write("table { width: 100%; border-collapse: collapse; border-spacing: 0; }\n")  # No spacing between cells
        output_file.write("th, td { padding: 0; border: 1px solid #ccc; }\n")  # Set padding to zero for all cells
        output_file.write("td:first-child { width: 80%; vertical-align: top; }\n")
        output_file.write("td:last-child { width: 20%; vertical-align: top; }\n")


        output_file.write("</style>\n<script src='https://cdn.plot.ly/plotly-latest.min.js'></script>\n</head>\n<body>\n")
        
        #tool_name_and_version = "Emotion Detector v1.0"  # Update this line accordingly
        output_file.write(f"{tool_name_and_version}\n")
        
        #print(f"{tool_name_and_version}")
        output_file.write(f'<h1>Emotion Scores Visualization, for Stage: {stage_suffix}, of the file: <a href="../{media_path.name}"> {media_path.name} </a> </h1>\n')
        output_file.write(f"(An interactive Plotly graph is about to appear below, which takes time, as over 3 MB may need to be downloaded from  <a href='https://cdn.plot.ly/plotly-latest.min.js'>cdn.plot.ly</a>, so do wait... \n")
        output_file.write(f"Tip: use the <strong><a href='https://gofullpage.com/'>GoFullPage</strong></a> extension to capture this page with the video previews as images, which thumbnails shall be missed by the standard printing to PDF or saving this page).\n")

        # Initialize variables for plotting and storing segments
        plot_dict = {}
        segments = [0]  # Start segments with 0

        # Process each result in rec_result and create Emotion instances
        for i, result in enumerate(rec_result):

            segments.append(i + 1)  # Segment index for the X-axis
            
            # Create Emotion instances from labels and scores
            emotions = [Emotion(label, score) for label, score in zip(result['labels'], result['scores'])]
            
            # Append initial zero scores for each emotion before adding actual scores
            for emotion in emotions:
                if emotion.label not in plot_dict:
                    plot_dict[emotion.label] = [0]  # Initialize list with a zero entry for new labels
                plot_dict[emotion.label].append(emotion.score)  # Append scores to the respective label list

        # Convert scores to a DataFrame for cumulative calculation
        df_cumulative = pd.DataFrame(plot_dict)

        # Calculate cumulative sums for each label
        cumulative_sums = df_cumulative.cumsum()

        # Build Plotly traces as line charts with markers
        plot_data = []

        for label in cumulative_sums.columns:
            plot_data.append(go.Scatter(
                x=segments,
                y=cumulative_sums[label],
                mode='lines+markers',  # Show lines and markers labels
                name=label,
                marker=dict(size=10),  # Size of the markers
                text=[f"{score:.2f}" for score in cumulative_sums[label]],  # Display scores as text labels
                textposition="top center"  # Position of the text labels
            ))

        # Generate Plotly figure
        fig = go.Figure(data=plot_data)
        fig.update_layout(
            title="Emotion Progression Over Time (interactive graph)",
            xaxis_title="Segment Index",
            yaxis_title="Cumulative Emotion Score",
            legend_title="Emotions",
            xaxis=dict(
                tickmode='array',
                tickvals=segments,  # Use segment numbers directly
                ticktext=[str(segment) for segment in segments],  # Convert segments to strings for display
                tickangle=90  # Rotate tick labels to be vertical
            ),
        )

        # Write the Plotly chart to HTML
        output_file.write(fig.to_html(full_html=False, include_plotlyjs='cdn'))

        #print("Inserted Plotly line chart with markers before the table.")




        if stage_suffix=="diarization":
            ### Visualization for Speaker Diarization ###
            print(f"Debug info: We are adding the diarization graph to the HTML file, assuming that it is the rigth pass...") 

            # Assuming output_dir and stem are defined globally
            diarization_result_file = output_dir / f"{stem}_diarization.json"  # Update this if using a different suffix

            try:
                # Read the diarization file JSON 
                with open(diarization_result_file, 'r') as file:
                    data = json.load(file)

                # Extract segments information, add again the missing speakers (duplicate process, just in case, see also the diarization def above)
                segments = []
                for segment in data.get('segments', []):
                    try:
                        # Check if 'speaker' key exists; if not, assign a pseudo speaker value
                        if 'speaker' in segment:
                            speaker = segment['speaker']
                        else:
                            speaker = 'SPEAKER_missing'  # We can assign a placeholder value if 'speaker' is not present. But ignore it for now - these are weird segments with the end timestamp earlier than the start timestamp. 
                            print(f"\033[91mWarning: Missing speaker key in segment starting at {segment['start']}\033[0m. We are adding a 'missing' speaker, just in case.")  # Print in red
                        
                        segments.append({
                            'start': segment['start'],
                            'end': segment['end'],
                            'speaker': speaker  # Assign the speaker value or 'missing'
                        })
                    except KeyError as e:
                        print(f"Error: Missing key '{e}' in segment data. Check this file for errors: '{diarization_result_file}'. Use e.g. jq '.segments[] | select(.speaker == null) | {start: .start, end: .end}' '{diarization_result_file}' ")
                        sys.exit(1)  # Exit with a non-zero status to indicate an error

            except FileNotFoundError:
                print(f"Error: The file '{diarization_result_file}' was not found.")
                sys.exit(1)  # Exit with a non-zero status to indicate an error
            except json.JSONDecodeError:
                print(f"Error: Failed to decode JSON from the file '{diarization_result_file}'.")
                sys.exit(1)  # Exit with a non-zero status to indicate an error
            
            # Create DataFrame for speaker data (assuming 'segments' contains speaker info)
            df = pd.DataFrame(segments)
            
            print(f"Debug dataframe with the speakers: ")
            print(f"{df['speaker']}")

            unique_speakers = df['speaker'].unique()
            speaker_y_positions = {speaker: i for i, speaker in enumerate(sorted(unique_speakers))}
            
            colors = px.colors.qualitative.Plotly[:len(unique_speakers)]
            speaker_colors = dict(zip(sorted(unique_speakers), colors))

            traces = []
            legend_items = set()

            for speaker in unique_speakers:
                speaker_data = df[df['speaker'] == speaker]
                
                for _, segment in speaker_data.iterrows():
                    legend_label = f"{speaker} ({segment['start']:.2f}-{segment['end']:.2f})"
                    
                    trace = go.Scatter(
                        x=[segment['start'], segment['end']],
                        y=[speaker_y_positions[speaker], speaker_y_positions[speaker]],
                        mode='lines',
                        line=dict(color=speaker_colors.get(speaker, 'gray'), width=10),
                        name=legend_label if legend_label not in legend_items else None,
                        showlegend=legend_label not in legend_items,
                        hoverinfo='text',
                        text=f"Speaker: {segment['speaker']}<br>Start: {segment['start']:.2f}<br>End: {segment['end']:.2f}"
                    )
                    traces.append(trace)
                    
                    legend_items.add(legend_label)

            layout = go.Layout(
                title=f"Who says when (speakers' timestamps)",
                xaxis=dict(title='Timestamp (in seconds)'),
                yaxis=dict(
                    title='Speakers identified', 
                    tickvals=list(speaker_y_positions.values()), 
                    ticktext=list(speaker_y_positions.keys()),
                    tickmode='linear',
                    dtick=1,
                    range=[-0.5, len(unique_speakers)-0.5]
                ),
                height=400,
                width=None,
                margin=dict(l=50, r=50, t=50, b=50),
                autosize=True,
                showlegend=False
            )

            fig_speaker = go.Figure(data=traces, layout=layout)

            fig_speaker.update_layout(
                xaxis_rangeslider_visible=False
            )

            # Write the second Plotly chart (speaker visualization) to HTML
            output_file.write(fig_speaker.to_html(full_html=False, include_plotlyjs='cdn'))

            print("Inserted Plotly speaker visualization after emotion progression.")




        # Open the table here
        output_file.write("<table>\n")  # Open the table
        
        
        # Debugging Output: Check times of the rec_result and sentences
        print("Debug info: They should be equal:")
        print(f"{len(sentences_data)} - the number of the sentences in the TSV file with the media chunks.")
        print(f"{len(rec_result)} - the number of the results in the rec_result dictionary of the emotions detected by the funasr model.")

        current_emotions_list = []  # Initialize before entering the loop

        for i, result in enumerate(rec_result):
            try:
                #sentence = sentences[i]  # Get the sentence from the TSV file
                start_time_ms, end_time_ms, sentence = sentences_data[i]  # Get data from TSV
                print(f"Sentence: {sentence}")

                # Create an output file name for the segment
                #segment_filepath = f"{stem}_{stage_suffix}_segment_{i+1:03d}{original_extension}"  # Prepare segment filepath
                #But we changed all to .mp4 so
                segment_filepath = f"{stem}_{stage_suffix}_segment_{i+1:03d}.mp4"  # Prepare segment filepath
                
                output_file.write("<tr>\n")  # Start a new table row
                output_file.write("<td>\n")  # Open left column
                
                # Write segment information in the left column
                output_file.write(f' <h2>{sentence}</h2>\nChunk #<a href="{segment_filepath}">{i+1:03d}</a>, timestamps: [{start_time_ms} - {end_time_ms}]:\n')
                
                # Start mini table for emotions
                output_file.write("<table style='width: 100%; border-collapse: collapse;'>\n")
                output_file.write("    <thead>\n")
                output_file.write("        <tr>\n")
                output_file.write("            <th style='text-align: left;'>Emotion Label</th>\n")
                output_file.write("            <th style='text-align: left;'>Score</th>\n")
                output_file.write("            <th style='text-align: left;'>Representation</th>\n")
                output_file.write("        </tr>\n")
                output_file.write("    </thead>\n")
                output_file.write("    <tbody>\n")

                emotions = [Emotion(label, score) for label, score in zip(result['labels'], result['scores'])]
                
                # Directly append emotions to current_emotions_list
                current_emotions_list.append({
                    "sentence": sentence,
                    "start_time_s": start_time_ms.total_seconds(),
                    "end_time_s": end_time_ms.total_seconds(),
                    "emotions": []  
                })

                for emotion in emotions:
                    bar = emotion.get_bar_representation()  # Get bar representation
                    emoticon = emotion_emoticons.get(emotion.label, '')  # Get emoticon
                    
                    output_file.write(f"        <tr>\n")
                    output_file.write(f"            <td style='width: 12%;'>{emotion.label} {emoticon}</td>\n")  # Emotion Label
                    output_file.write(f"            <td style='width: 8%;'>{emotion.score:.6f}</td>\n")       # Score
                    output_file.write(f"            <td style='width: 80%;'>[{bar}]</td>\n")                # Representation
                    output_file.write(f"        </tr>\n")

                    # Append emotion data directly to the last entry in current_emotions_list
                    current_emotions_list[-1]["emotions"].append({
                        "label": emotion.label,
                        "score": round(emotion.score, 3),  # Round to 3 decimal places, they should be enough for AIs
                        #"representation": bar  # Optional if needed. Not needed for AIs.
                    })

                    print(f", {emotion.label}, {emotion.score:.3f}") 

                output_file.write("    </tbody>\n")
                output_file.write("</table>\n")  # Close mini table

                output_file.write("</td><td>\n")  # Close left column and open right column
                
                output_file.write(f"<video class='video-small' controls><source src='{segment_filepath}' type='video/mp4'>Your browser does not support the video tag.</video><br>\n")

                output_file.write("</td></tr>\n")  # Close table row

            except IndexError:
                print(f"Warning: Index out of range when accessing sentences at index {i}. Stopping further processing.")
                break  # Exit the loop if index is out of range

        output_file.write("</table>\n")  # Close the table
        output_file.write("</body>\n</html>")
        print()

        # After processing all sentences, export current_emotions_list to a JSON file
        output_json_path = output_dir / (stem + '_' + stage_suffix + '_emotions.json')
        with open(output_json_path, 'w', encoding='utf-8') as json_file:
            json.dump(current_emotions_list, json_file, ensure_ascii=False, indent=4)

        print(f"The above results are also saved as JSON (e.g. for AIs to process) to: \033[94m{output_json_path}\033[0m")

        # Create and save the AI-friendly flattened JSON
        flattened_data = []
        for entry in current_emotions_list:
            new_entry = {
                "sentence": entry["sentence"],
                "start_time_s": entry["start_time_s"],
                "end_time_s": entry["end_time_s"]
            }
            for emotion in entry["emotions"]:
                label = emotion["label"].split("/")[-1].replace("<", "").replace(">", "")
                new_entry[label] = emotion["score"]
            flattened_data.append(new_entry)
        
        output_ai_json_path = output_dir / (stem + '_' + stage_suffix + '_emotions_ai_friendly.json')
        with open(output_ai_json_path, 'w', encoding='utf-8') as json_file:
            json.dump(flattened_data, json_file, ensure_ascii=False, indent=4)
        
        print(f"AI-friendly flattened JSON saved to: \033[94m{output_ai_json_path}\033[0m")
        print(f"The above results are also saved as HTML to: \033[94m{output_html_path}\033[0m")

        print()




        #print(f"The output path of the resulting HTML is: {output_html_path}" )
        print(f"Opening the result \033[94m{output_html_path}\033[0m in the default browser. It may also take some time and it may fail if there is no default browser or the filename has weird characters. ")
        print()
        print()
        # Open the HTML file in the default web browser
        # Encode the file path
        encoded_path = quote(os.path.abspath(output_html_path))

        webbrowser.open(f'file://{os.path.abspath(encoded_path)}')



'''

---

# Guide to Interpreting the Emotions JSON Structure , 1.0

This document provides an overview of the JSON format used to represent emotional content associated with sentences. Each entry in the JSON array contains a sentence along with its corresponding emotions and their intensity scores.

## JSON Structure Overview

The JSON data is structured as follows:

```json
[
    {
        "sentence": "Example sentence here.",
        "start_time_ms": <integer>,   
        "end_time_ms": <integer>,     
        "emotions": [
            {
                "label": "Emotion Label",
                "score": Emotion Score
            },
            ...
        ]
    },
    ...
]
```

## Key Components

### Sentence:
- Each object in the array represents a single sentence.

### Timestamps of the sentence:
- Each sentence has associated timestamps in milliseconds, indicating when the sentence starts and ends within the audio or video context.

### Emotions:
- The "emotions" key holds an array of emotion objects associated with the sentence.
- Each emotion object includes:
  - **label**: A string representing the name of the emotion (e.g., "生气/angry" for "angry").
  - **score**: A numerical value (between 0 and 1) indicating the intensity or strength of that emotion in relation to the sentence. Higher values indicate stronger emotional responses.
 
## Emotion Definitions
- **Emotions**: The model recognizes various emotional states based on the vocal cues only:
  - **Angry**: Frustration or hostility.
  - **Happy**: It is not "happy" as such, but it indicates the generic: "emotional", "agitated", a high affect.
  - **Sad**: sorrow or disappointment, a low affect.
  - **Fearful**: anxiety or apprehension.
  - **Disgusted**: aversion or strong disapproval.
  - **Surprised**: shock or unexpectedness.
  - **Neutral**: lack of strong emotional expression, flat affect.
  - **Other**: Captures emotions that have been detected but do not fit standard categories.
  - **Unknown** `<unk>`: even more unusual emotions that do not fit predefined categories, often arising in ambiguous or complex situations. 

## Interpreting Emotion Scores
- **Low Scores**: Scores close to zero indicate minimal emotional presence.
- **Multiple Emotions**: The highest score represents the dominant emotion, but other emotions are relevant. In fact, the presence of multiple emotions is a signal in itself. 

## Contextual Factors
- The emotion recognition model operates solely on auditory features, relying on vocal characteristics only, not on the textual content. The sentences have been added separately to this JSON, for you. 

## Conclusion
This JSON format provides a structured way to analyze and interpret emotional content within sentences. Use this structured data to gain deeper insights into the feelings and responses captured in the text.
 




'''

'''
Actual command: 
Task:
Please provide a summary analysis of the emotional scores from the JSON file attached. Do find:
Shifts in Dominant Emotion: Highlight sentences with notable emotional scores and explain what they reveal about the speaker's feelings beyond the plain text.
Emotional Nuance: Discuss any sentences that exhibit complexity in emotional expression based on their scores.
Significant Contrasts: Identify sentences that sharply contrast with others in terms of emotional expression.



Or:

The overall progression of emotions as if they were musical notes.
Key shifts in dominant emotions and their implications.
Contrasts between different emotional expressions.
Present this analysis in a flowing narrative style, similar to how one might describe the dynamics of a musical piece


'''
        

def initialize_tracker(tracker_file):
    # Initialize tracker with all stages set to "not started"
    output_dir.mkdir(exist_ok=True)  # Create the folder if it doesn't exist

    tracker_data = {
    }
    with open(tracker_file, 'w') as f:
        json.dump(tracker_data, f)



def read_tracker(tracker_file):
    if os.path.exists(tracker_file):
        with open(tracker_file, 'r') as f:
            return json.load(f)
    return {}

def update_tracker(tracker_file, stage):
    statuses = read_tracker(tracker_file)
    #statuses[stage] = ("completed", datetime.datetime.now().isoformat())
    statuses[stage] = ("completed")
    
    with open(tracker_file, 'w') as f:
        json.dump(statuses, f)
    print(f"The Run Tracker status quo: \033[94m{statuses}\033[0m")
        
        

  	
# Function to call ExifTool and print track information
def print_exif_info(file_path):
    try:
        # Call ExifTool and capture the output
        print()
        print(f"Detailed exif media information for the file: {file_path}")
        result = subprocess.run(['exiftool', file_path], capture_output=True, text=True)

        # Check if ExifTool executed successfully
        if result.returncode == 0:
            print(result.stdout)  # Print the output from ExifTool
        else:
            print(f"Error executing ExifTool: {result.stderr}")
    except Exception as e:
        print(f"An error occurred: {e}")




# Function to get and print the duration of any media file
def print_media_duration_info(file_path):
    media_info = MediaInfo.parse(file_path)
    duration_ms = media_info.tracks[0].duration  # Accessing duration directly from the first track
    
    # Convert milliseconds to seconds and milliseconds
    seconds = duration_ms // 1000
    milliseconds = duration_ms % 1000
    
    # Print formatted duration
    print(f"Media file duration: \033[96m{seconds}\033[0m s \033[94m{milliseconds}\033[0m ms")  # Duration in seconds and milliseconds

# Example usage
# print_media_duration_info('/path/to/your/media/file.mp4')




def process_stage(pass_name):
    print()
    print(f"\033[92mWhisperx pass: {pass_name}\033[0m")  # Print the pass name

    # Check if the current stage has been completed
    if statuses.get(f"whisperx_{pass_name}") != "completed":
        # Dynamically call the corresponding function based on pass_name
        if pass_name == "transcription":
            language_code = whisperx_transcribe(args)  # Call transcription function
            extract_media_segments(pass_name) # Do the media chunking for that stage
            display_result_temp_html(pass_name, language_code)  # Display transcription results - optional, just to keep the users happy that they see smth interim

        elif pass_name == "alignment":
            
            # Define the path to your JSON file
            transcription_json_file_path = f"{output_dir}/{stem}_transcription.json"
            #print(f"Reading the language code from: {transcription_json_file_path}")

            # Open and load the JSON file
            with open(transcription_json_file_path, 'r', encoding='utf-8') as f:
                result = json.load(f)  # Load the contents of the JSON file into a dictionary

            # Safely get the language code from the loaded JSON data
            language_code = result.get("language")  # This retrieves the value associated with 'language'

            # Print the language code (optional)
            #print(f"Language Code from the whisperx transcription stage is: {language_code}")
            print()

            whisperx_align(args, language_code)
            #extract_media_segments(pass_name) # Do the media chunking for that stage
            #display_result_temp_html(pass_name, language_code)  # Display transcription results - optional, just to keep the users happy that they see smth interim
            if args.no_diarize:
                display_result_temp_html(pass_name, language_code)  # Display transcription results
                
        elif pass_name == "diarization":
            #If an argument is `--no_diarize`, do skip it - add it some time ... 


            # Define the path to your JSON file
            transcription_json_file_path = f"{output_dir}/{stem}_transcription.json"
            #print(f"Reading the language code from: {transcription_json_file_path}")

            # Open and load the JSON file
            with open(transcription_json_file_path, 'r', encoding='utf-8') as f:
                result = json.load(f)  # Load the contents of the JSON file into a dictionary

            # Safely get the language code from the loaded JSON data
            language_code = result.get("language")  # This retrieves the value associated with 'language'

            
            whisperx_diarize(args, language_code) # Uses alignment file, hard coded
            extract_media_segments(pass_name) # Do the media chunking for that stage
 
            display_result_temp_html(pass_name, language_code)  # Display diarization results
            
        update_tracker(tracker_file, "whisperx_" + pass_name)

    else:
        print(f"We have skipped the whisperx {pass_name} as per the Run Tracker.")




if __name__ == "__main__":

    print("Here we start ...")
    rainbow_text(tool_name_and_version)

    #rainbow_text(tool_name_and_version)
    # See also https://github.com/ddlBoJack/emotion2vec

    parser = argparse.ArgumentParser(description="Process a media file to detect emotions there")
    parser.add_argument("media_path", type=str, help="Path to the media file analyzed")
    
    parser.add_argument("--language", type=str, default="", help="Specify the language code (default: '{none}')")
    parser.add_argument("--no_align", action="store_true", help="Do not perform word alignment (default: False)")
    parser.add_argument("--no_diarize", action="store_true", help="Do not perform diarization (default: False)")
    
    # Add arguments for min and max speakers
    parser.add_argument("--min_speakers", type=int, help="Minimum number of speakers ")
    parser.add_argument("--max_speakers", type=int, help="Maximum number of speakers")

    parser.add_argument("--model", type=str, default="medium", help="Size of the recognition model: small, medium (default), large-v3 ...")

    args = parser.parse_args()
    
        
    # Get the number of CPU cores
    num_cores = os.cpu_count()  # or use multiprocessing.cpu_count()

    if num_cores is not None:
        # Calculate the number of threads to use (half the number of cores)
        faster_whisper_threads = num_cores // num_cores_divisor
    else:
        # Fallback if unable to determine the number of cores
        faster_whisper_threads = 1  # Default to 1 thread if undetermined

    print(f"Using \033[94m{faster_whisper_threads} threads\033[0m for whisperx processing. You may increase them to {num_cores}.")


        

    print(f"Current date and time: \033[94m{datetime.datetime.now()}\033[0m")

    

    # Initialize necessary variables
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
        media_path = Path(args.media_path)  # Convert to Path object

    stem = media_path.stem  # Extract stem from media path
    original_extension = media_path.suffix  # Extract original file extension
    
    # Use the min and max speakers from command line arguments
    min_speakers = args.min_speakers
    max_speakers = args.max_speakers
    whisperx_model_size = args.model
   
    '''
We also have: 
# Accessing attributes
print(media_path.name)       # 'Censored_Men_bugs.mp4'
print(media_path.stem)       # 'Censored_Men_bugs'
print(media_path.suffix)     # '.mp4'
print(media_path.parent)      # '/home/user/Videos'

.with_suffix(suffix): Returns a new Path object with a different suffix.
python
new_path = path.with_suffix('.bak')
print(new_path)  # Output: '/home/user/file.bak'

.joinpath(*other): Joins one or more path components intelligently.
python
new_path = path.parent.joinpath('new_file.txt')
print(new_path)  # Output: '/home/user/new_file.txt'


# Checking existence and type
print(media_path.exists())    # True or False depending on existence
print(media_path.is_file())    # True if it's a file

# Creating a new directory and file
new_dir = media_path.parent / 'new_folder'
new_dir.mkdir(parents=True, exist_ok=True)

new_file = new_dir / 'new_file.txt'
new_file.touch()               # Create an empty file

# Resolving to an absolute path
print(media_path.resolve())

'''

    output_dir = media_path.parent / (media_path.name + "_emotions_detected")  # Create output directory
    output_dir.mkdir(exist_ok=True)  # Create directory if it doesn't exist

    tracker_file = output_dir / "tracker.json"
    
    # Initialize tracker if it doesn't exist
    if not os.path.exists(tracker_file):
        initialize_tracker(tracker_file)

    # Read current statuses from the tracker file
    statuses = read_tracker(tracker_file)
    print(f"The Run Tracker status quo: \033[94m{statuses}\033[0m")
    print_media_duration_info(media_path)
     
        
     # Parse the media file
    media_info = MediaInfo.parse(media_path)
    
    
    print()
    print("\033[94mImporting Python libraries... This may take some time; you might see some warnings during this process; most can be safely ignored, but if later processing fails, review these too to ensure all these libraries are up to date to avoid compatibility issues.... \033[0m")  # Blue

    #These imports take time. They  are here so as to let the user measure in output how much time they take to import: 
        

    #Changed imports with MoviePy update > 2.0:
    from moviepy import VideoFileClip, AudioFileClip
        
    import webbrowser
    import plotly.graph_objects as go
    import plotly.express as px

    from playsound import playsound
            
    import srt


    import pandas as pd

    import whisperx
    from funasr import AutoModel
    #For emotions model downloading, needed once:
    import modelscope
    ''' 
    
    from moviepy.editor import VideoFileClip, AudioFileClip
    from moviepy.audio.AudioClip import CompositeAudioClip
    '''


    #print_media_duration_info(media_path)
    print()
    #from pydub import AudioSegment


    
   # Get and print the version of whisperx
    whisperx_version = importlib.metadata.version("whisperx")
    funasr_version=importlib.metadata.version("funasr")
    moviepy_version=importlib.metadata.version("moviepy")
    numpy_version=importlib.metadata.version("numpy")
    
    
    #print(f"WhisperX version: {whisperx_version}") 
    #print()
    #print()
    print(f"We are using this Whisperx version: \033[94m{whisperx_version}\033[0m")  # Blue)
    print(f"Note, if whisperx version is larger than 3.1.5 and you see errors about some 'asr arguments' missing or wrong, the easiest ugly and temporary fix is to downgrade to 3.1.5 : 'pip install whisperx==3.1.5' "  )

    print(f"We are using this Funasr version: \033[94m{funasr_version}\033[0m")  # Blue)
    print(f"We are using this MoviePy version: \033[94m{moviepy_version}\033[0m")  # Blue)
    print(f"We are using this Numpy version: \033[94m{numpy_version}\033[0m")  # Blue)

    '''
    # Command to execute to run translation 
    print("We are using this translate-shell version:\033[94m")
    command = f"trans -U"

    try:
        # Execute the command that requires Internet access
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        # Handle the error if the command fails
        print(f"\033[91m") # Red color for error message
        print(f"Error occurred while executing the translation command: {e}")
        print("Check your Internet connection and try again.")
        print(f"\033[0m") # Reset text color

    print(f"\033[0m") # Reset text color to default
    '''
    from moviepy.config import check
    check()

    # Construct output file path for the converted MP4 file
    output_file = output_dir / (media_path.name + ".mp4")
    
    #print()

    
    print()    
    print(f"Processing: \033[94m{media_path}\033[0m")  # Blue)
    
    
    mime_type, _ = mimetypes.guess_type(media_path)
    #print()
    #print_exif_info(media_path)

    if mime_type and mime_type.startswith('audio'):
        # Handle audio file processing here
        print(f"\033[94mMedia is audio.\033[0m")
    elif mime_type and mime_type.startswith('video'):
        # Handle video file processing here
        print(f"\033[96mMedia is video.\033[0m")
    else:
        raise ValueError(f"Unsupported media type: {mime_type}")
        

    print_media_duration_info(media_path)

    print()     
    
    
    
    
    
    
    
    '''
    #Potential initial stage - any media file is transcoded to an mp4 first:
    print("\033[92mStage:\nTranscoding (cleansing) by ffmpeg \033[0m")  # Green


    # Step 2: Run WhisperX transcription processing
    if statuses.get("input_file_transcoded_by_ffmpeg") != "completed":
        print("\033[94mWe are cleansing (transcoding) the source file by ffmpeg. This stage takes time, about three times faster than the play time of the source audio. \033[0m")  # Blue


        # Construct the FFmpeg command to convert any input media to MP4
        
        
        ffmpeg_command = [
            'ffmpeg',
            '-i', str(media_path),
            '-y',                          # Overwrite output files without asking
            str(output_file)              # Output file path (should have .mp4 extension)
        ]

        # Execute the FFmpeg command
        subprocess.run(ffmpeg_command)

        # Check if the output file exists
        if output_file.exists():
            print("The input file has been cleansed (transcoded) by ffmpeg.") 
        else:
            # Raise an error indicating that FFmpeg failed for some reason
            raise RuntimeError(f"FFmpeg failed to create the output file: {output_file}")
            
    else:
        # Check if the output file exists
        if output_file.exists():
             print("The input file had already been cleansed (transcoded) by ffmpeg, so we skip that step.") 
        else:
            # Raise an error indicating that FFmpeg failed for some reason
            raise RuntimeError(f"Some problem with: {output_file}. Do check it by hand.")
    
    # Update media_path to point to the new MP4 file
    media_path = output_file
     
     
    print(f"Attributes of the cleansed MP4 file:  {media_path}")
    print_exif_info(media_path)
    '''
   
  




    
      
     # Parse the media file
    media_info = MediaInfo.parse(media_path)

    	

    print(f"The Run Tracker status quo: \033[94m{statuses}\033[0m")
    print()

    print("\033[94mThe next steps will take some time. There will be three processing runs (passes):\n"
          "A. WhisperX initial Transcription: the fastest run, which shall show you the first crude level emotions analysis.\n"
          "B. WhisperX Alignment: a run which takes more time.\n"
          "C. Speaker Diarization (identifying speakers in the transcript): the run which usually takes the most time.\033[0m")  

    print("Run C (Diarization) will show you:\n"
          "1. A graph with the speakers identified and the corresponding timestamps.\n" 
          "2. And at the end of all processing - the final interactive graph of the emotions analysis, the transcripts of the chunks and their playable video thumbnails.\n"
          "During these steps, the files for the Speech To Text (Automatic Speech Recognition, ASR) and emotion detection (FunASR) models ('the electronic brains' behind it all) may be downloaded as needed.\n"
          "Please be patient as on a regular, CPU-only computer these processes may take about five times as long as the duration of the source video.\033[0m")  # Blue

    process_stage("transcription")
    process_stage("alignment")
    process_stage("diarization")

    '''    
#   If diarization got broken for some reason mid-stream, so the interim chunked media files are there but no HTML yet, do run these by hand, removing the comments:
    if statuses.get("whisperx_diarization_display") != "completed":
        display_result_temp_html('diarization', language_code)  # Display diarization results
        update_tracker(tracker_file, "whisperx_diarization_display")
                # Path to the audio file
    '''
    
    
           
    # Path to the audio file
    audio_path = "~/Music/Timer_and_sounds/Emotion Scores Visualization, for Stage Alignment.wav"

    # Play the audio
    #playsound(audio_path)
        
    


    print(f"Current date and time: \033[94m{datetime.datetime.now()}\033[0m")
    #print(f"Run Tracker status quo: \033[94m{statuses}\033[0m")
        
 

    # End measuring time
    end_time = time.time()
  
    # Calculate elapsed time
    elapsed_time = end_time - start_time
    print_media_duration_info(media_path)
        

    print(f"Total CPU processing time: \033[94m{elapsed_time:.2f} seconds\033[0m")  # Blue 
        
  

 
 
 
 
