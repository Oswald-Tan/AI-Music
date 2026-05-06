import os
import subprocess
import shutil
import re
from utils.notifier import report_progress

def process_separate(file_path: str, job_id: str = None, start_progress: int = 0, end_progress: int = 100):
    """
    Separates audio into 4 stems using Demucs AI.
    Saves results directly into the backend's uploads folder for stability.
    """
    base_name = os.path.basename(file_path)
    name_without_ext = os.path.splitext(base_name)[0]
    
    # Path to backend/uploads folder (relative to machine_py)
    backend_uploads_root = os.path.join("..", "backend", "uploads", "separated")
    os.makedirs(backend_uploads_root, exist_ok=True)
    
    try:
        # Run Demucs and track progress with MP3 output
        print(f"Starting Demucs separation (MP3) for: {file_path}")
        
        if job_id:
            report_progress(job_id, start_progress, "Stem Separation")

        # We use Popen to read real-time output
        process = subprocess.Popen([
            "demucs", 
            "-n", "htdemucs", 
            "--mp3",
            "--mp3-bitrate", "320",
            "--out", backend_uploads_root, 
            file_path
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True)

        for line in process.stdout:
            print(line, end="")
            # Parse percentage e.g. " 10%|"
            match = re.search(r"(\d+)%\|", line)
            if match and job_id:
                raw_progress = int(match.group(1))
                # Map progress to range
                mapped_progress = start_progress + (raw_progress * (end_progress - start_progress) / 100)
                report_progress(job_id, mapped_progress, "Stem Separation")

        process.wait()
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, "demucs")
        
        # Demucs structure: backend/uploads/separated/htdemucs/<filename>/vocals.mp3
        demucs_out_dir = os.path.join(backend_uploads_root, "htdemucs", name_without_ext)
        
        stems = ["vocals", "drums", "bass", "other"]
        result_paths = {}
        
        for stem in stems:
            stem_filename = f"{stem}.mp3"
            src_path = os.path.join(demucs_out_dir, stem_filename)
            
            if os.path.exists(src_path):
                # Return relative path for the backend (it serves /uploads)
                result_paths[stem] = f"/uploads/separated/htdemucs/{name_without_ext}/{stem_filename}"
            else:
                print(f"Warning: Stem {stem} not found at {src_path}")
        
        return {
            "status": "success",
            "resultJson": result_paths
        }
        
    except Exception as e:
        print(f"Demucs Error: {e}")
        # FALLBACK: If AI fails, use original file as stems so the app doesn't break
        print("Falling back to original file for stems...")
        stems = ["vocals", "drums", "bass", "other"]
        result_paths = {}
        for stem in stems:
            result_paths[stem] = f"http://10.150.164.53:8087/{file_path.split('backend/')[1]}"
            
        return {
            "status": "success",
            "resultJson": result_paths,
            "warning": f"AI Separation failed, using original audio. Error: {str(e)}"
        }
