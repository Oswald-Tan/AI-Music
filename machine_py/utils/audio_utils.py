import librosa
import soundfile as sf
import os

MAX_DURATION_SECONDS = 300 # 5 minutes

def ensure_max_duration(file_path: str):
    """
    Checks the duration of the audio file.
    If it exceeds MAX_DURATION_SECONDS, it trims the file.
    """
    if not os.path.exists(file_path):
        return file_path

    try:
        # Get duration without loading full audio
        duration = librosa.get_duration(path=file_path)
        
        if duration > MAX_DURATION_SECONDS:
            print(f"Trimming file {file_path} from {duration:.2f}s to {MAX_DURATION_SECONDS}s")
            
            # Load only the first 5 minutes
            y, sr = librosa.load(file_path, sr=None, duration=MAX_DURATION_SECONDS)
            
            # Overwrite the original file with trimmed version
            # We use the same extension as original
            sf.write(file_path, y, sr)
            print(f"File trimmed successfully: {file_path}")
            
    except Exception as e:
        print(f"Error while trimming audio: {e}")
    
    return file_path
