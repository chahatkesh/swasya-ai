// API utility functions for the Doctor Dashboard
const BASE_URL = 'http://192.168.0.7:8000';

// Helper function to handle API responses
const handleResponse = async (response) => {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Network error' }));
    throw new Error(error.detail || `HTTP error! status: ${response.status}`);
  }
  return response.json();
};

// Patient Management APIs
export const patientsAPI = {
  // Get all patients
  getAll: async () => {
    const response = await fetch(`${BASE_URL}/patients`);
    return handleResponse(response);
  },

  // Get patient details
  getDetails: async (patientId) => {
    const response = await fetch(`${BASE_URL}/patients/${patientId}`);
    return handleResponse(response);
  },

  // Get complete patient record
  getComplete: async (patientId) => {
    const response = await fetch(`${BASE_URL}/patients/${patientId}/complete`);
    return handleResponse(response);
  },

  // Get patient summary (recommended for quick view)
  getSummary: async (patientId) => {
    const response = await fetch(`${BASE_URL}/summary/${patientId}`);
    return handleResponse(response);
  },

  // Get patient timeline (RECOMMENDED FOR DOCTOR DASHBOARD)
  getTimeline: async (patientId) => {
    const response = await fetch(`${BASE_URL}/timeline/${patientId}`);
    return handleResponse(response);
  },

  // Get patient medical timeline (NEW DOCUMENTED API)
  getMedicalTimeline: async (patientId) => {
    const response = await fetch(`${BASE_URL}/documents/${patientId}/timeline`);
    return handleResponse(response);
  },

  // Generate medical timeline
  generateTimeline: async (patientId, batchId) => {
    const response = await fetch(`${BASE_URL}/documents/${patientId}/complete-batch?batch_id=${batchId}`, {
      method: 'POST',
    });
    return handleResponse(response);
  }
};

// Queue Management APIs
export const queueAPI = {
  // Get current queue
  getCurrent: async () => {
    const response = await fetch(`${BASE_URL}/queue`);
    return handleResponse(response);
  },

  // Get waiting patients only
  getWaiting: async () => {
    const response = await fetch(`${BASE_URL}/queue/waiting`);
    return handleResponse(response);
  },

  // Get current patient in consultation
  getCurrentPatient: async () => {
    const response = await fetch(`${BASE_URL}/queue/current`);
    return handleResponse(response);
  },

  // Add patient to queue
  addPatient: async (patientId, priority = 'normal') => {
    const response = await fetch(`${BASE_URL}/queue`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patientId,
        priority: priority
      }),
    });
    return handleResponse(response);
  },

  // Nurse complete patient (NEW)
  nurseComplete: async (queueId) => {
    const response = await fetch(`${BASE_URL}/queue/${queueId}/nurse-complete`, {
      method: 'POST',
    });
    return handleResponse(response);
  },

  // Start consultation
  startConsultation: async (queueId) => {
    const response = await fetch(`${BASE_URL}/queue/${queueId}/start`, {
      method: 'POST',
    });
    return handleResponse(response);
  },

  // Complete consultation
  completeConsultation: async (queueId) => {
    const response = await fetch(`${BASE_URL}/queue/${queueId}/complete`, {
      method: 'POST',
    });
    return handleResponse(response);
  }
};

// Medical Notes APIs
export const notesAPI = {
  // Get all patient notes
  getAll: async (patientId) => {
    const response = await fetch(`${BASE_URL}/notes/${patientId}`);
    return handleResponse(response);
  },

  // Get latest note only
  getLatest: async (patientId) => {
    const response = await fetch(`${BASE_URL}/notes/${patientId}/latest`);
    return handleResponse(response);
  }
};

// Prescription History APIs
export const historyAPI = {
  // Get all prescription history
  getAll: async (patientId) => {
    const response = await fetch(`${BASE_URL}/history/${patientId}`);
    return handleResponse(response);
  },

  // Get all medications timeline
  getMedications: async (patientId) => {
    const response = await fetch(`${BASE_URL}/history/${patientId}/medications`);
    return handleResponse(response);
  }
};

// System Statistics API
export const statsAPI = {
  // Get dashboard statistics
  get: async () => {
    const response = await fetch(`${BASE_URL}/stats`);
    return handleResponse(response);
  }
};

