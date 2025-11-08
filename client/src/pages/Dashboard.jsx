import React, { useState, useEffect } from 'react';
import { colors } from '../utils/colors';
import PatientQueue from '../components/dashboard/PatientQueue';
import LiveEncounter from '../components/dashboard/LiveEncounter';
import PatientHistory from '../components/dashboard/PatientHistory';
import { 
  mockPatients, 
  mockEncounterData, 
  mockPatientHistory, 
  mockAIAnalysis 
} from '../data/mockData';
import { FiRefreshCw, FiSettings, FiLogOut } from 'react-icons/fi';

const Dashboard = () => {
  const [patients, setPatients] = useState(mockPatients);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [encounterData, setEncounterData] = useState(null);
  const [patientHistory, setPatientHistory] = useState(null);
  const [aiAnalysis, setAiAnalysis] = useState(null);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  // Simulate real-time updates
  useEffect(() => {
    const interval = setInterval(() => {
      setPatients(prevPatients => 
        prevPatients.map(patient => ({
          ...patient,
          lastUpdated: new Date()
        }))
      );
      setLastRefresh(new Date());
    }, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, []);

  const handlePatientSelect = (patient) => {
    setSelectedPatient(patient);
    
    // Load encounter data if patient is ready
    if (patient.status === 'ready' || patient.status === 'completed') {
      setEncounterData({
        ...mockEncounterData,
        patientId: patient.id
      });
      setPatientHistory({
        ...mockPatientHistory,
        patientId: patient.id,
        personalInfo: {
          ...mockPatientHistory.personalInfo,
          name: patient.name,
          age: patient.age,
          gender: patient.gender === 'M' ? 'Male' : 'Female',
          uhid: patient.uhid,
          contact: patient.mobile
        }
      });
      setAiAnalysis(mockAIAnalysis);
    } else {
      setEncounterData(null);
      setPatientHistory(null);
      setAiAnalysis(null);
    }
  };

  const handleRefresh = () => {
    setLastRefresh(new Date());
    // In a real app, this would fetch fresh data from the API
    console.log('Refreshing dashboard data...');
  };

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    });
  };

  return (
    <div 
      className="h-screen flex flex-col"
      style={{ backgroundColor: colors.background }}
    >
      {/* Top Navigation Bar */}
      <div 
        className="h-16 flex items-center justify-between px-6 border-b"
        style={{ 
          backgroundColor: colors.surface,
          borderColor: colors.border 
        }}
      >
        <div className="flex items-center gap-6">
          <h1 
            className="text-xl font-medium"
            style={{ color: colors.textPrimary }}
          >
            Doctor's Dashboard
          </h1>
          <div className="flex items-center gap-4">
            <span 
              className="text-sm"
              style={{ color: colors.textSecondary }}
            >
              Swasya AI
            </span>
            <div 
              className="h-4 w-px"
              style={{ backgroundColor: colors.border }}
            />
            <span 
              className="text-sm font-medium"
              style={{ color: colors.primary }}
            >
              PHC Clinic Dashboard
            </span>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right">
            <div 
              className="text-sm font-medium"
              style={{ color: colors.textPrimary }}
            >
              Dr. Sarah Patel
            </div>
            <div 
              className="text-xs"
              style={{ color: colors.textSecondary }}
            >
              Last refresh: {formatTime(lastRefresh)}
            </div>
          </div>
          
          <button
            onClick={handleRefresh}
            className="p-2 rounded-lg transition-colors duration-200 hover:bg-opacity-80"
            style={{ backgroundColor: colors.primary20 }}
            title="Refresh dashboard"
          >
            <FiRefreshCw size={16} style={{ color: colors.primary }} />
          </button>
        </div>
      </div>

      {/* Main Dashboard Layout - 3 Column Cockpit */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* Column 1: Patient Queue (Left) */}
        <div 
          className="w-80 border-r shrink-0"
          style={{ borderColor: colors.border }}
        >
          <PatientQueue
            patients={patients}
            selectedPatient={selectedPatient}
            onPatientSelect={handlePatientSelect}
          />
        </div>

        {/* Column 2: Live Encounter (Center) */}
        <div className="flex-1 min-w-0">
          <LiveEncounter
            encounterData={encounterData}
            selectedPatient={selectedPatient}
          />
        </div>

        {/* Column 3: Patient History & AI Analysis (Right) */}
        <div 
          className="w-96 border-l shrink-0"
          style={{ borderColor: colors.border }}
        >
          <PatientHistory
            patientHistory={patientHistory}
            aiAnalysis={aiAnalysis}
            selectedPatient={selectedPatient}
          />
        </div>
      </div>

      {/* Status Bar */}
      <div 
        className="h-8 flex items-center justify-between px-6 text-xs border-t"
        style={{ 
          backgroundColor: colors.surfaceSecondary,
          borderColor: colors.border,
          color: colors.textSecondary 
        }}
      >
        <div className="flex items-center gap-4">
          <span>Status: Online</span>
          <span>Queue: {patients.filter(p => p.status !== 'completed').length} active</span>
          <span>Ready: {patients.filter(p => p.status === 'ready').length}</span>
        </div>
        <div className="flex items-center gap-4">
          <span>AI Analysis: Active</span>
          <span>Version: 1.0.0</span>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
