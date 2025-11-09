#!/bin/bash

echo "🚀 Starting PHC Backend (FastAPI)"
echo ""

# Build and run
docker-compose up --build -d

echo ""
echo "✅ Backend running at: http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