// Utility functions for data transformation
export const transformers = {
  // Transform API patient data to dashboard format
  transformPatient: (apiPatient) => {
    return {
      id: apiPatient.patient_id,
      displayId: apiPatient.uhid || apiPatient.patient_id.split('_')[1],
      name: apiPatient.name,
      mobile: apiPatient.phone,
      age: apiPatient.age,
      gender: apiPatient.gender === 'male' ? 'M' : 'F',
      uhid: apiPatient.uhid || apiPatient.patient_id,
      status: 'waiting', // Will be updated from queue data
      queueNumber: null,
      checkInTime: new Date(apiPatient.created_at).toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }),
      lastUpdated: new Date(apiPatient.last_visit || apiPatient.created_at),
      visitCount: apiPatient.visit_count || 0
    };
  },

  // Transform queue data to update patient status
  transformQueueEntry: (queueEntry) => {
    // Map API status to UI status - UPDATED for new workflow
    let status = 'waiting';
    switch (queueEntry.status) {
      case 'waiting':
        status = 'waiting'; // Patient just registered, waiting for nurse
        break;
      case 'nurse_completed':
        status = 'nurse_completed'; // Nurse finished, timeline generating
        break;
      case 'ready_for_doctor':
        status = 'ready_for_doctor'; // Timeline ready, waiting for doctor
        break;
      case 'in_consultation':
        status = 'in_consultation'; // Currently with doctor
        break;
      case 'completed':
        status = 'completed'; // Consultation finished
        break;
      default:
        status = 'waiting';
    }

    return {
      queueId: queueEntry.queue_id,
      patientId: queueEntry.patient_id,
      patientName: queueEntry.patient_name,
      tokenNumber: queueEntry.token_number,
      priority: queueEntry.priority,
      status: status,
      addedAt: queueEntry.added_at,
      startedAt: queueEntry.started_at,
      completedAt: queueEntry.completed_at,
      nurseCompletedAt: queueEntry.nurse_completed_at,
      timelineReadyAt: queueEntry.timeline_ready_at
    };
  },

  // Transform timeline data for patient history
  transformTimeline: (timelineData) => {
    const timeline = timelineData.timeline || [];
    
    // Separate notes and prescriptions
    const notes = timeline.filter(entry => entry.type === 'note');
    const prescriptions = timeline.filter(entry => entry.type === 'prescription');

    // Transform for patient history component - ONLY show data available from API
    return {
      personalInfo: {
        name: timelineData.patient_name,
        age: null, // Will be filled from patient details API
        gender: null, // Will be filled from patient details API
        uhid: timelineData.patient_id,
        contact: null // Will be filled from patient details API
      },
      // Only show medications that actually have data
      medications: prescriptions
        .filter(p => p.entry.medications && p.entry.medications.length > 0)
        .flatMap(p => p.entry.medications.map(med => ({
          name: med.name || 'Unknown medication',
          dosage: med.dosage || 'Not specified',
          frequency: med.frequency || 'Not specified',
          prescriptionDate: new Date(p.date).toLocaleDateString(),
          diagnosis: p.entry.diagnosis || 'Not specified',
          doctor: p.entry.doctor_name || 'Unknown',
          hospital: p.entry.hospital || 'Not specified'
        }))),
      // Transform SOAP notes into visit history
      visitHistory: notes
        .filter(note => note.entry.soap_note && (
          note.entry.soap_note.subjective || 
          note.entry.soap_note.assessment || 
          note.entry.chief_complaint
        ))
        .map(note => ({
          date: new Date(note.date).toLocaleDateString(),
          time: new Date(note.date).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
          }),
          chiefComplaint: note.entry.chief_complaint || 'Not recorded',
          assessment: note.entry.assessment || note.entry.soap_note?.assessment || 'No assessment',
          plan: note.entry.plan || note.entry.soap_note?.plan || 'No plan recorded',
          subjective: note.entry.soap_note?.subjective || 'No symptoms recorded',
          objective: note.entry.soap_note?.objective || 'No examination findings',
          noteId: note.entry.note_id,
          audioFile: note.entry.audio_file,
          language: note.entry.soap_note?.language || 'Unknown'
        })),
      statistics: timelineData.statistics || {}
    };
  },

  // Transform latest note for encounter data
  transformEncounterData: (noteData, patientId) => {
    if (!noteData || !noteData.note) {
      return null;
    }

    const note = noteData.note;
    const soapNote = note.soap_note || {};

    return {
      patientId: patientId,
      scribeData: {
        noteId: note.note_id || null,
        rawTranscript: note.transcript || null,
        soapNote: {
          subjective: soapNote.subjective || null,
          objective: soapNote.objective || null,
          assessment: soapNote.assessment || null,
          plan: soapNote.plan || null,
          medications: soapNote.medications || []
        },
        isProcessing: false
      },
      audioFile: note.audio_file || null,
      timestamp: note.created_at || new Date().toISOString()
    };
  }
};

// Helper functions for real-time updates
export const polling = {
  // Start polling for queue updates
  startQueuePolling: (callback, interval = 5000) => {
    const poll = async () => {
      try {
        const queueData = await queueAPI.getCurrent();
        callback(queueData);
      } catch (error) {
        console.error('Queue polling error:', error);
      }
    };

    poll(); // Initial call
    const intervalId = setInterval(poll, interval);
    return intervalId;
  },

  // Start polling for current patient updates
  startCurrentPatientPolling: (callback, interval = 10000) => {
    const poll = async () => {
      try {
        const currentPatient = await queueAPI.getCurrentPatient();
        callback(currentPatient);
      } catch (error) {
        console.error('Current patient polling error:', error);
        // Don't callback on error to avoid clearing current patient
      }
    };

    const intervalId = setInterval(poll, interval);
    return intervalId;
  },

  // Start polling for latest notes
  startNotesPolling: (patientId, callback, interval = 15000) => {
    const poll = async () => {
      try {
        const latestNote = await notesAPI.getLatest(patientId);
        callback(latestNote);
      } catch (error) {
        console.error('Notes polling error:', error);
      }
    };

    const intervalId = setInterval(poll, interval);
    return intervalId;
  },

  // Stop polling
  stop: (intervalId) => {
    if (intervalId) {
      clearInterval(intervalId);
    }
  }
};

export default {
  patientsAPI,
  queueAPI,
  notesAPI,
  historyAPI,
  statsAPI,
  transformers,
  polling
};