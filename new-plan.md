Ini bukan lagi “AI musik umum”, tapi tool buat musisi ngulik lagu—mirip versi fokus dari Moises tapi dengan kontrol yang kamu tentukan sendiri.

Aku bantu susun ulang jadi MVP Voxora (Musician Practice AI Tool) yang realistis + detail teknis.

🎯 CORE VALUE VOXORA

“Upload lagu → langsung bisa dipelajari (tempo, nada, chord, stem)”

Fitur inti:

Upload lagu
Auto:
Detect chord
Detect BPM
Split stem (vocal, drum, bass, dll)
Kontrol:
Ubah tempo (tanpa ubah pitch)
Ubah pitch (semitone ±)
Volume per stem
Metronome

🧠 ARSITEKTUR FINAL
Flutter App
↓
Express API (Node.js)
↓
Python AI Service (FastAPI)
↓
MySQL + File Storage

🧠 PYTHON (OTAK UTAMA AI + AUDIO ENGINE)

Ini bagian paling penting. Kita pecah per fitur.

🎧 1. Audio Loading & Processing (CORE)

Library:

Librosa
soundfile
numpy

Fungsi:

Load audio
Convert sample rate
Basic processing

🎼 2. Time Stretch (Ubah Tempo TANPA ubah pitch)

Pakai:

Librosa (time_stretch)
Alternatif lebih bagus:
rubberband (lebih natural, kualitas tinggi)

👉 Saran:

MVP: Librosa
Upgrade: Rubberband

🎵 3. Pitch Shift (Naik/Turun Semitone)

Pakai:

Librosa (pitch_shift)

Contoh:

+2 = naik 2 semitone
-3 = turun 3 semitone

🎸 4. Chord Detection

Pakai kombinasi:

Librosa (chroma feature)
Madmom (beat tracking)

Flow:

Extract chroma
Mapping ke chord (rule-based / template)
Align dengan waktu

Output:

[
{ "time": 0, "chord": "C" },
{ "time": 2.5, "chord": "G" }
]

🥁 5. BPM Detection

Pakai:

Librosa
Madmom (lebih akurat)

🎤 6. Stem Separation (WAJIB ADA)

Pakai:

Spleeter
atau (lebih bagus):
Demucs

Output:

vocal.wav
drums.wav
bass.wav
other.wav

🔊 7. Volume Control per Stem

Pakai:

pydub
atau numpy scaling

⏱️ 8. Metronome (Backend vs Frontend)

👉 Saran:

Generate di Flutter (frontend) → lebih ringan

Backend hanya kirim:

BPM

⚙️ PYTHON API (FastAPI)

Endpoint:

POST /analyze
POST /separate
POST /process (tempo + pitch)
GET /result/{id}

🔁 FLOW UTAMA (END-TO-END)

🎯 Upload Lagu
Flutter → upload
Express simpan file
Kirim ke Python /analyze

🧠 Python /analyze

Sekali jalan:

Detect BPM
Detect chord
Generate preview JSON

Return:

{
"bpm": 120,
"chords": [...],
"duration": 180
}
🎧 Split Stem

User klik “split”
→ Python /separate

🎛️ Adjust Tempo & Pitch

User atur slider:
→ Python /process

Input:

{
"tempo": 0.8,
"pitch": -2
}

🧱 EXPRESS BACKEND

Pakai:

express
multer
axios
mysql2
bull (queue optional)
Endpoint:
POST /upload
POST /analyze
POST /separate
POST /process
GET /song/:id

🗄️ DATABASE (MySQL)
songs
id
user_id
title
file_path
bpm
duration
created_at
chords
id
song_id
time
chord
stems
id
song_id
type (vocal/drum/bass)
file_path
jobs
id
song_id
type
status

📱 FLUTTER APP (UI FLOW)

1. Home
   List lagu
2. Upload Page
   Pick file
   Upload
3. Player Page (CORE 🔥)

Fitur:

Play / Pause
Slider tempo
Slider pitch
Volume:
Vocal
Drum
Bass
Chord display (auto scroll)
Metronome ON/OFF

🎛️ AUDIO ENGINE DI FLUTTER

Gunakan:

just_audio
audio_service

Untuk:

Multi track playback (stem)

🔥 MVP SCOPE (JANGAN KELEWATAN)
WAJIB ADA:

✅ Upload lagu
✅ BPM detect
✅ Chord detect
✅ Tempo adjust
✅ Pitch shift

OPTIONAL (phase 2):
Stem separation
Volume per instrument

⚠️ HAL PENTING (BIAR NGGAK FAIL)
Jangan real-time processing
→ semua jadi job async
Jangan langsung semua fitur
→ chord + tempo dulu
Audio itu berat
→ compress + limit durasi
💡 FITUR PEMBEDA VOXORA

Kalau mau beda dari Moises:

Auto scroll chord sinkron lagu
“Simplify chord” (AI bantu pemula)
Loop bagian tertentu (practice mode)
Save preset latihan

🚀 STEP PALING MASUK AKAL UNTUK KAMU
Buat Python:
Load audio
Detect BPM + chord
Connect ke Express
Tampilkan di Flutter:
BPM
Chord timeline

👉 Baru tambah fitur lain
