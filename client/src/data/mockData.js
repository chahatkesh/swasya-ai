// Mock data for the Doctor's Dashboard

export const mockPatients = [
  {
    id: "pat_001",
    displayId: "123",
    name: "R. Kumar",
    mobile: "+91 9876543210",
    age: 58,
    gender: "M",
    uhid: "UHID001",
    status: "ready", // waiting, with-nurse, ready, completed
    queueNumber: 1,
    checkInTime: "09:15 AM",
    lastUpdated: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
  },
  {
    id: "pat_002", 
    displayId: "124",
    name: "S. Devi",
    mobile: "+91 9876543211",
    age: 42,
    gender: "F",
    uhid: "UHID002",
    status: "with-nurse",
    queueNumber: 2,
    checkInTime: "09:30 AM",
    lastUpdated: new Date(Date.now() - 2 * 60 * 1000), // 2 minutes ago
    nurseAssigned: "Nurse Rekha"
  },
  {
    id: "pat_003",
    displayId: "125", 
    name: "A. Singh",
    mobile: "+91 9876543212",
    age: 65,
    gender: "M",
    uhid: "UHID003",
    status: "waiting",
    queueNumber: 3,
    checkInTime: "09:45 AM",
    lastUpdated: new Date(Date.now() - 1 * 60 * 1000), // 1 minute ago
  },
  {
    id: "pat_004",
    displayId: "126",
    name: "M. Sharma",
    mobile: "+91 9876543213", 
    age: 35,
    gender: "F",
    uhid: "UHID004",
    status: "completed",
    queueNumber: 4,
    checkInTime: "08:45 AM",
    lastUpdated: new Date(Date.now() - 45 * 60 * 1000), // 45 minutes ago
    completedTime: "09:15 AM"
  }
];

export const mockEncounterData = {
  patientId: "pat_001",
  scribeData: {
    rawTranscript: "बुखार और खाँसी... तीन दिन से... सिर दर्द भी है... रात में नींद नहीं आती...",
    englishTranscript: "Fever and cough... for three days... also having headache... unable to sleep at night...",
    soapNote: {
      subjective: "Patient reports 3-day history of fever and cough with associated headache and insomnia.",
      objective: "Temperature: 101.2°F, BP: 140/90 mmHg, Pulse: 88 bpm, visible signs of fatigue",
      assessment: "Likely viral upper respiratory tract infection with secondary sleep disturbance",
      plan: "Symptomatic treatment with paracetamol, adequate rest, follow-up in 3 days if symptoms persist"
    },
    isProcessing: false,
    confidence: 0.92
  },
  digitizedData: {
    scannedImageUrl: "/mock-prescription.jpg", // Mock image path
    extractedData: {
      medications: [
        {
          name: "Amlodipine",
          dosage: "5mg",
          frequency: "Once daily",
          duration: "30 days"
        },
        {
          name: "Aspirin", // This will trigger drug interaction alert
          dosage: "75mg", 
          frequency: "Once daily",
          duration: "30 days"
        }
      ],
      date: "Jan 2025",
      doctorName: "Dr. Verma",
      clinic: "City Hospital"
    },
    isProcessing: false,
    confidence: 0.88
  }
};

export const mockPatientHistory = {
  patientId: "pat_001",
  personalInfo: {
    name: "R. Kumar",
    age: 58,
    gender: "Male",
    bloodType: "B+",
    contact: "+91 9876543210",
    uhid: "UHID001"
  },
  allergies: [
    {
      allergen: "Penicillin",
      severity: "High",
      reaction: "Skin rash, breathing difficulty"
    }
  ],
  currentMedications: [
    {
      name: "Warfarin", // This will trigger drug interaction alert
      dosage: "5mg",
      frequency: "Once daily",
      startDate: "Dec 2024",
      indication: "Atrial fibrillation"
    },
    {
      name: "Metformin",
      dosage: "500mg", 
      frequency: "Twice daily",
      startDate: "Nov 2024",
      indication: "Type 2 Diabetes"
    }
  ],
  visitHistory: [
    {
      date: "Dec 15, 2024",
      diagnosis: "Routine diabetes follow-up",
      doctor: "Dr. Patel",
      notes: "HbA1c: 7.2%, Blood pressure controlled"
    },
    {
      date: "Nov 20, 2024", 
      diagnosis: "Atrial fibrillation - new diagnosis",
      doctor: "Dr. Sharma",
      notes: "Started on Warfarin, patient counseled"
    },
    {
      date: "Oct 10, 2024",
      diagnosis: "Hypertension follow-up", 
      doctor: "Dr. Patel",
      notes: "BP: 145/92, medication adjusted"
    },
    {
      date: "Sep 5, 2024",
      diagnosis: "Type 2 Diabetes - initial diagnosis",
      doctor: "Dr. Patel", 
      notes: "HbA1c: 8.1%, started on Metformin"
    }
  ],
  vitals: {
    lastRecorded: "Dec 15, 2024",
    height: "170 cm",
    weight: "75 kg",
    bmi: "26.0",
    bloodPressure: "135/85 mmHg",
    heartRate: "72 bpm",
    temperature: "98.6°F"
  }
};

// AI Analysis Results
export const mockAIAnalysis = {
  drugInteractions: [
    {
      severity: "critical",
      interaction: {
        drug1: "Warfarin",
        drug2: "Aspirin", 
        riskLevel: "High",
        description: "Concurrent use increases bleeding risk significantly",
        recommendation: "Avoid combination or monitor INR closely if essential"
      }
    }
  ],
  symptomAlerts: [
    {
      severity: "high",
      alert: {
        symptom: "Headache",
        relatedMedication: "Warfarin",
        riskDescription: "Headache in patient on Warfarin may indicate intracranial bleeding",
        recommendation: "Investigate for potential internal bleeding, consider CT scan"
      }
    }
  ],
  riskFactors: [
    {
      factor: "Age 58+ with multiple cardiovascular medications",
      riskLevel: "Medium",
      recommendation: "Regular cardiovascular monitoring"
    }
  ]
};

export const mockNurseData = [
  {
    id: "nurse_001",
    name: "Nurse Rekha",
    status: "active",
    currentPatient: "pat_002",
    location: "Room 2"
  },
  {
    id: "nurse_002", 
    name: "Nurse Priya",
    status: "available",
    currentPatient: null,
    location: "Station 1"
  }
];