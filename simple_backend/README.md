# Simple Backend - Quick Setup

> **✨ New:** Backend has been refactored into modular route files for better maintainability! See [REFACTORING_DOCS.md](REFACTORING_DOCS.md) for details.

## 🚀 One Command Start

```bash
cd simple_backend
docker-compose up -d
```

**Backend running at:** http://localhost:8000  
**API Docs:** http://localhost:8000/docs

---

## 📁 Files Stored Locally

- **Patients:** `./data/patients.json`
- **Notes:** `./data/notes.json`
- **Uploads:** `./data/uploads/`

---

## 🔧 Configuration

Edit `.env` file:
```bash
GEMINI_API_KEY=your_key_here
```

---

## 📡 API Routes

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | API info & stats |
| POST | `/patients` | Register patient |
| GET | `/patients` | List all patients |
| GET | `/patients/{id}` | Get patient details |
| POST | `/upload/audio/{id}` | Upload audio → SOAP note |
| POST | `/upload/image/{id}` | Upload prescription image |
| GET | `/notes/{id}` | Get patient notes |

---

## 🧪 Test Commands

```bash
# Register patient
curl -X POST http://localhost:8000/patients \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Patient","phone":"9876543210"}'

# List patients
curl http://localhost:8000/patients

# Upload audio
curl -X POST http://localhost:8000/upload/audio/PAT_XXXXX \
  -F "file=@audio.mp3"

# Get notes
curl http://localhost:8000/notes/PAT_XXXXX
```

---

## 📊 View Logs

```bash
docker-compose logs -f
```

---

## 🛑 Stop

```bash
docker-compose down
```

---

## 🔄 Restart After Changes

```bash
docker-compose restart
```

No rebuild needed - code is mounted!

---

## 📚 Project Structure

The backend is now organized into modular files:

```
simple_backend/
├── main.py              # App initialization (68 lines)
├── models.py            # Data models
├── config.py            # Configuration
├── routes/              # Modular route handlers
│   ├── health.py       # Health check endpoints
│   ├── patients.py     # Patient management (3 endpoints)
│   ├── queue.py        # Queue management (4 endpoints)
│   └── uploads.py      # Upload & AI processing (3 endpoints)
└── utils/              # Utility functions
    ├── storage.py      # JSON storage helpers
    └── ai_services.py  # AI integrations (Groq Whisper, Gemini Vision)
```

**Benefits:**
- 90% reduction in main.py complexity (569 → 68 lines)
- Clear separation of concerns
- Easier to test and maintain
- Simple to add new features

See [REFACTORING_DOCS.md](REFACTORING_DOCS.md) for complete details.
