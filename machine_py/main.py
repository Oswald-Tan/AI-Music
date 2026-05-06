import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from routers import process_router

app = FastAPI(title="Voxora AI Service")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure output directory exists
OUTPUT_DIR = "outputs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Mount static files for output audio
app.mount("/outputs", StaticFiles(directory=OUTPUT_DIR), name="outputs")

# Include routers
app.include_router(process_router.router)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Voxora AI Engine is running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
