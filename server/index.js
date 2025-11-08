const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'PHC AI Co-Pilot Server is running',
    timestamp: new Date().toISOString()
  });
});

// Placeholder routes (will be replaced by Lambda functions)
app.post('/api/patients', (req, res) => {
  res.json({ 
    message: 'Patient registration endpoint',
    note: 'This will be handled by AWS Lambda in production'
  });
});

app.get('/api/patients/:id', (req, res) => {
  res.json({ 
    message: 'Get patient endpoint',
    patient_id: req.params.id,
    note: 'This will be handled by AWS Lambda in production'
  });
});

app.post('/api/upload-url', (req, res) => {
  res.json({ 
    message: 'Presigned URL generation endpoint',
    note: 'This will generate S3 presigned URLs via Lambda'
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/health`);
});
