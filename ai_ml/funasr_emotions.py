from funasr import AutoModel
import os

# Get the home directory path
home = os.path.expanduser("~")

# Construct the full path to the audio file
audio_file = os.path.join(home, "Downloads", "jebra_faushay_video.mp4")

# Load the emotion recognition model
model = AutoModel(model="iic/emotion2vec_plus_large")

# Generate the emotion recognition result
res = model.generate(audio_file, output_dir="./outputs", granularity="utterance", extract_embedding=False)

# Print the result
print(res)