import os
import shutil
import uuid

def process_voice(file_path: str, model_id: str):
    """
    Converts voice using an RVC model.
    Stub implementation.
    """
    base_name = os.path.basename(file_path)
    output_name = f"voice_converted_{uuid.uuid4().hex[:8]}.wav"
    output_path = os.path.join("outputs", output_name)
    
    # Stub: just copy the file
    shutil.copy(file_path, output_path)
    
    return {
        "status": "success",
        "fileUrls": [
            f"http://localhost:8000/outputs/{output_name}"
        ],
        "resultJson": {
            "model_used": model_id,
            "output_url": f"http://localhost:8000/outputs/{output_name}"
        }
    }
