🧠 GAMBARAN BESAR ARSITEKTUR

Stack:

Frontend: Flutter
Backend API Gateway: Express (Node.js)
AI Engine: Python service (microservice)
Database: MySQL
Storage: (opsional) Cloud / local file

Flow utama:

User upload audio dari Flutter
Kirim ke Express API
Express simpan metadata → MySQL
Express kirim file ke Python service
Python proses AI
Python kirim hasil ke Express
Express simpan hasil → MySQL / storage
Flutter fetch hasil
🔧 ARSITEKTUR DETAIL

1. Flutter (Client)

Fitur:

Upload audio
Pilih fitur:
Pisah suara
Detect chord
Generate beat
Voice convert
Progress loading
Result page (audio + chord + dll)

2. Express (API Gateway)

Gunakan:

express
multer (upload file)
axios (call Python API)
mysql2
uuid

Endpoint utama:

POST /upload
POST /process/separate
POST /process/chord
POST /process/beat
POST /process/voice
GET /result/:id 3. Python AI Service (CORE 🔥)

Gunakan:

FastAPI (biar cepat & async)
uvicorn
🧠 LIBRARY PYTHON UNTUK AI MUSIK (INI PENTING)

🎧 1. Pemisah Suara (Feature #1)

Pakai:

Spleeter
Alternatif lebih bagus:
Demucs (facebookresearch/demucs)

Install:

pip install spleeter

Output:

vocal.wav
drums.wav
bass.wav

🎸 2. Chord & Tempo Detection (Feature #2)

Pakai:

Librosa
Essentia

Fungsi:

BPM detection
Chroma features → chord

Tambahan:

madmom (lebih akurat tempo)

🎤 3. Voice Conversion (Feature #3)

Pakai:

RVC

Butuh:

Model pretrained voice

Catatan:

Berat (GPU disarankan)

🎼 4. Beat / Music Generator (Feature #4)

Pakai:

MusicGen

Install:

pip install audiocraft

Bisa generate:

dari teks (prompt)
dari style

🎹 5. Practice Tools (Feature #5)

Pakai:

pydub (audio manipulation)
soundstretch / librosa

Fungsi:

Slow tempo tanpa ubah pitch
Loop section
🔁 FLOW TIAP FITUR

🎧 A. Pisah Suara

Upload audio
Express → Python /separate
Python:
Load file
Run Spleeter
Save hasil
Return URL file

🎸 B. Chord Detection

Upload audio
Python:
Load pakai librosa
Extract chroma
Mapping chord
Hitung BPM
Return:
{
bpm: 120,
chords: [
{time: 0, chord: "C"},
{time: 2, chord: "G"}
]
}

🎤 C. Voice Conversion

Upload suara
Python:
Load model RVC
Convert voice
Return audio baru

🎼 D. Generate Musik
User pilih mood
Python:
Call MusicGen
Return audio

🎹 E. Practice Mode

Frontend saja bisa handle sebagian:

Loop
Speed control

🗄️ DATABASE (MySQL)
Table: users
id
email
password
Table: audio_jobs
id
user_id
file_path
type (separate/chord/etc)
status (pending/done)
created_at
Table: results
id
job_id
result_json
file_url
⚡ JOB SYSTEM (PENTING BANGET)

Jangan proses langsung → nanti server mati.

Gunakan:

Queue (opsional awal: simple polling)
Atau Redis + Bull (di Express)

Flow:

Job masuk → status pending
Python worker proses
Update status done

📦 STRUKTUR PROJECT
Express
/api
/controllers
/routes
/services/pythonService.js

Python
/app
main.py
services/
separate.py
chord.py
voice.py
beat.py
