# PHC AI Co-Pilot - Doctor Dashboard (React)

## Overview
Web dashboard for doctors to view patient data and live-updating medical notes.

## Features
- Patient list view
- Real-time SOAP notes (AI Scribe output)
- RAG-generated patient history timeline
- Live typewriter effect via AWS IoT Core (MQTT)

## Tech Stack
- React 18
- AWS Amplify (for IoT Core connection)
- Tailwind CSS (for styling)

## Setup

```bash
# Install dependencies
npm install

# Start development server
npm start
```

## Environment Variables
Create a `.env` file:
```
REACT_APP_API_ENDPOINT=https://your-api-gateway-url.com/Prod
REACT_APP_IOT_ENDPOINT=wss://your-iot-endpoint.iot.ap-south-1.amazonaws.com
```

## Deployment
```bash
npm run build
# Deploy to S3 + CloudFront or Vercel
```

## Priority for Hackathon
⚠️ **LOW PRIORITY** - Focus on backend and mobile first!
