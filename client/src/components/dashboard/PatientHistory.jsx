import React from 'react';
import { colors } from '../../utils/colors';
import { 
  FiUser, 
  FiCalendar, 
  FiHeart, 
  FiAlertTriangle, 
  FiAlertCircle,
  FiActivity,
  FiShield
} from 'react-icons/fi';

const PatientHistory = ({ patientHistory, aiAnalysis, selectedPatient }) => {
  if (!selectedPatient || !patientHistory) {
    return (
      <div className="h-full flex flex-col items-center justify-center" style={{ backgroundColor: colors.surfaceSecondary }}>
        <div className="text-center space-y-4 max-w-md">
          <div 
            className="w-20 h-20 rounded-full mx-auto flex items-center justify-center"
            style={{ backgroundColor: colors.primary20 }}
          >
            <FiUser size={32} style={{ color: colors.primary }} />
          </div>
          <h3 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Patient History
          </h3>
          <p 
            className="text-base font-light"
            style={{ color: colors.textSecondary }}
          >
            Select a patient to view their complete medical history and AI analysis.
          </p>
        </div>
      </div>
    );
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <div className="h-full flex flex-col" style={{ backgroundColor: colors.surface }}>
      {/* Critical Alerts Section - Always at top */}
      {aiAnalysis && (aiAnalysis.drugInteractions?.length > 0 || aiAnalysis.symptomAlerts?.length > 0) && (
        <div className="p-4 space-y-3">
          {/* Critical Drug Interaction Alert */}
          {aiAnalysis.drugInteractions?.map((interaction, index) => (
            <div
              key={index}
              className="p-4 rounded-xl border-2"
              style={{
                backgroundColor: interaction.severity === 'critical' ? '#FEF2F2' : '#FFF7ED',
                borderColor: interaction.severity === 'critical' ? '#DC2626' : '#F59E0B',
                borderStyle: 'solid'
              }}
            >
              <div className="flex items-start gap-3">
                <FiAlertTriangle 
                  size={20} 
                  style={{ 
                    color: interaction.severity === 'critical' ? '#DC2626' : '#F59E0B',
                    flexShrink: 0,
                    marginTop: '2px'
                  }} 
                />
                <div>
                  <h4 
                    className="font-medium text-sm mb-2"
                    style={{ color: interaction.severity === 'critical' ? '#DC2626' : '#F59E0B' }}
                  >
                    🚨 CRITICAL DRUG INTERACTION
                  </h4>
                  <p 
                    className="text-sm font-medium mb-2"
                    style={{ color: colors.textPrimary }}
                  >
                    Patient is on '{interaction.interaction.drug1}' (History) and '{interaction.interaction.drug2}' (New Scan). High Bleed Risk.
                  </p>
                  <p 
                    className="text-xs"
                    style={{ color: colors.textSecondary }}
                  >
                    {interaction.interaction.recommendation}
                  </p>
                </div>
              </div>
            </div>
          ))}

          {/* Symptom Alert */}
          {aiAnalysis.symptomAlerts?.map((alert, index) => (
            <div
              key={index}
              className="p-4 rounded-xl border-2"
              style={{
                backgroundColor: '#FFF7ED',
                borderColor: '#F59E0B',
                borderStyle: 'solid'
              }}
            >
              <div className="flex items-start gap-3">
                <FiAlertCircle 
                  size={20} 
                  style={{ 
                    color: '#F59E0B',
                    flexShrink: 0,
                    marginTop: '2px'
                  }} 
                />
                <div>
                  <h4 
                    className="font-medium text-sm mb-2"
                    style={{ color: '#F59E0B' }}
                  >
                    ⚠ HIGH-RISK SYMPTOM
                  </h4>
                  <p 
                    className="text-sm font-medium mb-2"
                    style={{ color: colors.textPrimary }}
                  >
                    '{alert.alert.symptom}' reported by Scribe. Patient is on '{alert.alert.relatedMedication}'.
                  </p>
                  <p 
                    className="text-xs"
                    style={{ color: colors.textSecondary }}
                  >
                    {alert.alert.recommendation}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Header */}
      <div className="p-6 border-b" style={{ borderColor: colors.border }}>
        <div className="flex items-center justify-between mb-4">
          <h2 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Patient History
          </h2>
          <div className="flex items-center gap-2">
            <FiShield size={16} style={{ color: colors.success }} />
            <span 
              className="text-sm font-medium"
              style={{ color: colors.success }}
            >
              AI Analysis Active
            </span>
          </div>
        </div>
        
        <div className="space-y-2">
          <h3 
            className="text-lg font-medium"
            style={{ color: colors.textPrimary }}
          >
            {patientHistory.personalInfo.name}
          </h3>
          <p 
            className="text-sm"
            style={{ color: colors.textSecondary }}
          >
            UHID: {patientHistory.personalInfo.uhid} • {patientHistory.personalInfo.age}yr {patientHistory.personalInfo.gender}
          </p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-6 space-y-6">
          
          {/* Allergies - Prominent Display */}
          {patientHistory.allergies && patientHistory.allergies.length > 0 && (
            <div 
              className="p-4 rounded-xl border-2"
              style={{ 
                backgroundColor: '#FEF2F2',
                borderColor: '#DC2626' 
              }}
            >
              <div className="flex items-center gap-3 mb-3">
                <FiAlertTriangle size={18} style={{ color: '#DC2626' }} />
                <h3 
                  className="font-medium"
                  style={{ color: '#DC2626' }}
                >
                  ALLERGIES
                </h3>
              </div>
              <div className="space-y-2">
                {patientHistory.allergies.map((allergy, index) => (
                  <div key={index} className="flex justify-between items-center">
                    <span 
                      className="font-medium text-sm"
                      style={{ color: colors.textPrimary }}
                    >
                      {allergy.allergen}
                    </span>
                    <span 
                      className="text-xs px-2 py-1 rounded-full font-medium"
                      style={{
                        backgroundColor: '#DC2626',
                        color: '#FFFFFF'
                      }}
                    >
                      {allergy.severity} Risk
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Current Medications */}
          <div>
            <h3 
              className="text-lg font-medium mb-4 flex items-center gap-2"
              style={{ color: colors.textPrimary }}
            >
              <FiHeart size={18} style={{ color: colors.primary }} />
              Current Medications
            </h3>
            <div className="space-y-3">
              {patientHistory.currentMedications?.map((med, index) => (
                <div 
                  key={index}
                  className="p-3 rounded-xl border"
                  style={{ 
                    backgroundColor: colors.background,
                    borderColor: colors.border 
                  }}
                >
                  <div className="flex justify-between items-start mb-2">
                    <h4 
                      className="font-medium"
                      style={{ color: colors.textPrimary }}
                    >
                      {med.name}
                    </h4>
                    <span 
                      className="text-xs px-2 py-1 rounded-full"
                      style={{
                        backgroundColor: colors.primary20,
                        color: colors.primary
                      }}
                    >
                      Active
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <span style={{ color: colors.textSecondary }}>Dose: </span>
                      <span style={{ color: colors.textPrimary }}>{med.dosage}</span>
                    </div>
                    <div>
                      <span style={{ color: colors.textSecondary }}>Frequency: </span>
                      <span style={{ color: colors.textPrimary }}>{med.frequency}</span>
                    </div>
                  </div>
                  <div className="mt-2 text-xs">
                    <span style={{ color: colors.textSecondary }}>For: </span>
                    <span style={{ color: colors.textPrimary }}>{med.indication}</span>
                    <span style={{ color: colors.textTertiary }}> (Since {med.startDate})</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Latest Vitals */}
          <div>
            <h3 
              className="text-lg font-medium mb-4 flex items-center gap-2"
              style={{ color: colors.textPrimary }}
            >
              <FiActivity size={18} style={{ color: colors.accent }} />
              Latest Vitals
            </h3>
            <div 
              className="p-4 rounded-xl border"
              style={{ 
                backgroundColor: colors.background,
                borderColor: colors.border 
              }}
            >
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="space-y-2">
                  <div>
                    <span style={{ color: colors.textSecondary }}>Height: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.height}</span>
                  </div>
                  <div>
                    <span style={{ color: colors.textSecondary }}>Weight: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.weight}</span>
                  </div>
                  <div>
                    <span style={{ color: colors.textSecondary }}>BMI: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.bmi}</span>
                  </div>
                </div>
                <div className="space-y-2">
                  <div>
                    <span style={{ color: colors.textSecondary }}>BP: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.bloodPressure}</span>
                  </div>
                  <div>
                    <span style={{ color: colors.textSecondary }}>Heart Rate: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.heartRate}</span>
                  </div>
                  <div>
                    <span style={{ color: colors.textSecondary }}>Temperature: </span>
                    <span style={{ color: colors.textPrimary }}>{patientHistory.vitals.temperature}</span>
                  </div>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t" style={{ borderColor: colors.border }}>
                <span 
                  className="text-xs"
                  style={{ color: colors.textTertiary }}
                >
                  Last recorded: {patientHistory.vitals.lastRecorded}
                </span>
              </div>
            </div>
          </div>

          {/* Visit History Timeline */}
          <div>
            <h3 
              className="text-lg font-medium mb-4 flex items-center gap-2"
              style={{ color: colors.textPrimary }}
            >
              <FiCalendar size={18} style={{ color: colors.textSecondary }} />
              Visit History
            </h3>
            <div className="space-y-3">
              {patientHistory.visitHistory?.map((visit, index) => (
                <div 
                  key={index}
                  className="p-3 rounded-xl border"
                  style={{ 
                    backgroundColor: colors.background,
                    borderColor: colors.border 
                  }}
                >
                  <div className="flex justify-between items-start mb-2">
                    <h4 
                      className="font-medium text-sm"
                      style={{ color: colors.textPrimary }}
                    >
                      {visit.diagnosis}
                    </h4>
                    <span 
                      className="text-xs"
                      style={{ color: colors.textTertiary }}
                    >
                      {formatDate(visit.date)}
                    </span>
                  </div>
                  <p 
                    className="text-sm mb-2"
                    style={{ color: colors.textSecondary }}
                  >
                    {visit.notes}
                  </p>
                  <div className="text-xs">
                    <span style={{ color: colors.textSecondary }}>Dr: </span>
                    <span style={{ color: colors.textPrimary }}>{visit.doctor}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* AI Risk Assessment */}
          {aiAnalysis?.riskFactors && aiAnalysis.riskFactors.length > 0 && (
            <div>
              <h3 
                className="text-lg font-medium mb-4 flex items-center gap-2"
                style={{ color: colors.textPrimary }}
              >
                <FiShield size={18} style={{ color: colors.warning }} />
                AI Risk Assessment
              </h3>
              <div className="space-y-2">
                {aiAnalysis.riskFactors.map((risk, index) => (
                  <div 
                    key={index}
                    className="p-3 rounded-xl border"
                    style={{ 
                      backgroundColor: colors.background,
                      borderColor: colors.border 
                    }}
                  >
                    <div className="flex justify-between items-start mb-2">
                      <p 
                        className="text-sm font-medium"
                        style={{ color: colors.textPrimary }}
                      >
                        {risk.factor}
                      </p>
                      <span 
                        className="text-xs px-2 py-1 rounded-full"
                        style={{
                          backgroundColor: risk.riskLevel === 'High' ? colors.error + '20' : colors.warning + '20',
                          color: risk.riskLevel === 'High' ? colors.error : colors.warning
                        }}
                      >
                        {risk.riskLevel} Risk
                      </span>
                    </div>
                    <p 
                      className="text-xs"
                      style={{ color: colors.textSecondary }}
                    >
                      {risk.recommendation}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PatientHistory;