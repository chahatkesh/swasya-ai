import React, { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { colors } from '../utils/colors'
import PatientQueue from '../components/dashboard/PatientQueue'
import LiveEncounter from '../components/dashboard/LiveEncounter'
import PatientHistory from '../components/dashboard/PatientHistory'
import { patientsAPI, queueAPI, notesAPI, statsAPI, transformers, polling } from '../utils/api'
import { FiUsers, FiActivity, FiFileText, FiMenu } from 'react-icons/fi'

const Dashboard = () => {
  const navigate = useNavigate()
  const [patients, setPatients] = useState([])
  const [selectedPatient, setSelectedPatient] = useState(null)
  const [encounterData, setEncounterData] = useState(null)
  const [timelineData, setTimelineData] = useState(null)
  const [lastRefresh, setLastRefresh] = useState(new Date())
  const [loading, setLoading] = useState(true)
  const [dashboardStats, setDashboardStats] = useState(null)
  
  // Mobile state management
  const [activeTab, setActiveTab] = useState('queue') // 'queue', 'encounter', 'history'
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    })
  }

  const loadInitialData = useCallback(async () => {
    try {
      setLoading(true)
      
      const [patientsData, queueData, statsData] = await Promise.all([
        patientsAPI.getAll(),
        queueAPI.getCurrent(),
        statsAPI.get()
      ])

      const transformedPatients = patientsData.patients.map(transformers.transformPatient)
      const updatedPatients = updatePatientsWithQueueData(transformedPatients, queueData.queue)
      
      setPatients(updatedPatients)
      setDashboardStats(statsData)
      setLastRefresh(new Date())
    } catch (error) {
      console.error('Error loading initial data:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  const updatePatientsWithQueueData = (patients, queueEntries) => {
    return patients.map(patient => {
      const queueEntry = queueEntries.find(q => q.patient_id === patient.id)
      if (queueEntry) {
        const transformedQueue = transformers.transformQueueEntry(queueEntry)
        return {
          ...patient,
          status: transformedQueue.status,
          queueNumber: transformedQueue.tokenNumber,
          queueId: transformedQueue.queueId
        }
      }
      return patient
    })
  }

  const handleQueueUpdate = useCallback((queueData) => {
    setPatients(prevPatients => 
      updatePatientsWithQueueData(prevPatients, queueData.queue)
    )
    setLastRefresh(new Date())
  }, [])

  useEffect(() => {
    loadInitialData()
  }, [loadInitialData])

  useEffect(() => {
    const queueId = polling.startQueuePolling(handleQueueUpdate, 5000)
    return () => polling.stop(queueId)
  }, [handleQueueUpdate])

  const handlePatientSelect = async (patient) => {
    setSelectedPatient(patient)
    
    // On mobile, switch to encounter tab when patient is selected
    if (window.innerWidth < 1024) {
      setActiveTab('encounter')
    }
    
    // Load encounter data and timeline for the LiveEncounter component
    try {
      const [latestNote, timeline] = await Promise.all([
        notesAPI.getLatest(patient.id).catch(() => null),
        patientsAPI.getTimeline(patient.id).catch(() => null)
      ])

      // Load current encounter data if available
      if (latestNote && latestNote.success) {
        const encounterData = transformers.transformEncounterData(latestNote, patient.id)
        setEncounterData(encounterData)
      } else {
        setEncounterData(null)
      }

      // Load timeline data for historical SOAP notes
      if (timeline && timeline.success) {
        setTimelineData(timeline)
      } else {
        setTimelineData(null)
      }

    } catch (error) {
      console.error('Error loading patient encounter data:', error)
      setEncounterData(null)
      setTimelineData(null)
    }
  }

  // Navigation handlers
  const handleSwasyaMapClick = () => {
    navigate('/swasya-map')
  }

  // Mobile utility functions
  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen)
  }

  const handleTabChange = (tab) => {
    setActiveTab(tab)
    setIsMobileMenuOpen(false)
  }

  // Mobile component renderer
  const renderMobileView = () => {
    return (
      <div className="lg:hidden flex flex-col h-full">
        {/* Mobile Tab Navigation */}
        <div 
          className="flex border-b"
          style={{ borderColor: colors.border }}
        >
          <button
            onClick={() => handleTabChange('queue')}
            className={`flex-1 flex items-center justify-center gap-2 p-4 text-sm font-medium transition-colors ${
              activeTab === 'queue' ? 'border-b-2' : ''
            }`}
            style={{
              color: activeTab === 'queue' ? colors.primary : colors.textSecondary,
              borderBottomColor: activeTab === 'queue' ? colors.primary : 'transparent'
            }}
          >
            <FiUsers size={16} />
            Queue
          </button>
          <button
            onClick={() => handleTabChange('encounter')}
            className={`flex-1 flex items-center justify-center gap-2 p-4 text-sm font-medium transition-colors ${
              activeTab === 'encounter' ? 'border-b-2' : ''
            }`}
            style={{
              color: activeTab === 'encounter' ? colors.primary : colors.textSecondary,
              borderBottomColor: activeTab === 'encounter' ? colors.primary : 'transparent'
            }}
          >
            <FiActivity size={16} />
            Encounter
          </button>
          <button
            onClick={() => handleTabChange('history')}
            className={`flex-1 flex items-center justify-center gap-2 p-4 text-sm font-medium transition-colors ${
              activeTab === 'history' ? 'border-b-2' : ''
            }`}
            style={{
              color: activeTab === 'history' ? colors.primary : colors.textSecondary,
              borderBottomColor: activeTab === 'history' ? colors.primary : 'transparent'
            }}
          >
            <FiFileText size={16} />
            History
          </button>
        </div>

        {/* Mobile Tab Content */}
        <div className="flex-1 overflow-hidden">
          {activeTab === 'queue' && (
            <PatientQueue
              patients={patients}
              selectedPatient={selectedPatient}
              onPatientSelect={handlePatientSelect}
              onQueueUpdate={loadInitialData}
            />
          )}
          {activeTab === 'encounter' && (
            <LiveEncounter
              encounterData={encounterData}
              selectedPatient={selectedPatient}
              timelineData={timelineData}
              onConsultationAction={loadInitialData}
            />
          )}
          {activeTab === 'history' && (
            <PatientHistory
              selectedPatient={selectedPatient}
            />
          )}
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div 
        className="h-screen flex items-center justify-center"
        style={{ backgroundColor: colors.background }}
      >
        <div className="text-center">
          <div 
            className="w-16 h-16 border-4 border-t-transparent border-solid rounded-full animate-spin mx-auto mb-4"
            style={{ borderColor: colors.primary }}
          />
          <p style={{ color: colors.textPrimary }}>Loading Dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div 
      className="h-screen flex flex-col"
      style={{ backgroundColor: colors.background }}
    >
      <div 
        className="h-16 flex items-center justify-between px-4 sm:px-6 border-b"
        style={{ 
          backgroundColor: colors.surface,
          borderColor: colors.border 
        }}
      >
        <div className="flex items-center gap-3 sm:gap-6">
          <h1 
            className="text-lg sm:text-xl font-ptserif font-medium"
            style={{ color: colors.textSecondary }}
          >
            Swasya AI
          </h1>
          
          {/* Desktop Dashboard Label & Navigation */}
          <div className="hidden sm:flex items-center gap-4">
            <div 
              className="h-4 w-px"
              style={{ backgroundColor: colors.border }}
            />
            <span 
              className="text-sm font-medium"
              style={{ color: colors.primary }}
            >
              Doctor's Dashboard
            </span>
          </div>
          
          {/* Desktop Navigation Buttons */}
          <div className="hidden lg:flex items-center gap-3 ml-6">
            <button
              onClick={handleSwasyaMapClick}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 hover:opacity-80"
              style={{
                backgroundColor: colors.primary,
                color: colors.surface
              }}
            >
              Swasya Map
            </button>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={toggleMobileMenu}
            className="lg:hidden p-2 rounded-lg transition-colors"
            style={{
              backgroundColor: isMobileMenuOpen ? colors.primary20 : 'transparent',
              color: colors.textPrimary
            }}
          >
            <FiMenu size={20} />
          </button>
        </div>

        <div className="flex items-center gap-2 sm:gap-4">
          {/* Mobile Navigation Dropdown */}
          {isMobileMenuOpen && (
            <div 
              className="absolute top-16 left-0 right-0 lg:hidden border-b z-50"
              style={{
                backgroundColor: colors.surface,
                borderColor: colors.border
              }}
            >
              <div className="p-4 space-y-3">
                <button
                  onClick={handleSwasyaMapClick}
                  className="w-full flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                  style={{
                    backgroundColor: colors.primary,
                    color: colors.surface
                  }}
                >
                  Swasya Map
                </button>
              </div>
            </div>
          )}
          
          <div className="text-right">
            <div 
              className="text-sm font-medium"
              style={{ color: colors.textPrimary }}
            >
              Dr. Shubham
            </div>
            <div 
              className="text-xs hidden sm:block"
              style={{ color: colors.textSecondary }}
            >
              Last refresh: {formatTime(lastRefresh)}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content - Desktop and Mobile Layouts */}
      <div className="flex-1 overflow-hidden">
        {/* Desktop Layout (3-column) */}
        <div className="hidden lg:flex h-full">
          <div 
            className="w-80 border-r shrink-0"
            style={{ borderColor: colors.border }}
          >
            <PatientQueue
              patients={patients}
              selectedPatient={selectedPatient}
              onPatientSelect={handlePatientSelect}
              onQueueUpdate={loadInitialData}
            />
          </div>

          <div className="flex-1 min-w-0">
            <LiveEncounter
              encounterData={encounterData}
              selectedPatient={selectedPatient}
              timelineData={timelineData}
              onConsultationAction={loadInitialData}
            />
          </div>

          <div 
            className="w-96 border-l shrink-0"
            style={{ borderColor: colors.border }}
          >
            <PatientHistory
              selectedPatient={selectedPatient}
            />
          </div>
        </div>

        {/* Mobile Layout (Tab-based) */}
        {renderMobileView()}
      </div>

      <div 
        className="h-8 flex items-center justify-between px-4 sm:px-6 text-xs border-t"
        style={{ 
          backgroundColor: colors.surfaceSecondary,
          borderColor: colors.border,
          color: colors.textSecondary 
        }}
      >
        <div className="flex items-center gap-2 sm:gap-4">
          <span>Status: {dashboardStats ? 'Online' : 'Loading...'}</span>
          <span className="hidden sm:inline">Ready: {patients.filter(p => p.status === 'ready').length}</span>
          <span>Total: {dashboardStats?.patients?.total || 0}</span>
        </div>
        <div className="flex items-center gap-2 sm:gap-4">
          <span className="hidden sm:inline">Backend: {dashboardStats ? 'Connected' : 'Loading...'}</span>
          <span>v1.0.0</span>
        </div>
      </div>
    </div>
  )
}

export default Dashboard