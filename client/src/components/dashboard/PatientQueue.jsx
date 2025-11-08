import React from 'react';
import { colors } from '../../utils/colors';
import { FiUser, FiClock, FiCheck } from 'react-icons/fi';
import { RiNurseFill } from 'react-icons/ri';

const PatientQueue = ({ patients, selectedPatient, onPatientSelect }) => {
  const getStatusConfig = (status) => {
    switch (status) {
      case 'waiting':
        return {
          color: colors.textTertiary,
          bgColor: `${colors.textTertiary}20`,
          icon: FiClock,
          label: 'Waiting',
          pulse: false
        };
      case 'with-nurse':
        return {
          color: colors.warning,
          bgColor: `${colors.warning}20`,
          icon: RiNurseFill,
          label: 'With Nurse',
          pulse: true
        };
      case 'ready':
        return {
          color: colors.success,
          bgColor: `${colors.success}20`,
          icon: FiUser,
          label: 'Ready for Doctor',
          pulse: false
        };
      case 'completed':
        return {
          color: colors.primary,
          bgColor: `${colors.primary}20`,
          icon: FiCheck,
          label: 'Completed',
          pulse: false
        };
      default:
        return {
          color: colors.textTertiary,
          bgColor: `${colors.textTertiary}20`,
          icon: FiClock,
          label: 'Unknown',
          pulse: false
        };
    }
  };



  const getTimeAgo = (date) => {
    const minutes = Math.floor((new Date() - new Date(date)) / 60000);
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    return `${hours}h ${minutes % 60}m ago`;
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
        
        <p 
          className="text-sm font-light"
          style={{ color: colors.textSecondary }}
        >
          Live status updates from the clinic floor
        </p>
      </div>

      {/* Patient List */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-4 space-y-3">
          {patients.map((patient) => {
            const statusConfig = getStatusConfig(patient.status);
            const StatusIcon = statusConfig.icon;
            const isSelected = selectedPatient?.id === patient.id;
            const isClickable = patient.status === 'ready' || patient.status === 'completed';

            return (
              <div
                key={patient.id}
                className={`
                  relative p-4 rounded-2xl border transition-all duration-200
                  ${isClickable ? 'cursor-pointer hover:scale-[1.02]' : 'cursor-default'}
                  ${isSelected ? 'ring-2' : ''}
                `}
                style={{
                  backgroundColor: isSelected ? colors.primary10 : colors.background,
                  borderColor: isSelected ? colors.primary : colors.border,
                  ringColor: isSelected ? colors.primary : 'transparent'
                }}
                onClick={() => isClickable && onPatientSelect(patient)}
              >
                {/* Status Indicator */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div 
                      className={`
                        w-10 h-10 rounded-xl flex items-center justify-center
                        ${statusConfig.pulse ? 'animate-pulse' : ''}
                      `}
                      style={{ backgroundColor: statusConfig.bgColor }}
                    >
                      <StatusIcon 
                        size={18} 
                        style={{ color: statusConfig.color }}
                      />
                    </div>
                    
                    <div>
                      <h3 
                        className="font-medium text-base"
                        style={{ color: colors.textPrimary }}
                      >
                        {patient.name}
                      </h3>
                      <p 
                        className="text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        {patient.age}/{patient.gender} • ID: {patient.displayId}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <div 
                      className="text-xs font-medium px-2 py-1 rounded-full"
                      style={{
                        backgroundColor: statusConfig.bgColor,
                        color: statusConfig.color
                      }}
                    >
                      {statusConfig.label}
                    </div>
                  </div>
                </div>

                {/* Patient Details */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span 
                      className="text-sm"
                      style={{ color: colors.textSecondary }}
                    >
                      Check-in:
                    </span>
                    <span 
                      className="text-sm font-medium"
                      style={{ color: colors.textPrimary }}
                    >
                      {patient.checkInTime}
                    </span>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span 
                      className="text-sm"
                      style={{ color: colors.textSecondary }}
                    >
                      Last update:
                    </span>
                    <span 
                      className="text-sm font-medium"
                      style={{ color: colors.textTertiary }}
                    >
                      {getTimeAgo(patient.lastUpdated)}
                    </span>
                  </div>

                  {patient.nurseAssigned && (
                    <div className="flex justify-between items-center">
                      <span 
                        className="text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        With:
                      </span>
                      <span 
                        className="text-sm font-medium"
                        style={{ color: colors.warning }}
                      >
                        {patient.nurseAssigned}
                      </span>
                    </div>
                  )}

                  {patient.completedTime && (
                    <div className="flex justify-between items-center">
                      <span 
                        className="text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        Completed:
                      </span>
                      <span 
                        className="text-sm font-medium"
                        style={{ color: colors.success }}
                      >
                        {patient.completedTime}
                      </span>
                    </div>
                  )}
                </div>

                {/* Action Hint */}
                {patient.status === 'ready' && (
                  <div className="mt-3 pt-3 border-t" style={{ borderColor: colors.border }}>
                    <p 
                      className="text-xs font-medium text-center"
                      style={{ color: colors.success }}
                    >
                      ← Click to view encounter data
                    </p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Queue Summary */}
      <div className="p-4 border-t" style={{ borderColor: colors.border }}>
        <div className="grid grid-cols-2 gap-4 text-center">
          <div>
            <div 
              className="text-lg font-medium"
              style={{ color: colors.primary }}
            >
              {patients.filter(p => p.status === 'ready').length}
            </div>
            <div 
              className="text-xs"
              style={{ color: colors.textSecondary }}
            >
              Ready
            </div>
          </div>
          <div>
            <div 
              className="text-lg font-medium"
              style={{ color: colors.warning }}
            >
              {patients.filter(p => p.status === 'with-nurse').length}
            </div>
            <div 
              className="text-xs"
              style={{ color: colors.textSecondary }}
            >
              In Progress
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PatientQueue;