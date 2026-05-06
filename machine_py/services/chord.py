import librosa
import numpy as np
import os
from utils.notifier import report_progress

def process_chord(file_path: str, job_id: str = None):
    """
    Advanced Chord Detection with high precision timing.
    Uses onset-strength aligned beat tracking for better synchronization.
    """
    if not os.path.exists(file_path):
        return {"status": "error", "message": "File not found"}

    if job_id:
        report_progress(job_id, 2, "Chord Analysis")

    # 1. Load audio with high quality
    print(f"Loading audio for chord detection: {file_path}")
    y, sr = librosa.load(file_path, sr=22050) # Standard SR for analysis
    if job_id:
        report_progress(job_id, 5, "Chord Analysis")

    # 2. HPSS to isolate harmony and percussion
    # Harmonic for pitch, Percussive for beat timing
    y_harmonic, y_percussive = librosa.effects.hpss(y)

    # 3. Enhanced Beat Tracking
    # Using onset strength to make beats more precise
    onset_env = librosa.onset.onset_strength(y=y_percussive, sr=sr)
    tempo, beat_frames = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
    
    if isinstance(tempo, np.ndarray):
        bpm = int(np.round(tempo[0]))
    else:
        bpm = int(np.round(tempo))

    if job_id:
        report_progress(job_id, 10, "Chord Analysis")

    # 4. High-Resolution Chroma (CQT)
    # Using hop_length=512 for better time resolution
    hop_length = 512
    chroma = librosa.feature.chroma_cqt(y=y_harmonic, sr=sr, hop_length=hop_length)
    
    # Normalize chroma to make it robust to volume changes
    chroma = librosa.util.normalize(chroma, axis=0)

    # Calculate energy for each frame
    rms = librosa.feature.rms(y=y_harmonic, hop_length=hop_length)[0]

    # 5. Beat-Synchronous Analysis
    # Sync chroma to detected beats for "locked" timing
    beat_chroma = librosa.util.sync(chroma, beat_frames, aggregate=np.median)
    beat_rms = librosa.util.sync(rms, beat_frames, aggregate=np.median)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=hop_length)
    
    # Chord templates (Major and Minor)
    chord_names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
                   'Cm', 'C#m', 'Dm', 'D#m', 'Em', 'Fm', 'F#m', 'Gm', 'G#m', 'Am', 'A#m', 'Bm']
    
    templates = []
    for i in range(12): # Major
        t = np.zeros(12); t[i] = 1.0; t[(i + 4) % 12] = 0.7; t[(i + 7) % 12] = 0.5
        templates.append(t)
    for i in range(12): # Minor
        t = np.zeros(12); t[i] = 1.0; t[(i + 3) % 12] = 0.7; t[(i + 7) % 12] = 0.5
        templates.append(t)
    templates = np.array(templates)

    # 6. Chord Recognition
    chord_scores = np.dot(templates, beat_chroma)
    raw_chords_idx = np.argmax(chord_scores, axis=0)
    
    # Identify the first onset to align timing (offsets silence)
    onsets = librosa.onset.onset_detect(y=y, sr=sr, hop_length=hop_length, units='time')
    first_onset = onsets[0] if len(onsets) > 0 else 0
    
    # Smart Offset: Alignment to first major sound event
    # If first beat is way before first onset, we might need an offset
    TIME_OFFSET = -0.05 # Small constant for internal latency compensation
    
    smooth_chords_idx = []
    for i in range(len(raw_chords_idx)):
        # Silence/Solo Drum detection
        h_energy = beat_rms[i]
        peak_chroma = np.max(beat_chroma[:, i])

        if h_energy < 0.005 or peak_chroma < 0.35:
            smooth_chords_idx.append(-1)
            continue
            
        # Median filtering for stability
        start = max(0, i - 1)
        end = min(len(raw_chords_idx), i + 2)
        window = raw_chords_idx[start:end]
        counts = np.bincount(window)
        smooth_chords_idx.append(np.argmax(counts))
    
    # 7. Group into Bars (4/4 time)
    bars = []
    current_bar = []
    num_beats = len(beat_times)
    
    for i in range(num_beats):
        idx = smooth_chords_idx[i]
        chord = chord_names[idx] if idx != -1 else ""
        
        # Apply smart timing
        time = float(max(0, np.round(beat_times[i] + TIME_OFFSET, 3)))
        
        current_bar.append({
            "chord": chord,
            "time": time
        })
        
        if len(current_bar) == 4:
            bars.append(current_bar)
            current_bar = []
            
    if current_bar:
        # Pad last bar if incomplete
        while len(current_bar) < 4:
            current_bar.append({"chord": "", "time": 0})
        bars.append(current_bar)

    # Determine Global Key
    from collections import Counter
    valid_chords = [chord_names[idx] for idx in smooth_chords_idx if idx != -1]
    most_common = Counter(valid_chords).most_common(1)[0][0] if valid_chords else "N/A"

    return {
        "status": "success",
        "resultJson": {
            "bpm": bpm,
            "key": most_common,
            "bars": bars 
        }
    }
