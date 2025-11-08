# Simple Backend - Quick Setup

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
