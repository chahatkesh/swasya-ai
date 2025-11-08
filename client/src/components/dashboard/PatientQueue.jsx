import React, { useState, useCallback } from 'react';
import { colors } from '../../utils/colors';
import { FiUser, FiClock, FiCheck, FiPlay, FiActivity, FiChevronRight, FiChevronDown } from 'react-icons/fi';
import { RiNurseFill, RiStethoscopeFill } from 'react-icons/ri';
import { MdTimeline } from 'react-icons/md';
import { queueAPI } from '../../utils/api';

const PatientQueue = ({ patients, selectedPatient, onPatientSelect, onQueueUpdate }) => {
  const [consultationLoading, setConsultationLoading] = useState({});
  const getStatusConfig = (status) => {
    switch (status) {
      case 'waiting':
        return {
          color: colors.textTertiary,
          bgColor: `${colors.textTertiary}20`,
          icon: FiClock,
          label: 'With Nurse',
          pulse: false,
          description: 'Patient is currently with nurse for data collection'
        };
      case 'nurse_completed':
        return {
          color: colors.primary,
          bgColor: `${colors.primary}20`,
          icon: MdTimeline,
          label: 'Ready',
          pulse: false,
          description: 'Nurse completed, ready for doctor consultation'
        };
      case 'ready_for_doctor':
        return {
          color: colors.success,
          bgColor: `${colors.success}20`,
          icon: RiStethoscopeFill,
          label: 'Ready for Doctor',
          pulse: false,
          description: 'Medical timeline ready, patient waiting for consultation'
        };
      case 'in_consultation':
        return {
          color: colors.primary,
          bgColor: `${colors.primary}20`,
          icon: FiActivity,
          label: 'In Consultation',
          pulse: true,
          description: 'Currently in consultation with doctor'
        };
      case 'completed':
        return {
          color: colors.success,
          bgColor: `${colors.success}20`,
          icon: FiCheck,
          label: 'Completed',
          pulse: false,
          description: 'Consultation completed successfully'
        };
      // Legacy status support
      case 'with-nurse':
        return {
          color: colors.warning,
          bgColor: `${colors.warning}20`,
          icon: RiNurseFill,
          label: 'With Nurse',
          pulse: true,
          description: 'Currently with nurse'
        };
      case 'ready':
        return {
          color: colors.success,
          bgColor: `${colors.success}20`,
          icon: FiUser,
          label: 'Ready',
          pulse: false,
          description: 'Ready for consultation'
        };
      default:
        return {
          color: colors.textTertiary,
          bgColor: `${colors.textTertiary}20`,
          icon: FiClock,
          label: 'Unknown',
          pulse: false,
          description: 'Unknown status'
        };
    }
  };

    // Consultation management functions (Doctor actions only)
  const handleStartConsultation = useCallback(async (patient) => {
    if (!patient.queueId) {
      console.error('No queue ID available for patient');
      return;
    }

    try {
      setConsultationLoading(prev => ({ ...prev, [patient.id]: true }));
      await queueAPI.startConsultation(patient.queueId);
      console.log('✅ Consultation started for queue:', patient.queueId);
      
      // Refresh the queue data
      if (onQueueUpdate) {
        onQueueUpdate();
      }
      
    } catch (error) {
      console.error('Error starting consultation:', error);
      alert('Failed to start consultation. Please try again.');
    } finally {
      setConsultationLoading(prev => ({ ...prev, [patient.id]: false }));
    }
  }, [onQueueUpdate]);

  const handleCompleteConsultation = useCallback(async (patient) => {
    if (!patient.queueId) {
      console.error('No queue ID available for patient');
      return;
    }

    try {
      setConsultationLoading(prev => ({ ...prev, [patient.id]: true }));
      await queueAPI.completeConsultation(patient.queueId);
      console.log('✅ Consultation completed for queue:', patient.queueId);
      
      // Refresh the queue data
      if (onQueueUpdate) {
        onQueueUpdate();
      }
      
    } catch (error) {
      console.error('Error completing consultation:', error);
      alert('Failed to complete consultation. Please try again.');
    } finally {
      setConsultationLoading(prev => ({ ...prev, [patient.id]: false }));
    }
  }, [onQueueUpdate]);

  // Get action button for current status (Doctor actions only)
  const getActionButton = (patient) => {
    const isLoading = consultationLoading[patient.id];
    
    // Debug logging
    console.log('Patient status for action button:', {
      name: patient.name || patient.patientName,
      status: patient.status,
      queueId: patient.queueId,
      patientId: patient.id || patient.patientId
    });
    
    switch (patient.status) {
      case 'waiting':
        // No action for doctor - nurse handles this in mobile app
        return null; // Don't show redundant action button since status already shows "With Nurse"
      
      case 'nurse_completed':
        // Doctor can start consultation directly (API allows this)
        return (
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleStartConsultation(patient);
            }}
            disabled={isLoading}
            className="px-3 py-1 text-xs rounded-full transition-colors flex items-center gap-1"
            style={{
              backgroundColor: colors.primary,
              color: colors.surface
            }}
          >
            <FiPlay size={12} />
            {isLoading ? 'Starting...' : 'Start'}
          </button>
        );
      
      case 'ready_for_doctor':
        // Doctor can start consultation
        return (
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleStartConsultation(patient);
            }}
            disabled={isLoading}
            className="px-3 py-1 text-xs rounded-full transition-colors flex items-center gap-1"
            style={{
              backgroundColor: colors.primary,
              color: colors.surface
            }}
          >
            <FiPlay size={12} />
            {isLoading ? 'Starting...' : 'Start'}
          </button>
        );
      
      case 'in_consultation':
        // Doctor can complete consultation
        return (
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleCompleteConsultation(patient);
            }}
            disabled={isLoading}
            className="px-3 py-1 text-xs rounded-full transition-colors flex items-center gap-1"
            style={{
              backgroundColor: colors.success,
              color: colors.surface
            }}
          >
            <FiCheck size={12} />
            {isLoading ? 'Completing...' : 'Done'}
          </button>
        );
      
      default:
        return (
          <div 
            className="text-xs px-2 py-1 rounded-full"
            style={{
              backgroundColor: colors.textTertiary + '20',
              color: colors.textTertiary
            }}
          >
            {patient.status || 'Unknown'}
          </div>
        );
    }
  };

  // Patient sorting function - API-driven order with new statuses
  // Updated to place active conversation candidates on top (in_consultation, ready_for_doctor)
  const getSortedPatients = useCallback((patients) => {
    return [...patients].sort((a, b) => {
      // Priority order: in_consultation -> ready_for_doctor -> nurse_completed -> waiting -> completed
      const statusOrder = {
        'in_consultation': 1,
        'ready_for_doctor': 2,
        'nurse_completed': 3,
        'waiting': 4,
        'completed': 5,
        // Legacy support mapping
        'with-nurse': 3,
        'ready': 2,
        'in_progress': 1
      };

      const aOrder = statusOrder[a.status] || 99;
      const bOrder = statusOrder[b.status] || 99;

      if (aOrder !== bOrder) {
        return aOrder - bOrder;
      }

      // Within same status, sort by startedAt (if present) then by check-in/added time (earlier first)
      const aTime = new Date(a.startedAt || a.lastUpdated || a.addedAt || 0);
      const bTime = new Date(b.startedAt || b.lastUpdated || b.addedAt || 0);
      return aTime - bTime;
    });
  }, []);

  // Local UI state: whether to show completed patients
  const [showCompleted, setShowCompleted] = useState(false);



  // Pre-compute sorted lists for rendering
  const sortedPatients = getSortedPatients(patients || []);
  const activePatients = sortedPatients.filter(p => p.status !== 'completed');
  const completedPatients = sortedPatients.filter(p => p.status === 'completed');

  // Render a patient card (reusable) - Compact Professional Design
  const renderPatientCard = (patient) => {
    const statusConfig = getStatusConfig(patient.status);
    const StatusIcon = statusConfig.icon;
    const isSelected = selectedPatient?.id === patient.id;

    // Calculate queue position only for waiting patients
    const waitingPatients = sortedPatients.filter(p => p.status === 'waiting');
    const queuePosition = patient.status === 'waiting' ? 
      waitingPatients.findIndex(p => p.id === patient.id) + 1 : null;

    return (
      <div
        key={patient.id}
        className={`
          relative p-3 rounded-lg border transition-all duration-150
          cursor-pointer hover:shadow-sm
          ${isSelected ? 'ring-2' : ''}
        `}
        style={{
          backgroundColor: isSelected ? colors.primary10 : colors.background,
          borderColor: isSelected ? colors.primary : colors.border
        }}
        onClick={() => onPatientSelect(patient)}
      >
        {/* Two Line Layout */}
        <div className="space-y-2">
          {/* Line 1: Name + Queue Position + Status + Action */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 flex-1 min-w-0">
              {/* Status Icon */}
              <div 
                className={`
                  w-6 h-6 rounded-md flex items-center justify-center shrink-0
                  ${statusConfig.pulse ? 'animate-pulse' : ''}
                `}
                style={{ backgroundColor: statusConfig.bgColor }}
              >
                <StatusIcon 
                  size={14} 
                  style={{ color: statusConfig.color }}
                />
              </div>
              
              {/* Patient Name */}
              <h3 
                className="font-semibold text-sm truncate"
                style={{ color: colors.textPrimary }}
              >
                {patient.name || patient.patientName}
              </h3>
              
              {/* Queue Position Badge */}
              {queuePosition && (
                <span 
                  className="text-xs font-bold px-1.5 py-0.5 rounded shrink-0"
                  style={{
                    backgroundColor: colors.primary,
                    color: colors.surface
                  }}
                >
                  #{patient.tokenNumber || queuePosition}
                </span>
              )}
            </div>

            {/* Right: Status + Action */}
            <div className="flex items-center gap-2 shrink-0">
              {/* Status Badge */}
              <div 
                className="text-xs font-medium px-2 py-1 rounded"
                style={{
                  backgroundColor: statusConfig.bgColor,
                  color: statusConfig.color
                }}
              >
                {statusConfig.label}
              </div>
              
              {/* Action Button */}
              {getActionButton(patient)}
            </div>
          </div>

          {/* Line 2: Full UHID */}
          <div className="flex items-center text-xs ml-8">
            <span 
              className="truncate"
              style={{ color: colors.textTertiary }}
              title={`UHID: ${patient.displayId || patient.patientId}`}
            >
              UHID: {patient.displayId || patient.patientId || 'N/A'}
            </span>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="h-full flex flex-col" style={{ backgroundColor: colors.surface }}>
      {/* Header */}
      <div className="p-6 border-b" style={{ borderColor: colors.border }}>
        <div className="flex items-center justify-between mb-4">
          <h2 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Patient Queue
          </h2>
          <div 
            className="text-sm font-medium px-3 py-1 rounded-full"
            style={{ 
              backgroundColor: colors.primary20,
              color: colors.primary 
            }}
          >
            {patients.length} patients
          </div>
        </div>
      </div>

      {/* Patient List */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-4 space-y-3">
          {/* Completed patients toggle - Notion Style */}
          {completedPatients.length > 0 && (
            <div>
              <div 
                className="flex items-center gap-2 p-2 rounded-lg cursor-pointer transition-all duration-200 hover:bg-opacity-50"
                style={{
                  backgroundColor: 'transparent',
                  ':hover': {
                    backgroundColor: colors.textTertiary + '10'
                  }
                }}
                onClick={() => setShowCompleted(prev => !prev)}
              >
                {/* Chevron Icon */}
                <div className="transition-transform duration-200" style={{ 
                  transform: showCompleted ? 'rotate(0deg)' : 'rotate(0deg)' 
                }}>
                  {showCompleted ? (
                    <FiChevronDown 
                      size={16} 
                      style={{ color: colors.textSecondary }}
                    />
                  ) : (
                    <FiChevronRight 
                      size={16} 
                      style={{ color: colors.textSecondary }}
                    />
                  )}
                </div>
                
                {/* Label */}
                <div 
                  className="font-medium text-sm select-none"
                  style={{ color: colors.textPrimary }}
                >
                  Completed ({completedPatients.length})
                </div>
              </div>

              {/* Collapsible Content */}
              {showCompleted && (
                <div className="ml-6 mt-2 space-y-2 animate-fadeIn">
                  {completedPatients.map((patient) => {
                    const statusConfig = getStatusConfig(patient.status);
                    const StatusIcon = statusConfig.icon;
                    const isSelected = selectedPatient?.id === patient.id;
                    return (
                      <div
                        key={patient.id}
                        className={`relative p-3 rounded-xl border transition-all duration-150 cursor-pointer ${isSelected ? 'ring-2' : ''}`}
                        style={{
                          backgroundColor: isSelected ? colors.primary10 : colors.background,
                          borderColor: isSelected ? colors.primary : colors.border,
                          borderLeft: `3px solid ${colors.success}`
                        }}
                        onClick={() => onPatientSelect(patient)}
                      >
                        <div className="flex items-center gap-3">
                          <div 
                            className="w-8 h-8 rounded-md flex items-center justify-center"
                            style={{ backgroundColor: statusConfig.bgColor }}
                          >
                            <StatusIcon size={16} style={{ color: statusConfig.color }} />
                          </div>
                          <div className="flex-1">
                            <div 
                              className="font-medium text-sm"
                              style={{ color: colors.textPrimary }}
                            >
                              {patient.name || patient.patientName}
                            </div>
                            <div 
                              className="text-xs mt-1"
                              style={{ color: colors.textSecondary }}
                            >
                              ID: {patient.displayId || patient.patientId}
                              {patient.completedAt && (
                                <span className="ml-2">
                                  • Completed {new Date(patient.completedAt).toLocaleTimeString('en-US', {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                    hour12: true
                                  })}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {activePatients.map(patient => renderPatientCard(patient))}
        </div>
      </div>
    </div>
  );
};

export default PatientQueue;