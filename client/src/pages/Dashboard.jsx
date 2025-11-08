import React, { useState, useEffect, useCallback } from 'react'
import { colors } from '../utils/colors'
import PatientQueue from '../components/dashboard/PatientQueue'
import LiveEncounter from '../components/dashboard/LiveEncounter'
import PatientHistory from '../components/dashboard/PatientHistory'
import { patientsAPI, queueAPI, notesAPI, statsAPI, transformers, polling } from '../utils/api'
import { FiRefreshCw } from 'react-icons/fi'

const Dashboard = () => {
  const [patients, setPatients] = useState([])
  const [selectedPatient, setSelectedPatient] = useState(null)
  const [encounterData, setEncounterData] = useState(null)
  const [timelineData, setTimelineData] = useState(null)
  const [lastRefresh, setLastRefresh] = useState(new Date())
  const [loading, setLoading] = useState(true)
  const [dashboardStats, setDashboardStats] = useState(null)

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

  const handleRefresh = async () => {
    await loadInitialData()
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

      <div className="flex-1 flex overflow-hidden">
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

      <div 
        className="h-8 flex items-center justify-between px-6 text-xs border-t"
        style={{ 
          backgroundColor: colors.surfaceSecondary,
          borderColor: colors.border,
          color: colors.textSecondary 
        }}
      >
        <div className="flex items-center gap-4">
          <span>Status: {dashboardStats ? 'Online' : 'Loading...'}</span>
          <span>Queue: {dashboardStats?.queue?.current_size || 0} active</span>
          <span>Ready: {patients.filter(p => p.status === 'ready').length}</span>
          <span>Total Patients: {dashboardStats?.patients?.total || 0}</span>
        </div>
        <div className="flex items-center gap-4">
          <span>Backend Status: {dashboardStats ? 'Connected' : 'Loading...'}</span>
          <span>Version: 1.0.0</span>
        </div>
      </div>
    </div>
  )
}

export default Dashboard