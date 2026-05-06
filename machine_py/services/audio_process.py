import librosa
import soundfile as sf
import os
import numpy as np

def process_audio(file_path: str, tempo: float = 1.0, pitch: float = 0.0):
    """
    Processes audio with tempo and pitch adjustment.
    tempo: factor to stretch (e.g. 0.8 = 80% speed)
    pitch: semitones to shift (e.g. -2.0 = down 2 semitones)
    """
    if not os.path.exists(file_path):
        return {"status": "error", "message": "File not found"}

    try:
        # 1. Load audio
        y, sr = librosa.load(file_path, sr=None)

        # 2. Apply Pitch Shift (first, as it might be easier on the buffer)
        if pitch != 0.0:
            y = librosa.effects.pitch_shift(y, sr=sr, n_steps=pitch)

        # 3. Apply Time Stretch
        if tempo != 1.0:
            y = librosa.effects.time_stretch(y, rate=tempo)

        # 4. Save to output
        base_name = os.path.basename(file_path)
        name_without_ext = os.path.splitext(base_name)[0]
        output_filename = f"{name_without_ext}_t{tempo}_p{pitch}.wav"
        output_dir = os.path.join("outputs", "processed")
        os.makedirs(output_dir, exist_ok=True)
        
        output_path = os.path.join(output_dir, output_filename)
        sf.write(output_path, y, sr)

        # Return the path relative to the static mount
        return {
            "status": "success",
            "filePath": output_path,
            "url": f"/outputs/processed/{output_filename}"
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}
