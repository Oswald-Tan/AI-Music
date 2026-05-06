from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

# Import services
from services import separate, chord, voice, beat, audio_process
from utils.audio_utils import ensure_max_duration

router = APIRouter()

class SeparateRequest(BaseModel):
    filePath: str
    jobId: str = None

class ChordRequest(BaseModel):
    filePath: str
    jobId: str = None

class AnalyzeRequest(BaseModel):
    filePath: str
    jobId: str = None

class ProcessRequest(BaseModel):
    filePath: str
    tempo: float = 1.0
    pitch: float = 0.0

class VoiceRequest(BaseModel):
    filePath: str
    modelId: str

class BeatRequest(BaseModel):
    prompt: str

@router.post("/analyze")
async def analyze_audio(req: AnalyzeRequest):
    if not os.path.exists(req.filePath):
        raise HTTPException(status_code=400, detail="File not found")
    
    try:
        # 0. Enforce 5 minute limit (Trim if needed)
        ensure_max_duration(req.filePath)

        # 1. Analyze chord and BPM
        chord_result = chord.process_chord(req.filePath, req.jobId)
        
        # 2. Separate audio into stems (Starts from 10% after chord analysis)
        separate_result = separate.process_separate(req.filePath, req.jobId, start_progress=10, end_progress=100)
        
        # 3. Merge results
        if "resultJson" not in chord_result:
            chord_result["resultJson"] = {}
            
        chord_result["resultJson"]["stems"] = separate_result.get("resultJson", {})
        
        return chord_result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/process")
async def process_audio_endpoint(req: ProcessRequest):
    if not os.path.exists(req.filePath):
        raise HTTPException(status_code=400, detail="File not found")
    
    try:
        result = audio_process.process_audio(req.filePath, req.tempo, req.pitch)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/separate")
async def separate_audio(req: SeparateRequest):
    if not os.path.exists(req.filePath):
        raise HTTPException(status_code=400, detail="File not found")
    
    try:
        result = separate.process_separate(req.filePath, req.jobId)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chord")
async def detect_chord(req: ChordRequest):
    if not os.path.exists(req.filePath):
        raise HTTPException(status_code=400, detail="File not found")
    
    try:
        result = chord.process_chord(req.filePath, req.jobId)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/voice")
async def convert_voice(req: VoiceRequest):
    if not os.path.exists(req.filePath):
        raise HTTPException(status_code=400, detail="File not found")
    
    try:
        result = voice.process_voice(req.filePath, req.modelId)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/beat")
async def generate_beat(req: BeatRequest):
    try:
        result = beat.process_beat(req.prompt)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
