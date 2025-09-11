from funasr import AutoModel

#from modelscope.utils.constant import Tasks
#from funasr.utils.postprocess_utils import rich_transcription_postprocess

import os

# Get the home directory path
home = os.path.expanduser("~")

# Construct the full path to the audio file
#audio_file = os.path.join(home, "Downloads", "Police_2.mp4")

audio_file = os.path.join(home, "Downloads", "Police_2.mp4.wav")

# Load the emotion recognition model
#model = AutoModel(model="iic/emotion2vec_plus_large",  vad_model="fsmn-vad")

#model = AutoModel(model="iic/SenseVoiceSmall", vad_model="Whisper-large-v3-turbo")


#model = AutoModel(model="iic/SenseVoiceSmall", vad_model="fsmn-vad")


model = AutoModel(

    #You can have: 
    #A. 
    #English emotions., no scores: ANGRY/NEUTRAL, SPEECH
    #model="iic/SenseVoiceSmall",
    #vad_model="fsmn-vad",  # VAD model

    #B. 
    #Chinese/English emotions, scores and feats, angry/disgusted/fearful/happy/neutral/other/sad/surprised/unknown
    model="iic/emotion2vec_plus_large",  # Emotion recognition model
    #No VAD (sic!), as see  https://github.com/Manamama/Ubuntu_Scripts_1/blob/main/docs/FunASR_analysis_and_bugs.md, in short: FunASR's unified AutoModel pipeline is ASR-centric, assuming models output a 'text' key for segmentation and aggregation—hence the crashes when forcing VAD onto emotion2vec_plus_large. 
    #VAD causes: 'ValueError: operands could not be broadcast together with shapes (187,1024) (301,1024) (187,1024)' with  "iic/emotion2vec_plus_large" 
    #punc_model="ct-punc",
    vad_kwargs={"max_single_segment_time": 30000, "min_silence_duration": 500},  # VAD parameters
    #device="cuda:0" ,  # Use GPU if available
    #trust_remote_code=True,  # Required for ModelScope models
)


#model = AutoModel(model="iic/SenseVoiceSmall", vad_model="fsmn-vad")



# Generate the emotion recognition result
#res = model.generate(audio_file, output_dir="./outputs",  extract_embedding=True, language="en", use_it=True, ban_emo_unk=True)

#res = model.generate(audio_file, output_dir="./outputs", granularity="sentence", extract_embedding=True, language="en", ban_emo_unk=True)

#merge_vad=True errors, Disable VAD merging to avoid shape mismatch
res = model.generate(audio_file, output_dir="./outputs", granularity="sentence",  language="en", ban_emo_unk=True, use_itn=True, merge_vad=False)
#res = model.generate(audio_file, output_dir="./outputs", granularity="sentence", language="en", ban_emo_unk=True)

# Print the result
print(res)
