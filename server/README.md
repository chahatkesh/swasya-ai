# PHC AI Co-Pilot - Server (Express/Lambda)

## Overview
Backend server for local development. In production, this will be replaced by AWS Lambda functions.

## Purpose
- **Local Development:** Test API endpoints before deploying to Lambda
- **Quick Prototyping:** Rapid iteration during hackathon
- **Lambda Functions:** The `lambdas/` folder contains actual production code

## Structure
```
server/
├── index.js              # Express server for local testing
├── lambdas/              # AWS Lambda functions (production)
│   ├── patient_registration/
│   ├── scribe_task/
│   ├── digitize_task/
│   └── rag_task/
├── template.yaml         # SAM template (infrastructure as code)
└── package.json
```

## Setup

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
# Edit .env with your AWS credentials

# Start local server
npm start
```

## Test Endpoints

```bash
# Health check
curl http://localhost:3001/health

# Register patient
curl -X POST http://localhost:3001/api/patients \
  -H "Content-Type: application/json" \
  -d '{"name": "Ram Kumar", "phone": "9876543210"}'
```

## Deploy Lambda Functions

```bash
# Build and deploy to AWS
sam build
sam deploy --guided
```

## Note
⚠️ The Express server is ONLY for local testing. Production uses serverless Lambda functions!
