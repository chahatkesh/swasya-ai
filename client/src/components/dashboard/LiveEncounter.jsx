import React, { useState, useEffect, useCallback, useRef } from 'react';
import { colors } from '../../utils/colors';
import { FiMic, FiFileText, FiCheck, FiLoader, FiVolume2, FiWifi, FiClock, FiPlay, FiCheckCircle } from 'react-icons/fi';
import { queueAPI } from '../../utils/api';

const LiveEncounter = ({ encounterData, selectedPatient, timelineData, onConsultationAction }) => {
  const [liveEncounterData, setLiveEncounterData] = useState(encounterData);
  const [isPolling, setIsPolling] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('connected');
  const [consultationLoading, setConsultationLoading] = useState(false);
  const pollingIntervalRef = useRef(null);
  const cacheKeyRef = useRef(null);

  // Cache management for localStorage
  const getCacheKey = useCallback((patientId) => {
    return `live_encounter_${patientId}`;
  }, []);

  const getCachedData = useCallback((patientId) => {
    try {
      const cached = localStorage.getItem(getCacheKey(patientId));
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      console.error('Error reading cache:', error);
      return null;
    }
  }, [getCacheKey]);

  const setCachedData = useCallback((patientId, data) => {
    try {
      const cacheData = {
        timestamp: new Date().toISOString(),
        encounterData: data,
        noteId: data?.scribeData?.noteId || null,
        lastChecked: new Date().toISOString()
      };
      localStorage.setItem(getCacheKey(patientId), JSON.stringify(cacheData));
    } catch (error) {
      console.error('Error writing cache:', error);
    }
  }, [getCacheKey]);

  // API polling function
  const pollLatestNote = useCallback(async (patientId) => {
    try {
      setConnectionStatus('connecting');
      
      // Import the API functions (they should be available from the context)
      const { notesAPI, transformers } = await import('../../utils/api');
      
      const latestNote = await notesAPI.getLatest(patientId);
      
      if (latestNote && latestNote.success && latestNote.note) {
        const transformedData = transformers.transformEncounterData(latestNote, patientId);
        const cached = getCachedData(patientId);
        
        // Check if data has changed
        const hasChanged = !cached || 
          cached.noteId !== latestNote.note.note_id ||
          cached.timestamp !== latestNote.note.created_at;

        if (hasChanged) {
          console.log('🔄 New SOAP note detected, updating UI');
          setLiveEncounterData(transformedData);
          setCachedData(patientId, transformedData);
          setLastUpdateTime(new Date());
        }
        
        setConnectionStatus('connected');
      } else {
        setConnectionStatus('connected');
      }
    } catch (error) {
      console.error('Polling error:', error);
      setConnectionStatus('error');
    }
  }, [getCachedData, setCachedData]);

  // Start polling when patient is selected
  const startPolling = useCallback((patientId) => {
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
    }

    setIsPolling(true);
    setConnectionStatus('connected');
    
    // Initial poll
    pollLatestNote(patientId);
    
    // Set up recurring polling every 3 seconds
    pollingIntervalRef.current = setInterval(() => {
      pollLatestNote(patientId);
    }, 3000);

    console.log(`🔴 Live polling started for patient: ${patientId}`);
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

  // Effect to manage polling based on selected patient
  useEffect(() => {
    if (selectedPatient?.id) {
      // Check cache first
      const cached = getCachedData(selectedPatient.id);
      if (cached && cached.encounterData) {
        setLiveEncounterData(cached.encounterData);
        setLastUpdateTime(new Date(cached.timestamp));
      }
      
      // Start live polling
      cacheKeyRef.current = selectedPatient.id;
      startPolling(selectedPatient.id);
    } else {
      stopPolling();
      setLiveEncounterData(null);
      setLastUpdateTime(null);
    }

    // Cleanup on unmount or patient change
    return () => {
      stopPolling();
    };
  }, [selectedPatient?.id, startPolling, stopPolling, getCachedData]);

  // Sync with parent encounterData prop
  useEffect(() => {
    if (encounterData && (!liveEncounterData || encounterData !== liveEncounterData)) {
      setLiveEncounterData(encounterData);
      if (selectedPatient?.id) {
        setCachedData(selectedPatient.id, encounterData);
      }
    }
  }, [encounterData, liveEncounterData, selectedPatient?.id, setCachedData]);
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
        <div className="p-6 border-b" style={{ borderColor: colors.border }}>
          <div className="flex items-center justify-between mb-4">
            <h2 
              className="text-xl font-medium"
              style={{ color: colors.textPrimary }}
            >
              Live Encounter
            </h2>
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
              <div 
                className="text-sm font-medium"
                style={{ color: colors.textTertiary }}
              >
                ID: {selectedPatient.displayId}
              </div>
            </div>
          </div>
          
          <p 
            className="text-sm font-light"
            style={{ color: colors.textSecondary }}
          >
            {selectedPatient.name} • {selectedPatient.age}/{selectedPatient.gender}
          </p>
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
      <div className="p-6 border-b" style={{ borderColor: colors.border }}>
        <div className="flex items-center justify-between mb-4">
          <h2 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Live Encounter
          </h2>
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
            
            <div 
              className="text-sm font-medium"
              style={{ color: colors.textTertiary }}
            >
              ID: {selectedPatient.displayId}
            </div>

            {/* Consultation Management Buttons */}
            {selectedPatient.queueId && (
              <div className="flex items-center gap-2 ml-4">
                {selectedPatient.status === 'waiting' && (
                  <button
                    onClick={handleStartConsultation}
                    disabled={consultationLoading}
                    className="flex items-center gap-2 px-3 py-1 rounded-lg text-sm font-medium transition-colors hover:opacity-80 disabled:opacity-50"
                    style={{
                      backgroundColor: colors.success,
                      color: colors.surface
                    }}
                  >
                    <FiPlay size={14} />
                    {consultationLoading ? 'Starting...' : 'Start'}
                  </button>
                )}
                
                {(selectedPatient.status === 'with-nurse' || selectedPatient.status === 'ready') && (
                  <button
                    onClick={handleCompleteConsultation}
                    disabled={consultationLoading}
                    className="flex items-center gap-2 px-3 py-1 rounded-lg text-sm font-medium transition-colors hover:opacity-80 disabled:opacity-50"
                    style={{
                      backgroundColor: colors.primary,
                      color: colors.surface
                    }}
                  >
                    <FiCheckCircle size={14} />
                    {consultationLoading ? 'Completing...' : 'Complete'}
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
        
        <p 
          className="text-sm font-light"
          style={{ color: colors.textSecondary }}
        >
          {selectedPatient.name} • {selectedPatient.age}/{selectedPatient.gender}
        </p>
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
            <div className="flex items-center gap-3 mb-6">
              <div>
                <h3 
                  className="text-lg font-medium"
                  style={{ color: colors.textPrimary }}
                >
                  AI Scribe - SOAP Note
                </h3>
                <p 
                  className="text-sm"
                  style={{ color: colors.textSecondary }}
                >
                  Latest consultation analysis
                </p>
              </div>
            </div>

            {/* Raw Transcript - Only show if available */}
            {liveEncounterData.scribeData.rawTranscript && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3">
                  <FiVolume2 size={16} style={{ color: colors.textSecondary }} />
                  <h4 
                    className="text-sm font-medium"
                    style={{ color: colors.textSecondary }}
                  >
                    Raw Audio Transcript
                  </h4>
                </div>
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

            {/* SOAP Note - Only show real data */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 
                  className="text-sm font-medium"
                  style={{ color: colors.textPrimary }}
                >
                  Structured SOAP Note
                </h4>
              </div>
              
              {hasValidSoapNote ? (
                <div 
                  className="p-4 rounded-xl border space-y-4"
                  style={{ 
                    backgroundColor: colors.surface,
                    borderColor: colors.border
                  }}
                >
                  {soapNote.subjective && (
                    <div>
                      <h5 
                        className="text-xs font-medium mb-2 uppercase tracking-wider"
                        style={{ color: colors.primary }}
                      >
                        Subjective
                      </h5>
                      <p 
                        className="text-sm leading-relaxed"
                        style={{ color: colors.textPrimary }}
                      >
                        {soapNote.subjective}
                      </p>
                    </div>
                  )}

                  {soapNote.objective && (
                    <div>
                      <h5 
                        className="text-xs font-medium mb-2 uppercase tracking-wider"
                        style={{ color: colors.accent }}
                      >
                        Objective
                      </h5>
                      <p 
                        className="text-sm leading-relaxed"
                        style={{ color: colors.textPrimary }}
                      >
                        {soapNote.objective}
                      </p>
                    </div>
                  )}

                  {soapNote.assessment && (
                    <div>
                      <h5 
                        className="text-xs font-medium mb-2 uppercase tracking-wider"
                        style={{ color: colors.warning }}
                      >
                        Assessment
                      </h5>
                      <p 
                        className="text-sm leading-relaxed"
                        style={{ color: colors.textPrimary }}
                      >
                        {soapNote.assessment}
                      </p>
                    </div>
                  )}

                  {soapNote.plan && (
                    <div>
                      <h5 
                        className="text-xs font-medium mb-2 uppercase tracking-wider"
                        style={{ color: colors.success }}
                      >
                        Plan
                      </h5>
                      <p 
                        className="text-sm leading-relaxed"
                        style={{ color: colors.textPrimary }}
                      >
                        {soapNote.plan}
                      </p>
                    </div>
                  )}

                  {/* Show medications if available */}
                  {soapNote.medications && soapNote.medications.length > 0 && (
                    <div>
                      <h5 
                        className="text-xs font-medium mb-2 uppercase tracking-wider"
                        style={{ color: colors.error }}
                      >
                        Medications
                      </h5>
                      <div className="space-y-2">
                        {soapNote.medications.map((med, index) => (
                          <div 
                            key={index}
                            className="text-sm p-2 rounded"
                            style={{ 
                              backgroundColor: colors.surfaceSecondary,
                              color: colors.textPrimary 
                            }}
                          >
                            {med.name} - {med.dosage} ({med.frequency})
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
        {/* Historical SOAP Notes Timeline */}
        {timelineData && timelineData.timeline && timelineData.timeline.length > 0 && (
          <div className="mt-6 mb-6 px-6">
            <div className="flex items-center gap-2 mb-4">
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
                {timelineData.timeline.filter(entry => entry.type === 'note').length} records
              </span>
            </div>
            
            <div className="space-y-4">
              {timelineData.timeline
                .filter(entry => entry.type === 'note')
                .slice(0, 5) // Show only last 5 SOAP notes
                .map((entry, index) => {
                  const soapNote = entry.entry.soap_note || {};
                  return (
                    <div 
                      key={index}
                      className="p-4 rounded-xl border"
                      style={{ 
                        backgroundColor: colors.background,
                        borderColor: colors.border 
                      }}
                    >
                      <div className="flex justify-between items-start mb-3">
                        <div>
                          <h4 
                            className="font-medium text-sm"
                            style={{ color: colors.textPrimary }}
                          >
                            {entry.entry.chief_complaint || 'Medical Consultation'}
                          </h4>
                          {soapNote.language && soapNote.language !== 'Unknown' && (
                            <span 
                              className="text-xs px-2 py-1 rounded-full mt-1 inline-block"
                              style={{ 
                                backgroundColor: colors.accent + '20',
                                color: colors.accent 
                              }}
                            >
                              {soapNote.language}
                            </span>
                          )}
                        </div>
                        <div className="text-right">
                          <div 
                            className="text-xs"
                            style={{ color: colors.textTertiary }}
                          >
                            {new Date(entry.date).toLocaleDateString()} at {new Date(entry.date).toLocaleTimeString('en-US', {
                              hour: '2-digit',
                              minute: '2-digit',
                              hour12: true
                            })}
                          </div>
                        </div>
                      </div>

                      {/* Compact SOAP Display */}
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                        {soapNote.subjective && soapNote.subjective !== 'No symptoms recorded' && (
                          <div>
                            <span 
                              className="font-medium text-xs"
                              style={{ color: colors.primary }}
                            >
                              S: 
                            </span>
                            <span 
                              className="ml-2"
                              style={{ color: colors.textPrimary }}
                            >
                              {soapNote.subjective.substring(0, 80)}
                              {soapNote.subjective.length > 80 ? '...' : ''}
                            </span>
                          </div>
                        )}
                        
                        {soapNote.objective && soapNote.objective !== 'No examination findings' && (
                          <div>
                            <span 
                              className="font-medium text-xs"
                              style={{ color: colors.accent }}
                            >
                              O: 
                            </span>
                            <span 
                              className="ml-2"
                              style={{ color: colors.textPrimary }}
                            >
                              {soapNote.objective.substring(0, 80)}
                              {soapNote.objective.length > 80 ? '...' : ''}
                            </span>
                          </div>
                        )}
                        
                        {soapNote.assessment && soapNote.assessment !== 'No assessment' && (
                          <div>
                            <span 
                              className="font-medium text-xs"
                              style={{ color: colors.warning }}
                            >
                              A: 
                            </span>
                            <span 
                              className="ml-2"
                              style={{ color: colors.textPrimary }}
                            >
                              {soapNote.assessment.substring(0, 80)}
                              {soapNote.assessment.length > 80 ? '...' : ''}
                            </span>
                          </div>
                        )}
                        
                        {soapNote.plan && soapNote.plan !== 'No plan recorded' && (
                          <div>
                            <span 
                              className="font-medium text-xs"
                              style={{ color: colors.success }}
                            >
                              P: 
                            </span>
                            <span 
                              className="ml-2"
                              style={{ color: colors.textPrimary }}
                            >
                              {soapNote.plan.substring(0, 80)}
                              {soapNote.plan.length > 80 ? '...' : ''}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Audio file indicator */}
                      {entry.entry.audio_file && (
                        <div className="mt-3 pt-3 border-t" style={{ borderColor: colors.border }}>
                          <span 
                            className="text-xs flex items-center gap-1"
                            style={{ color: colors.textTertiary }}
                          >
                            <FiVolume2 size={12} />
                            Audio: {entry.entry.audio_file}
                          </span>
                        </div>
                      )}
                    </div>
                  );
                })}
            </div>
            
            {timelineData.timeline.filter(entry => entry.type === 'note').length > 5 && (
              <div className="mt-4 text-center">
                <p 
                  className="text-sm"
                  style={{ color: colors.textSecondary }}
                >
                  Showing 5 most recent SOAP notes • {timelineData.timeline.filter(entry => entry.type === 'note').length - 5} more available
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default LiveEncounter;