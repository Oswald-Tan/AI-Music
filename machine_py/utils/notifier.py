import requests

NODE_BACKEND_URL = "http://localhost:8087/api/jobs/progress"

def report_progress(job_id, progress, status_message=None):
    """
    Reports processing progress to the Node.js backend.
    """
    if not job_id:
        return
        
    try:
        payload = {
            "jobId": job_id,
            "progress": int(progress)
        }
        if status_message:
            payload["statusMessage"] = status_message
            
        requests.post(NODE_BACKEND_URL, json=payload, timeout=5)
    except Exception as e:
        print(f"Failed to report progress for job {job_id}: {e}")
