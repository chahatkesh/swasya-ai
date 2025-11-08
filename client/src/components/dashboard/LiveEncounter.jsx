import React, { useState, useEffect, useCallback, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import { colors } from '../../utils/colors';
import { FiMic, FiFileText, FiCheck, FiLoader, FiVolume2, FiWifi, FiClock, FiPlay, FiCheckCircle, FiChevronRight, FiChevronDown } from 'react-icons/fi';
import { queueAPI, notesAPI, transformers } from '../../utils/api';

// Custom Markdown Component for SOAP Notes
const SOAPMarkdown = ({ content, className, style }) => {
  const markdownComponents = {
    // Custom styling for markdown elements
    p: ({ children }) => (
      <p className="mb-2 last:mb-0" style={style}>
        {children}
      </p>
    ),
    ul: ({ children }) => (
      <ul className="list-disc list-inside space-y-1 mb-2" style={style}>
        {children}
      </ul>
    ),
    ol: ({ children }) => (
      <ol className="list-decimal list-inside space-y-1 mb-2" style={style}>
        {children}
      </ol>
    ),
    li: ({ children }) => (
      <li className="ml-2" style={style}>
        {children}
      </li>
    ),
    strong: ({ children }) => (
      <strong className="font-semibold" style={style}>
        {children}
      </strong>
    ),
    em: ({ children }) => (
      <em className="italic" style={style}>
        {children}
      </em>
    ),
    h1: ({ children }) => (
      <h1 className="text-base font-semibold mb-2" style={style}>
        {children}
      </h1>
    ),
    h2: ({ children }) => (
      <h2 className="text-sm font-semibold mb-2" style={style}>
        {children}
      </h2>
    ),
    h3: ({ children }) => (
      <h3 className="text-sm font-medium mb-1" style={style}>
        {children}
      </h3>
    ),
    blockquote: ({ children }) => (
      <blockquote 
        className="border-l-2 pl-3 mb-2" 
        style={{ 
          borderColor: colors.textTertiary + '40',
          ...style 
        }}
      >
        {children}
      </blockquote>
    ),
    code: ({ children }) => (
      <code 
        className="px-1 py-0.5 rounded text-xs font-mono"
        style={{
          backgroundColor: colors.surfaceSecondary,
          color: colors.textPrimary
        }}
      >
        {children}
      </code>
    )
  };

  return (
    <div className={className}>
      <ReactMarkdown components={markdownComponents}>
        {content || 'No data recorded'}
      </ReactMarkdown>
    </div>
  );
};

// Previous SOAP Notes Component
const PreviousSOAPNotes = ({ timelineData, colors }) => {
  const [expandedNotes, setExpandedNotes] = useState(new Set());
  
  const toggleNote = (index) => {
    const newExpanded = new Set(expandedNotes);
    if (newExpanded.has(index)) {
      newExpanded.delete(index);
    } else {
      newExpanded.add(index);
    }
    setExpandedNotes(newExpanded);
  };

  const filteredNotes = timelineData.timeline
    .filter(entry => entry.type === 'note')
    .slice(0, 8); // Show up to 8 recent notes

  return (
    <div className="mt-6 mb-6 px-6">
      <div className="flex items-center gap-2 mb-6">
        <FiFileText size={18} style={{ color: colors.textSecondary }} />
        <h3 
          className="text-lg font-medium"
          style={{ color: colors.textPrimary }}
        >
          Previous SOAP Notes
        </h3>
        <span 
          className="text-xs px-2 py-1 rounded-full"
          style={{ 
            backgroundColor: colors.textTertiary + '20',
            color: colors.textTertiary 
          }}
        >
          {filteredNotes.length} recent
        </span>
      </div>
      
      <div className="space-y-4">
        {filteredNotes.map((entry, index) => {
          const soapNote = entry.entry.soap_note || {};
          const isExpanded = expandedNotes.has(index);
          const chiefComplaint = entry.entry.chief_complaint || 'Medical Consultation';
          const hasValidSoap = soapNote.subjective || soapNote.objective || soapNote.assessment || soapNote.plan;
          
          return (
            <div 
              key={index}
              className="rounded-2xl transition-all duration-200"
              style={{ 
                backgroundColor: colors.surfaceSecondary,
                border: `1px solid ${colors.border}`
              }}
            >
              {/* Header - Always visible */}
              <div 
                className="p-5 cursor-pointer hover:bg-opacity-50 transition-colors"
                onClick={() => toggleNote(index)}
                style={{
                  backgroundColor: 'transparent'
                }}
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    {/* Chief Complaint */}
                    <div className="flex items-start gap-3">
                      <div className="transition-transform duration-200 mt-1">
                        {isExpanded ? (
                          <FiChevronDown size={16} style={{ color: colors.textSecondary }} />
                        ) : (
                          <FiChevronRight size={16} style={{ color: colors.textSecondary }} />
                        )}
                      </div>
                      <div className="flex-1">
                        <h4 
                          className="font-ptserif text-lg font-normal leading-relaxed"
                          style={{ color: colors.textPrimary }}
                        >
                          {chiefComplaint}
                        </h4>
                        <div className="flex items-center gap-3 mt-2">
                          <div 
                            className="text-xs"
                            style={{ color: colors.textTertiary }}
                          >
                            {new Date(entry.date).toLocaleDateString('en-US', {
                              month: 'short',
                              day: 'numeric',
                              year: 'numeric'
                            })} • {new Date(entry.date).toLocaleTimeString('en-US', {
                              hour: '2-digit',
                              minute: '2-digit',
                              hour12: true
                            })}
                          </div>
                          {soapNote.language && soapNote.language !== 'Unknown' && (
                            <span 
                              className="text-xs px-2 py-1 rounded-full"
                              style={{ 
                                backgroundColor: colors.accent + '20',
                                color: colors.accent 
                              }}
                            >
                              {soapNote.language}
                            </span>
                          )}
                          {hasValidSoap && (
                            <span 
                              className="text-xs px-2 py-1 rounded-full"
                              style={{ 
                                backgroundColor: colors.success + '20',
                                color: colors.success 
                              }}
                            >
                              Complete SOAP
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Expanded SOAP Note Content - Compact Apple-inspired Design */}
              {isExpanded && hasValidSoap && (
                <div 
                  className="px-5 pb-5 border-t"
                  style={{ borderColor: colors.border }}
                >
                  <div className="ml-7 pt-4">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
                      {/* Subjective */}
                      {soapNote.subjective && soapNote.subjective !== 'No symptoms recorded' && (
                        <div 
                          className="p-4 rounded-xl transition-all duration-200"
                          style={{ 
                            backgroundColor: colors.surfaceSecondary,
                            border: `1px solid ${colors.border}`
                          }}
                        >
                          <div className="flex items-center gap-2 mb-3">
                            <div 
                              className="w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold"
                              style={{ 
                                backgroundColor: colors.primary,
                                color: colors.surface
                              }}
                            >
                              S
                            </div>
                            <span 
                              className="font-ptserif text-sm font-normal tracking-tight"
                              style={{ color: colors.primary }}
                            >
                              Subjective
                            </span>
                          </div>
                          <SOAPMarkdown
                            content={soapNote.subjective}
                            className="text-xs leading-relaxed font-light"
                            style={{ color: colors.textPrimary }}
                          />
                        </div>
                      )}

                      {/* Objective */}
                      {soapNote.objective && soapNote.objective !== 'No examination findings' && (
                        <div 
                          className="p-4 rounded-xl transition-all duration-200"
                          style={{ 
                            backgroundColor: colors.surfaceSecondary,
                            border: `1px solid ${colors.border}`
                          }}
                        >
                          <div className="flex items-center gap-2 mb-3">
                            <div 
                              className="w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold"
                              style={{ 
                                backgroundColor: colors.accent,
                                color: colors.surface
                              }}
                            >
                              O
                            </div>
                            <span 
                              className="font-ptserif text-sm font-normal tracking-tight"
                              style={{ color: colors.accent }}
                            >
                              Objective
                            </span>
                          </div>
                          <SOAPMarkdown
                            content={soapNote.objective}
                            className="text-xs leading-relaxed font-light"
                            style={{ color: colors.textPrimary }}
                          />
                        </div>
                      )}

                      {/* Assessment */}
                      {soapNote.assessment && soapNote.assessment !== 'No assessment' && (
                        <div 
                          className="p-4 rounded-xl transition-all duration-200"
                          style={{ 
                            backgroundColor: colors.surfaceSecondary,
                            border: `1px solid ${colors.border}`
                          }}
                        >
                          <div className="flex items-center gap-2 mb-3">
                            <div 
                              className="w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold"
                              style={{ 
                                backgroundColor: colors.warning,
                                color: colors.surface
                              }}
                            >
                              A
                            </div>
                            <span 
                              className="font-ptserif text-sm font-normal tracking-tight"
                              style={{ color: colors.warning }}
                            >
                              Assessment
                            </span>
                          </div>
                          <SOAPMarkdown
                            content={soapNote.assessment}
                            className="text-xs leading-relaxed font-light"
                            style={{ color: colors.textPrimary }}
                          />
                        </div>
                      )}

                      {/* Plan */}
                      {soapNote.plan && soapNote.plan !== 'No plan recorded' && (
                        <div 
                          className="p-4 rounded-xl transition-all duration-200"
                          style={{ 
                            backgroundColor: colors.surfaceSecondary,
                            border: `1px solid ${colors.border}`
                          }}
                        >
                          <div className="flex items-center gap-2 mb-3">
                            <div 
                              className="w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold"
                              style={{ 
                                backgroundColor: colors.success,
                                color: colors.surface
                              }}
                            >
                              P
                            </div>
                            <span 
                              className="font-ptserif text-sm font-normal tracking-tight"
                              style={{ color: colors.success }}
                            >
                              Plan
                            </span>
                          </div>
                          <SOAPMarkdown
                            content={soapNote.plan}
                            className="text-xs leading-relaxed font-light"
                            style={{ color: colors.textPrimary }}
                          />
                        </div>
                      )}
                    </div>

                    {/* Medications if available */}
                    {soapNote.medications && soapNote.medications.length > 0 && (
                      <div className="mt-4">
                        <div className="flex items-center gap-2 mb-3">
                          <div 
                            className="w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold"
                            style={{ 
                              backgroundColor: colors.error,
                              color: colors.surface
                            }}
                          >
                            Rx
                          </div>
                          <span 
                            className="font-ptserif text-sm font-normal tracking-tight"
                            style={{ color: colors.error }}
                          >
                            Medications
                          </span>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                          {soapNote.medications.map((med, medIndex) => (
                            <div 
                              key={medIndex}
                              className="text-xs p-3 rounded-lg border"
                              style={{ 
                                backgroundColor: colors.surfaceSecondary,
                                borderColor: colors.border,
                                color: colors.textPrimary 
                              }}
                            >
                              <div className="font-medium">{med.name}</div>
                              <div className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                                {med.dosage} • {med.frequency}
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Show message if no valid SOAP data when expanded */}
              {isExpanded && !hasValidSoap && (
                <div 
                  className="px-5 pb-5 border-t"
                  style={{ borderColor: colors.border }}
                >
                  <div className="ml-7 pt-4">
                    <div 
                      className="p-4 rounded-xl border text-center"
                      style={{ 
                        backgroundColor: colors.surfaceSecondary,
                        borderColor: colors.border,
                        borderStyle: 'dashed'
                      }}
                    >
                      <FiFileText size={16} className="mx-auto mb-2" style={{ color: colors.textTertiary }} />
                      <p 
                        className="text-xs"
                        style={{ color: colors.textSecondary }}
                      >
                        No structured SOAP note available for this consultation
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
      
      {timelineData.timeline.filter(entry => entry.type === 'note').length > filteredNotes.length && (
        <div className="mt-6 text-center">
          <p 
            className="text-sm"
            style={{ color: colors.textSecondary }}
          >
            Showing {filteredNotes.length} most recent SOAP notes • {timelineData.timeline.filter(entry => entry.type === 'note').length - filteredNotes.length} more available
          </p>
        </div>
      )}
    </div>
  );
};

const LiveEncounter = ({ encounterData, selectedPatient, timelineData, onConsultationAction }) => {
  const [liveEncounterData, setLiveEncounterData] = useState(encounterData);
  const [isPolling, setIsPolling] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('connected');
  const [consultationLoading, setConsultationLoading] = useState(false);
  const [showRawTranscript, setShowRawTranscript] = useState(false); // Toggle for raw transcript
  const pollingIntervalRef = useRef(null);
  const cacheKeyRef = useRef(null);
  const currentPatientRef = useRef(null); // Track current patient to prevent conflicts
  const lastPollTime = useRef(0); // Prevent too frequent polling

  // Cache management for localStorage - Patient-specific keys
  const getCacheKey = useCallback((patientId) => {
    return `live_encounter_${patientId}_v3`; // Updated to v3 to force refresh after chief complaint fix
  }, []);

  const getCachedData = useCallback((patientId) => {
    try {
      const cached = localStorage.getItem(getCacheKey(patientId));
      if (cached) {
        const parsedCache = JSON.parse(cached);
        // Validate cache belongs to correct patient
        if (parsedCache.patientId === patientId) {
          return parsedCache;
        } else {
          // Clear invalid cache
          localStorage.removeItem(getCacheKey(patientId));
          return null;
        }
      }
      return null;
    } catch (error) {
      console.error('Error reading cache:', error);
      localStorage.removeItem(getCacheKey(patientId));
      return null;
    }
  }, [getCacheKey]);

  const setCachedData = useCallback((patientId, data) => {
    try {
      const cacheData = {
        patientId: patientId, // Store patient ID for validation
        timestamp: new Date().toISOString(),
        encounterData: data,
        noteId: data?.scribeData?.noteId || null,
        transcript: data?.scribeData?.rawTranscript || null,
        lastChecked: new Date().toISOString()
      };
      localStorage.setItem(getCacheKey(patientId), JSON.stringify(cacheData));
      console.log(`💾 Cached data for patient: ${patientId}`, { noteId: cacheData.noteId });
    } catch (error) {
      console.error('Error writing cache:', error);
    }
  }, [getCacheKey]);

  // Initial fetch function - called when patient is first selected
  const fetchLatestData = useCallback(async (patientId) => {
    try {
      console.log(`� Fetching latest data for patient: ${patientId}`);
      setConnectionStatus('connecting');
      
      const latestNote = await notesAPI.getLatest(patientId);
      
      if (latestNote && latestNote.success && latestNote.note) {
        const transformedData = transformers.transformEncounterData(latestNote, patientId);
        const cached = getCachedData(patientId);
        
        // Compare with cached data
        const newTranscript = latestNote.note.transcript || '';
        const cachedTranscript = cached?.transcript || '';
        const newNoteId = latestNote.note.note_id;
        const cachedNoteId = cached?.noteId;
        
        console.log(`📊 Comparing data for patient ${patientId}:`, {
          newNoteId,
          cachedNoteId,
          transcriptChanged: newTranscript !== cachedTranscript,
          noteIdChanged: newNoteId !== cachedNoteId
        });
        
        // Update if transcript or note ID differs
        if (newTranscript !== cachedTranscript || newNoteId !== cachedNoteId || !cached) {
          console.log(`🆕 New/different data detected for patient ${patientId}, updating...`);
          setLiveEncounterData(transformedData);
          setCachedData(patientId, transformedData);
          setLastUpdateTime(new Date());
        } else {
          console.log(`✅ Using cached data for patient ${patientId} (no changes)`);
          setLiveEncounterData(cached.encounterData);
          setLastUpdateTime(new Date(cached.timestamp));
        }
        
        setConnectionStatus('connected');
        return transformedData;
      } else {
        console.log(`⚠️ No note data received for patient: ${patientId}`);
        setConnectionStatus('connected');
        return null;
      }
    } catch (error) {
      console.error(`❌ Error fetching data for patient ${patientId}:`, error);
      setConnectionStatus('error');
      return null;
    }
  }, [getCachedData, setCachedData]);

  // Polling function for continuous updates
  const pollLatestNote = useCallback(async (patientId) => {
    // Prevent polling conflicts and excessive calls
    const now = Date.now();
    if (now - lastPollTime.current < 2000) { // Minimum 2 seconds between polls
      return;
    }
    lastPollTime.current = now;
    
    // Check if this is still the current patient
    if (currentPatientRef.current !== patientId) {
      console.log(`⚠️ Skipping poll for ${patientId}, current patient is ${currentPatientRef.current}`);
      return;
    }
    
    try {
      const latestNote = await notesAPI.getLatest(patientId);
      
      if (latestNote && latestNote.success && latestNote.note) {
        const transformedData = transformers.transformEncounterData(latestNote, patientId);
        
        // Use ref to get current state without causing dependency issues
        const newTranscript = latestNote.note.transcript || '';
        const newNoteId = latestNote.note.note_id;
        
        // Get current data from state
        setLiveEncounterData(currentData => {
          const currentTranscript = currentData?.scribeData?.rawTranscript || '';
          const currentNoteId = currentData?.scribeData?.noteId;
          
          // Update if there are any changes
          if (newTranscript !== currentTranscript || newNoteId !== currentNoteId) {
            console.log(`🔄 Real-time update detected for patient ${patientId}:`, {
              newNoteId,
              currentNoteId,
              transcriptChanged: newTranscript !== currentTranscript
            });
            
            setCachedData(patientId, transformedData);
            setLastUpdateTime(new Date());
            return transformedData;
          }
          
          // No changes, return current data
          return currentData;
        });
        
        setConnectionStatus('connected');
      } else {
        setConnectionStatus('connected');
      }
    } catch (error) {
      console.error(`❌ Polling error for patient ${patientId}:`, error);
      setConnectionStatus('error');
    }
  }, [setCachedData]);

  // Start polling when patient is selected
  const startPolling = useCallback((patientId) => {
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
    }

    setIsPolling(true);
    console.log(`🔴 Starting polling for patient: ${patientId}`);
    
    // Set up recurring polling every 3 seconds as requested
    pollingIntervalRef.current = setInterval(() => {
      pollLatestNote(patientId);
    }, 3000);

    console.log(`🔴 Live polling started for patient: ${patientId} (3-second intervals)`);
  }, [pollLatestNote]);

  // Stop polling
  const stopPolling = useCallback(() => {
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
      pollingIntervalRef.current = null;
    }
    setIsPolling(false);
    console.log('⏹️ Live polling stopped');
  }, []);

  // Consultation management functions
  const handleStartConsultation = useCallback(async () => {
    if (!selectedPatient?.queueId) {
      console.error('No queue ID available for patient');
      return;
    }

    try {
      setConsultationLoading(true);
      await queueAPI.startConsultation(selectedPatient.queueId);
      console.log('✅ Consultation started for queue:', selectedPatient.queueId);
      
      // Refresh the dashboard data
      if (onConsultationAction) {
        onConsultationAction();
      }
      
    } catch (error) {
      console.error('Error starting consultation:', error);
      alert('Failed to start consultation. Please try again.');
    } finally {
      setConsultationLoading(false);
    }
  }, [selectedPatient?.queueId, onConsultationAction]);

  const handleCompleteConsultation = useCallback(async () => {
    if (!selectedPatient?.queueId) {
      console.error('No queue ID available for patient');
      return;
    }

    try {
      setConsultationLoading(true);
      await queueAPI.completeConsultation(selectedPatient.queueId);
      console.log('✅ Consultation completed for queue:', selectedPatient.queueId);
      
      // Show success message
      alert('Consultation completed successfully! Next patient can now be seen.');
      
      // Refresh the dashboard data
      if (onConsultationAction) {
        onConsultationAction();
      }
      
    } catch (error) {
      console.error('Error completing consultation:', error);
      alert('Failed to complete consultation. Please try again.');
    } finally {
      setConsultationLoading(false);
    }
  }, [selectedPatient?.queueId, onConsultationAction]);

  // Effect to manage patient selection and initial data fetch
  useEffect(() => {
    if (selectedPatient?.id) {
      console.log(`👤 Patient selected: ${selectedPatient.id}`);
      
      // Update current patient ref
      currentPatientRef.current = selectedPatient.id;
      
      // Clear previous patient's data immediately
      setLiveEncounterData(null);
      setLastUpdateTime(null);
      
      // Stop any existing polling
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current);
        pollingIntervalRef.current = null;
      }
      
      // Set cache reference
      cacheKeyRef.current = selectedPatient.id;
      
      // Small delay to prevent excessive calls, then fetch data
      const timeoutId = setTimeout(() => {
        fetchLatestData(selectedPatient.id).then(() => {
          // After initial fetch, start polling for updates
          if (currentPatientRef.current === selectedPatient.id) {
            startPolling(selectedPatient.id);
          }
        });
      }, 100);
      
      return () => {
        clearTimeout(timeoutId);
      };
      
    } else {
      console.log('❌ No patient selected, cleaning up');
      currentPatientRef.current = null;
      stopPolling();
      setLiveEncounterData(null);
      setLastUpdateTime(null);
    }

    // Cleanup on unmount or patient change
    return () => {
      stopPolling();
    };
  }, [selectedPatient?.id, fetchLatestData, startPolling, stopPolling]);

  // Remove the old effect that synced with parent encounterData to avoid conflicts
  // The fetchLatestData function handles all data fetching and comparison
  if (!selectedPatient) {
    return (
      <div className="h-full flex flex-col items-center justify-center" style={{ backgroundColor: colors.surfaceSecondary }}>
        <div className="text-center space-y-4 max-w-md">
          <div 
            className="w-20 h-20 rounded-full mx-auto flex items-center justify-center"
            style={{ backgroundColor: colors.primary20 }}
          >
            <FiFileText size={32} style={{ color: colors.primary }} />
          </div>
          <h3 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Select a Patient
          </h3>
          <p 
            className="text-base font-light"
            style={{ color: colors.textSecondary }}
          >
            Choose a patient from the queue to view their live encounter data from the AI Scribe system.
          </p>
        </div>
      </div>
    );
  }

  // Show message if no encounter data is available
  if (!liveEncounterData || !liveEncounterData.scribeData) {
    return (
      <div className="h-full flex flex-col" style={{ backgroundColor: colors.surface }}>
        {/* Header */}
        <div className="h-20 flex flex-col justify-center p-6 border-b" style={{ borderColor: colors.border }}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <h2 
                className="text-xl font-medium"
                style={{ color: colors.textPrimary }}
              >
                Live Encounter
              </h2>
              {selectedPatient && (
                <div className="flex items-center gap-2 text-sm" style={{ color: colors.textSecondary }}>
                  <span>{selectedPatient.name}</span>
                  <span>•</span>
                  <span>{selectedPatient.age}/{selectedPatient.gender}</span>
                  <span>•</span>
                  <span style={{ color: colors.textTertiary }}>ID: {selectedPatient.displayId}</span>
                </div>
              )}
            </div>
            
            <div className="flex items-center gap-3">
              <div 
                className="text-sm font-medium px-3 py-1 rounded-full"
                style={{ 
                  backgroundColor: colors.warning + '20',
                  color: colors.warning 
                }}
              >
                No Data Available
              </div>
            </div>
          </div>
        </div>

        {/* No Data Message */}
        <div className="flex-1 flex items-center justify-center">
          <div className="text-center space-y-4 max-w-md">
            <div 
              className="w-16 h-16 rounded-full mx-auto flex items-center justify-center"
              style={{ backgroundColor: colors.warning + '20' }}
            >
              <FiMic size={24} style={{ color: colors.warning }} />
            </div>
            <h3 
              className="text-lg font-medium"
              style={{ color: colors.textPrimary }}
            >
              No Encounter Data
            </h3>
            <p 
              className="text-sm"
              style={{ color: colors.textSecondary }}
            >
              No recent SOAP notes or consultation data available for this patient.
            </p>
          </div>
        </div>
      </div>
    );
  }

  const soapNote = liveEncounterData.scribeData.soapNote;
  const hasValidSoapNote = soapNote && (
    soapNote.subjective || 
    soapNote.objective || 
    soapNote.assessment || 
    soapNote.plan
  );

  return (
    <div className="h-full flex flex-col" style={{ backgroundColor: colors.surface }}>
      {/* Header */}
      <div className="h-20 flex flex-col justify-center p-6 border-b" style={{ borderColor: colors.border }}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h2 
              className="text-xl font-medium"
              style={{ color: colors.textPrimary }}
            >
              Live Encounter
            </h2>
            {selectedPatient && (
              <div className="flex items-center gap-2 text-sm" style={{ color: colors.textSecondary }}>
                <span>{selectedPatient.name}</span>
                <span>•</span>
                <span>{selectedPatient.age}/{selectedPatient.gender}</span>
                <span>•</span>
                <span style={{ color: colors.textTertiary }}>ID: {selectedPatient.displayId}</span>
              </div>
            )}
          </div>
          
          <div className="flex items-center gap-3">
            {/* Live Status Indicator */}
            <div className="flex items-center gap-2">
              <div 
                className={`w-2 h-2 rounded-full ${isPolling ? 'animate-pulse' : ''}`}
                style={{ 
                  backgroundColor: connectionStatus === 'connected' ? colors.success : 
                                 connectionStatus === 'connecting' ? colors.warning : colors.error
                }}
              />
              <span 
                className="text-xs font-medium"
                style={{ 
                  color: connectionStatus === 'connected' ? colors.success : 
                        connectionStatus === 'connecting' ? colors.warning : colors.error
                }}
              >
                {connectionStatus === 'connected' ? 'LIVE' : 
                 connectionStatus === 'connecting' ? 'CONNECTING' : 'OFFLINE'}
              </span>
            </div>

            {/* Last Update Time */}
            {lastUpdateTime && (
              <div className="flex items-center gap-1">
                <FiClock size={12} style={{ color: colors.textTertiary }} />
                <span 
                  className="text-xs"
                  style={{ color: colors.textTertiary }}
                >
                  {lastUpdateTime.toLocaleTimeString('en-US', {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit'
                  })}
                </span>
              </div>
            )}
            
            {/* Data Status */}
            <div 
              className="text-sm font-medium px-3 py-1 rounded-full"
              style={{ 
                backgroundColor: hasValidSoapNote ? colors.success + '20' : colors.warning + '20',
                color: hasValidSoapNote ? colors.success : colors.warning
              }}
            >
              {hasValidSoapNote ? 'SOAP Available' : 'Limited Data'}
            </div>

            {/* Consultation Management Buttons */}
            {selectedPatient.queueId && (
              <div className="flex items-center gap-2">
                {/* For patients who are ready to start consultation */}
                {(selectedPatient.status === 'nurse_completed' || selectedPatient.status === 'ready_for_doctor') && (
                  <button
                    onClick={handleStartConsultation}
                    disabled={consultationLoading}
                    className="flex items-center gap-2 px-3 py-1 rounded-lg text-sm font-medium transition-colors hover:opacity-80 disabled:opacity-50"
                    style={{
                      backgroundColor: colors.primary,
                      color: colors.surface
                    }}
                  >
                    <FiPlay size={14} />
                    {consultationLoading ? 'Starting...' : 'Start Consultation'}
                  </button>
                )}
                
                {/* For patients currently in consultation */}
                {selectedPatient.status === 'in_consultation' && (
                  <button
                    onClick={handleCompleteConsultation}
                    disabled={consultationLoading}
                    className="flex items-center gap-2 px-3 py-1 rounded-lg text-sm font-medium transition-colors hover:opacity-80 disabled:opacity-50"
                    style={{
                      backgroundColor: colors.success,
                      color: colors.surface
                    }}
                  >
                    <FiCheckCircle size={14} />
                    {consultationLoading ? 'Completing...' : 'Complete Consultation'}
                  </button>
                )}

                {/* Show status for waiting patients */}
                {selectedPatient.status === 'waiting' && (
                  <div 
                    className="text-sm font-medium px-3 py-1 rounded-lg"
                    style={{
                      backgroundColor: colors.textTertiary + '20',
                      color: colors.textTertiary
                    }}
                  >
                    With Nurse
                  </div>
                )}

                {/* Show status for completed patients */}
                {selectedPatient.status === 'completed' && (
                  <div 
                    className="text-sm font-medium px-3 py-1 rounded-lg"
                    style={{
                      backgroundColor: colors.success + '20',
                      color: colors.success
                    }}
                  >
                    Consultation Completed
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-6 space-y-6">
          
          {/* AI Scribe Module - Only show real data */}
          <div 
            className="rounded-2xl p-6 border"
            style={{ 
              backgroundColor: colors.background,
              borderColor: colors.border 
            }}
          >
            {/* Raw Transcript - Collapsible Toggle */}
            {liveEncounterData.scribeData.rawTranscript && (
              <div className="mb-6">
                <div 
                  className="flex items-center gap-2 p-2 rounded-lg cursor-pointer transition-all duration-200 hover:bg-opacity-50"
                  style={{
                    backgroundColor: 'transparent',
                    ':hover': {
                      backgroundColor: colors.textTertiary + '10'
                    }
                  }}
                  onClick={() => setShowRawTranscript(prev => !prev)}
                >
                  {/* Chevron Icon */}
                  <div className="transition-transform duration-200">
                    {showRawTranscript ? (
                      <FiChevronDown size={16} style={{ color: colors.textSecondary }} />
                    ) : (
                      <FiChevronRight size={16} style={{ color: colors.textSecondary }} />
                    )}
                  </div>
                  
                  <FiVolume2 size={16} style={{ color: colors.textSecondary }} />
                  <h4 
                    className="text-sm font-medium select-none"
                    style={{ color: colors.textSecondary }}
                  >
                    Raw Audio Transcript
                  </h4>
                </div>
                
                {/* Collapsible Content */}
                {showRawTranscript && (
                  <div className="ml-6 mt-2">
                    <div 
                      className="p-4 rounded-xl text-sm max-h-32 overflow-y-auto"
                      style={{ 
                        backgroundColor: colors.surfaceSecondary,
                        color: colors.textSecondary 
                      }}
                    >
                      {liveEncounterData.scribeData.rawTranscript}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Chief Complaint - Title display */}
            {liveEncounterData.chiefComplaint && (
              <div className="mb-6">
                <h3 
                  className="font-ptserif ml-2 text-2xl font-medium leading-relaxed"
                  style={{ color: colors.textPrimary }}
                >
                  {liveEncounterData.chiefComplaint}
                </h3>
              </div>
            )}
            {/* SOAP Note - Only show real data */}
            <div>
              {hasValidSoapNote ? (
                <div>
                  {/* 4-Box Grid Layout for SOAP Note - Apple-inspired Clean Design */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Subjective */}
                  <div 
                    className="p-6 rounded-2xl transition-all duration-200 hover:scale-[1.02]"
                    style={{ 
                      backgroundColor: colors.surfaceSecondary,
                      border: `1px solid ${colors.border}`
                    }}
                  >
                    <div className="flex items-center gap-3 mb-4">
                      <div 
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold"
                        style={{ 
                          backgroundColor: colors.primary,
                          color: colors.surface
                        }}
                      >
                        S
                      </div>
                      <h5 
                        className="font-ptserif text-lg font-normal tracking-tight"
                        style={{ color: colors.primary }}
                      >
                        Subjective
                      </h5>
                    </div>
                    <SOAPMarkdown
                      content={soapNote.subjective}
                      className="text-sm leading-relaxed min-h-20 font-light"
                      style={{ color: colors.textPrimary }}
                    />
                  </div>

                  {/* Objective */}
                  <div 
                    className="p-6 rounded-2xl transition-all duration-200 hover:scale-[1.02]"
                    style={{ 
                      backgroundColor: colors.surfaceSecondary,
                      border: `1px solid ${colors.border}`
                    }}
                  >
                    <div className="flex items-center gap-3 mb-4">
                      <div 
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold"
                        style={{ 
                          backgroundColor: colors.accent,
                          color: colors.surface
                        }}
                      >
                        O
                      </div>
                      <h5 
                        className="font-ptserif text-lg font-normal tracking-tight"
                        style={{ color: colors.accent }}
                      >
                        Objective
                      </h5>
                    </div>
                    <SOAPMarkdown
                      content={soapNote.objective}
                      className="text-sm leading-relaxed min-h-20 font-light"
                      style={{ color: colors.textPrimary }}
                    />
                  </div>

                  {/* Assessment */}
                  <div 
                    className="p-6 rounded-2xl transition-all duration-200 hover:scale-[1.02]"
                    style={{ 
                      backgroundColor: colors.surfaceSecondary,
                      border: `1px solid ${colors.border}`
                    }}
                  >
                    <div className="flex items-center gap-3 mb-4">
                      <div 
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold"
                        style={{ 
                          backgroundColor: colors.warning,
                          color: colors.surface
                        }}
                      >
                        A
                      </div>
                      <h5 
                        className="font-ptserif text-lg font-normal tracking-tight"
                        style={{ color: colors.warning }}
                      >
                        Assessment
                      </h5>
                    </div>
                    <SOAPMarkdown
                      content={soapNote.assessment}
                      className="text-sm leading-relaxed min-h-20 font-light"
                      style={{ color: colors.textPrimary }}
                    />
                  </div>

                  {/* Plan */}
                  <div 
                    className="p-6 rounded-2xl transition-all duration-200 hover:scale-[1.02]"
                    style={{ 
                      backgroundColor: colors.surfaceSecondary,
                      border: `1px solid ${colors.border}`
                    }}
                  >
                    <div className="flex items-center gap-3 mb-4">
                      <div 
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold"
                        style={{ 
                          backgroundColor: colors.success,
                          color: colors.surface
                        }}
                      >
                        P
                      </div>
                      <h5 
                        className="font-ptserif text-lg font-normal tracking-tight"
                        style={{ color: colors.success }}
                      >
                        Plan
                      </h5>
                    </div>
                    <SOAPMarkdown
                      content={soapNote.plan}
                      className="text-sm leading-relaxed min-h-20 font-light"
                      style={{ color: colors.textPrimary }}
                    />
                  </div>
                </div>

                {/* Show medications if available - Separate section */}
                {soapNote.medications && soapNote.medications.length > 0 && (
                  <div className="mt-6">
                    <div className="flex items-center gap-2 mb-3">
                      <div 
                        className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold"
                        style={{ 
                          backgroundColor: colors.error + '20',
                          color: colors.error 
                        }}
                      >
                        Rx
                      </div>
                      <h5 
                        className="text-sm font-semibold"
                        style={{ color: colors.error }}
                      >
                        Medications
                      </h5>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {soapNote.medications.map((med, index) => (
                        <div 
                          key={index}
                          className="text-sm p-3 rounded-lg border"
                          style={{ 
                            backgroundColor: colors.surfaceSecondary,
                            borderColor: colors.error + '20',
                            color: colors.textPrimary 
                          }}
                        >
                          <div className="font-medium">{med.name}</div>
                          <div className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                            {med.dosage} • {med.frequency}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                </div>
              ) : (
                <div 
                  className="p-8 rounded-xl border text-center"
                  style={{ 
                    backgroundColor: colors.surfaceSecondary,
                    borderColor: colors.border,
                    borderStyle: 'dashed'
                  }}
                >
                  <FiLoader size={24} className="mx-auto mb-3" style={{ color: colors.textTertiary }} />
                  <p 
                    className="text-sm"
                    style={{ color: colors.textSecondary }}
                  >
                    No structured SOAP note available
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
        {/* Previous SOAP Notes - Improved UI */}
        {timelineData && timelineData.timeline && timelineData.timeline.length > 0 && (
          <PreviousSOAPNotes 
            timelineData={timelineData}
            colors={colors}
          />
        )}
      </div>
    </div>
  );
};

export default LiveEncounter;