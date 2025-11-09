import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { 
  FiArrowLeft, 
  FiMenu, 
  FiMapPin, 
  FiAlertTriangle, 
  FiActivity,
  FiCalendar,
  FiFilter,
  FiZoomIn,
  FiZoomOut,
  FiMaximize2,
  FiInfo,
  FiTrendingUp,
  FiUsers,
  FiThermometer
} from 'react-icons/fi';
import { colors } from '../utils/colors';

// Punjab districts with coordinates and outbreak data
const punjabOutbreakData = [
  {
    id: 'amritsar',
    name: 'Amritsar',
    coordinates: [31.6340, 74.8723],
    cases: 156,
    trend: 'increasing',
    severity: 'high',
    primarySymptom: 'Fever',
    lastUpdated: '2 hours ago',
    population: 2500000,
    details: {
      feverCases: 156,
      respiratoryCases: 89,
      gastrointestinalCases: 23,
      skinConditions: 12,
      affectedAreas: ['GT Road', 'Ranjit Avenue', 'Lawrence Road'],
      dominantAge: '25-45 years',
      genderRatio: 'M:F = 3:2'
    }
  },
  {
    id: 'jalandhar',
    name: 'Jalandhar',
    coordinates: [31.3260, 75.5762],
    cases: 134,
    trend: 'increasing',
    severity: 'high',
    primarySymptom: 'Respiratory Issues',
    lastUpdated: '1 hour ago',
    population: 2200000,
    details: {
      feverCases: 134,
      respiratoryCases: 156,
      gastrointestinalCases: 45,
      skinConditions: 8,
      affectedAreas: ['Model Town', 'Civil Lines', 'Cantt Area'],
      dominantAge: '30-50 years',
      genderRatio: 'M:F = 1:1'
    }
  },
  {
    id: 'ludhiana',
    name: 'Ludhiana',
    coordinates: [30.9010, 75.8573],
    cases: 89,
    trend: 'stable',
    severity: 'medium',
    primarySymptom: 'Gastrointestinal',
    lastUpdated: '3 hours ago',
    population: 3500000,
    details: {
      feverCases: 67,
      respiratoryCases: 45,
      gastrointestinalCases: 89,
      skinConditions: 34,
      affectedAreas: ['Pakhowal Road', 'Ferozepur Road', 'Industrial Area'],
      dominantAge: '20-40 years',
      genderRatio: 'M:F = 2:3'
    }
  },
  {
    id: 'patiala',
    name: 'Patiala',
    coordinates: [30.3398, 76.3869],
    cases: 67,
    trend: 'decreasing',
    severity: 'medium',
    primarySymptom: 'Skin Conditions',
    lastUpdated: '4 hours ago',
    population: 1800000,
    details: {
      feverCases: 34,
      respiratoryCases: 23,
      gastrointestinalCases: 12,
      skinConditions: 67,
      affectedAreas: ['Mall Road', 'Leela Bhawan', 'Urban Estate'],
      dominantAge: '15-35 years',
      genderRatio: 'M:F = 1:2'
    }
  },
  {
    id: 'bathinda',
    name: 'Bathinda',
    coordinates: [30.2110, 74.9455],
    cases: 23,
    trend: 'stable',
    severity: 'low',
    primarySymptom: 'Mixed Symptoms',
    lastUpdated: '5 hours ago',
    population: 1400000,
    details: {
      feverCases: 23,
      respiratoryCases: 18,
      gastrointestinalCases: 15,
      skinConditions: 9,
      affectedAreas: ['Railway Colony', 'Thermal Colony', 'Civil Lines'],
      dominantAge: '25-45 years',
      genderRatio: 'M:F = 3:2'
    }
  },
  {
    id: 'mohali',
    name: 'Mohali',
    coordinates: [30.7046, 76.7179],
    cases: 45,
    trend: 'stable',
    severity: 'low',
    primarySymptom: 'Respiratory Issues',
    lastUpdated: '2 hours ago',
    population: 1200000,
    details: {
      feverCases: 34,
      respiratoryCases: 45,
      gastrointestinalCases: 21,
      skinConditions: 6,
      affectedAreas: ['Phase 3B2', 'Phase 7', 'Sector 70'],
      dominantAge: '28-48 years',
      genderRatio: 'M:F = 1:1'
    }
  },
  {
    id: 'firozpur',
    name: 'Firozpur',
    coordinates: [30.9320, 74.6150],
    cases: 38,
    trend: 'increasing',
    severity: 'medium',
    primarySymptom: 'Fever',
    lastUpdated: '6 hours ago',
    population: 1100000,
    details: {
      feverCases: 38,
      respiratoryCases: 29,
      gastrointestinalCases: 17,
      skinConditions: 11,
      affectedAreas: ['City Area', 'Cantt', 'Railway Colony'],
      dominantAge: '22-42 years',
      genderRatio: 'M:F = 2:1'
    }
  }
];

// Component to handle map zoom controls
const MapController = ({ zoomLevel }) => {
  const map = useMap();
  
  useEffect(() => {
    map.setZoom(zoomLevel);
  }, [map, zoomLevel]);

  return null;
};

const SwasyaMapLeaflet = () => {
  const navigate = useNavigate();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [lastRefresh] = useState(new Date());
  const [selectedDistrict, setSelectedDistrict] = useState(null);
  const [filterSeverity, setFilterSeverity] = useState('all');
  const [timePeriod, setTimePeriod] = useState('24h');
  const [zoomLevel, setZoomLevel] = useState(8);
  const mapRef = useRef();

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    });
  };

  const handleDashboardClick = () => {
    navigate('/dashboard');
  };

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  // Filter data based on severity
  const filteredData = punjabOutbreakData.filter(district => {
    if (filterSeverity === 'all') return true;
    return district.severity === filterSeverity;
  });

  // Get marker color based on severity
  const getMarkerColor = (severity) => {
    switch (severity) {
      case 'high': return colors.error;
      case 'medium': return colors.warning;
      case 'low': return colors.success;
      default: return colors.textSecondary;
    }
  };

  // Get marker size based on case count
  const getMarkerSize = (cases) => {
    if (cases > 100) return 25;
    if (cases > 50) return 20;
    if (cases > 20) return 15;
    return 10;
  };

  // Calculate total statistics
  const totalCases = filteredData.reduce((sum, district) => sum + district.cases, 0);
  const highSeverityCount = filteredData.filter(d => d.severity === 'high').length;
  const increasingTrendCount = filteredData.filter(d => d.trend === 'increasing').length;

  return (
    <div 
      className="h-screen flex flex-col"
      style={{ backgroundColor: colors.background }}
    >
      {/* Header - Same as Dashboard */}
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
              Outbreak Analytics
            </span>
          </div>
          
          {/* Desktop Navigation Buttons */}
          <div className="hidden lg:flex items-center gap-3 ml-6">
            <button
              onClick={handleDashboardClick}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 hover:opacity-80"
              style={{
                backgroundColor: colors.primary,
                color: colors.surface
              }}
            >
              Dashboard
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
                  onClick={handleDashboardClick}
                  className="w-full flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                  style={{
                    backgroundColor: colors.primary,
                    color: colors.surface
                  }}
                >
                  <FiArrowLeft size={16} />
                  Dashboard
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

      {/* Main Content */}
      <div className="flex-1 flex flex-col lg:flex-row overflow-hidden">
        
        {/* Controls Panel */}
        <div 
          className="lg:w-80 border-b lg:border-b-0 lg:border-r p-4 space-y-4 overflow-y-auto"
          style={{ 
            backgroundColor: colors.surface,
            borderColor: colors.border 
          }}
        >
          {/* Statistics Cards */}
          <div className="space-y-3">
            <h3 
              className="text-lg font-medium"
              style={{ color: colors.textPrimary }}
            >
              Punjab Outbreak Summary
            </h3>
            
            <div className="grid grid-cols-2 lg:grid-cols-1 gap-3">
              <div 
                className="p-4 rounded-xl"
                style={{ backgroundColor: colors.surfaceSecondary }}
              >
                <div className="flex items-center gap-2 mb-2">
                  <FiUsers size={16} style={{ color: colors.error }} />
                  <span className="text-sm font-medium" style={{ color: colors.textSecondary }}>
                    Total Cases
                  </span>
                </div>
                <div className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
                  {totalCases}
                </div>
                <div className="text-xs" style={{ color: colors.textTertiary }}>
                  Across {filteredData.length} districts
                </div>
              </div>

              <div 
                className="p-4 rounded-xl"
                style={{ backgroundColor: colors.surfaceSecondary }}
              >
                <div className="flex items-center gap-2 mb-2">
                  <FiAlertTriangle size={16} style={{ color: colors.error }} />
                  <span className="text-sm font-medium" style={{ color: colors.textSecondary }}>
                    High Severity
                  </span>
                </div>
                <div className="text-2xl font-bold" style={{ color: colors.error }}>
                  {highSeverityCount}
                </div>
                <div className="text-xs" style={{ color: colors.textTertiary }}>
                  Districts at risk
                </div>
              </div>

              <div 
                className="p-4 rounded-xl"
                style={{ backgroundColor: colors.surfaceSecondary }}
              >
                <div className="flex items-center gap-2 mb-2">
                  <FiTrendingUp size={16} style={{ color: colors.warning }} />
                  <span className="text-sm font-medium" style={{ color: colors.textSecondary }}>
                    Rising Trend
                  </span>
                </div>
                <div className="text-2xl font-bold" style={{ color: colors.warning }}>
                  {increasingTrendCount}
                </div>
                <div className="text-xs" style={{ color: colors.textTertiary }}>
                  Escalating cases
                </div>
              </div>
            </div>
          </div>

          {/* Filters */}
          <div className="space-y-4">
            <h4 
              className="text-sm font-medium"
              style={{ color: colors.textPrimary }}
            >
              Filters & Controls
            </h4>
            
            {/* Severity Filter */}
            <div>
              <label className="text-xs font-medium" style={{ color: colors.textSecondary }}>
                Severity Level
              </label>
              <select
                value={filterSeverity}
                onChange={(e) => setFilterSeverity(e.target.value)}
                className="w-full mt-1 p-2 rounded-lg border text-sm"
                style={{
                  backgroundColor: colors.surfaceSecondary,
                  borderColor: colors.border,
                  color: colors.textPrimary
                }}
              >
                <option value="all">All Levels</option>
                <option value="high">High Severity</option>
                <option value="medium">Medium Severity</option>
                <option value="low">Low Severity</option>
              </select>
            </div>

            {/* Time Period */}
            <div>
              <label className="text-xs font-medium" style={{ color: colors.textSecondary }}>
                Time Period
              </label>
              <select
                value={timePeriod}
                onChange={(e) => setTimePeriod(e.target.value)}
                className="w-full mt-1 p-2 rounded-lg border text-sm"
                style={{
                  backgroundColor: colors.surfaceSecondary,
                  borderColor: colors.border,
                  color: colors.textPrimary
                }}
              >
                <option value="24h">Last 24 Hours</option>
                <option value="7d">Last 7 Days</option>
                <option value="30d">Last 30 Days</option>
                <option value="all">All Time</option>
              </select>
            </div>

            {/* Map Controls */}
            <div>
              <label className="text-xs font-medium" style={{ color: colors.textSecondary }}>
                Map Zoom
              </label>
              <div className="flex items-center gap-2 mt-2">
                <button
                  onClick={() => setZoomLevel(Math.max(6, zoomLevel - 1))}
                  className="p-2 rounded-lg transition-colors"
                  style={{
                    backgroundColor: colors.surfaceSecondary,
                    color: colors.textPrimary
                  }}
                >
                  <FiZoomOut size={14} />
                </button>
                <span className="text-sm px-3 py-1 rounded" style={{ 
                  backgroundColor: colors.surfaceSecondary,
                  color: colors.textPrimary 
                }}>
                  {zoomLevel}x
                </span>
                <button
                  onClick={() => setZoomLevel(Math.min(12, zoomLevel + 1))}
                  className="p-2 rounded-lg transition-colors"
                  style={{
                    backgroundColor: colors.surfaceSecondary,
                    color: colors.textPrimary
                  }}
                >
                  <FiZoomIn size={14} />
                </button>
              </div>
            </div>
          </div>

          {/* Legend */}
          <div className="space-y-3">
            <h4 
              className="text-sm font-medium"
              style={{ color: colors.textPrimary }}
            >
              Map Legend
            </h4>
            <div className="space-y-2">
              <div className="flex items-center gap-3">
                <div 
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: colors.error }}
                />
                <span className="text-xs" style={{ color: colors.textSecondary }}>
                  High Severity (100+ cases)
                </span>
              </div>
              <div className="flex items-center gap-3">
                <div 
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: colors.warning }}
                />
                <span className="text-xs" style={{ color: colors.textSecondary }}>
                  Medium Severity (50-99 cases)
                </span>
              </div>
              <div className="flex items-center gap-3">
                <div 
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: colors.success }}
                />
                <span className="text-xs" style={{ color: colors.textSecondary }}>
                  Low Severity (&lt;50 cases)
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Map Container */}
        <div className="flex-1 relative">
          <MapContainer
            ref={mapRef}
            center={[30.8, 75.8]}
            zoom={zoomLevel}
            scrollWheelZoom={true}
            className="h-full w-full"
            style={{ backgroundColor: colors.surfaceSecondary }}
          >
            <MapController zoomLevel={zoomLevel} />
            
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            
            {filteredData.map((district) => (
              <CircleMarker
                key={district.id}
                center={district.coordinates}
                radius={getMarkerSize(district.cases)}
                fillColor={getMarkerColor(district.severity)}
                color="#ffffff"
                weight={2}
                opacity={1}
                fillOpacity={0.8}
                eventHandlers={{
                  click: () => setSelectedDistrict(district),
                }}
              >
                <Popup>
                  <div className="p-3 min-w-64">
                    <div className="flex items-center gap-2 mb-3">
                      <FiMapPin size={16} style={{ color: getMarkerColor(district.severity) }} />
                      <h3 className="font-ptserif text-lg font-medium" style={{ color: colors.textPrimary }}>
                        {district.name}
                      </h3>
                    </div>
                    
                    <div className="space-y-2 mb-3">
                      <div className="flex justify-between">
                        <span className="text-sm" style={{ color: colors.textSecondary }}>Total Cases:</span>
                        <span className="text-sm font-medium" style={{ color: colors.textPrimary }}>{district.cases}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm" style={{ color: colors.textSecondary }}>Primary Symptom:</span>
                        <span className="text-sm font-medium" style={{ color: colors.textPrimary }}>{district.primarySymptom}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm" style={{ color: colors.textSecondary }}>Trend:</span>
                        <span 
                          className="text-sm font-medium capitalize"
                          style={{ 
                            color: district.trend === 'increasing' ? colors.error : 
                                   district.trend === 'decreasing' ? colors.success : colors.warning
                          }}
                        >
                          {district.trend}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm" style={{ color: colors.textSecondary }}>Last Updated:</span>
                        <span className="text-sm" style={{ color: colors.textTertiary }}>{district.lastUpdated}</span>
                      </div>
                    </div>

                    <div className="border-t pt-3" style={{ borderColor: colors.border }}>
                      <h4 className="text-sm font-medium mb-2" style={{ color: colors.textPrimary }}>Symptom Breakdown:</h4>
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        <div className="flex items-center gap-1">
                          <FiThermometer size={12} style={{ color: colors.error }} />
                          <span style={{ color: colors.textSecondary }}>Fever: {district.details.feverCases}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <FiActivity size={12} style={{ color: colors.warning }} />
                          <span style={{ color: colors.textSecondary }}>Respiratory: {district.details.respiratoryCases}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <FiUsers size={12} style={{ color: colors.accent }} />
                          <span style={{ color: colors.textSecondary }}>GI: {district.details.gastrointestinalCases}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <FiInfo size={12} style={{ color: colors.success }} />
                          <span style={{ color: colors.textSecondary }}>Skin: {district.details.skinConditions}</span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => setSelectedDistrict(district)}
                      className="w-full mt-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
                      style={{
                        backgroundColor: colors.primary,
                        color: colors.surface
                      }}
                    >
                      View Detailed Analysis
                    </button>
                  </div>
                </Popup>
              </CircleMarker>
            ))}
          </MapContainer>

          {/* Map Overlay - Quick Stats */}
          <div className="absolute top-4 right-4 z-10">
            <div 
              className="bg-white rounded-lg shadow-lg p-3 border"
              style={{
                backgroundColor: colors.surface,
                borderColor: colors.border
              }}
            >
              <div className="text-xs font-medium mb-2" style={{ color: colors.textSecondary }}>
                Real-time Status
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                <span className="text-xs" style={{ color: colors.success }}>
                  Live Monitoring Active
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Selected District Details Modal */}
      {selectedDistrict && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div 
            className="max-w-2xl w-full max-h-[80vh] overflow-y-auto rounded-2xl"
            style={{ backgroundColor: colors.surface }}
          >
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div 
                    className="w-8 h-8 rounded-full flex items-center justify-center"
                    style={{ backgroundColor: getMarkerColor(selectedDistrict.severity) + '20' }}
                  >
                    <FiMapPin size={16} style={{ color: getMarkerColor(selectedDistrict.severity) }} />
                  </div>
                  <h2 className="font-ptserif text-2xl font-medium" style={{ color: colors.textPrimary }}>
                    {selectedDistrict.name} District
                  </h2>
                </div>
                <button
                  onClick={() => setSelectedDistrict(null)}
                  className="p-2 rounded-lg transition-colors"
                  style={{
                    backgroundColor: colors.surfaceSecondary,
                    color: colors.textSecondary
                  }}
                >
                  ✕
                </button>
              </div>

              {/* Detailed Statistics */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                <div 
                  className="p-4 rounded-xl text-center"
                  style={{ backgroundColor: colors.surfaceSecondary }}
                >
                  <div className="text-2xl font-bold mb-1" style={{ color: colors.error }}>
                    {selectedDistrict.details.feverCases}
                  </div>
                  <div className="text-xs" style={{ color: colors.textSecondary }}>
                    Fever Cases
                  </div>
                </div>
                <div 
                  className="p-4 rounded-xl text-center"
                  style={{ backgroundColor: colors.surfaceSecondary }}
                >
                  <div className="text-2xl font-bold mb-1" style={{ color: colors.warning }}>
                    {selectedDistrict.details.respiratoryCases}
                  </div>
                  <div className="text-xs" style={{ color: colors.textSecondary }}>
                    Respiratory
                  </div>
                </div>
                <div 
                  className="p-4 rounded-xl text-center"
                  style={{ backgroundColor: colors.surfaceSecondary }}
                >
                  <div className="text-2xl font-bold mb-1" style={{ color: colors.accent }}>
                    {selectedDistrict.details.gastrointestinalCases}
                  </div>
                  <div className="text-xs" style={{ color: colors.textSecondary }}>
                    GI Issues
                  </div>
                </div>
                <div 
                  className="p-4 rounded-xl text-center"
                  style={{ backgroundColor: colors.surfaceSecondary }}
                >
                  <div className="text-2xl font-bold mb-1" style={{ color: colors.success }}>
                    {selectedDistrict.details.skinConditions}
                  </div>
                  <div className="text-xs" style={{ color: colors.textSecondary }}>
                    Skin Conditions
                  </div>
                </div>
              </div>

              {/* Additional Details */}
              <div className="space-y-4">
                <div>
                  <h3 className="text-sm font-medium mb-2" style={{ color: colors.textPrimary }}>
                    Affected Areas
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {selectedDistrict.details.affectedAreas.map((area, index) => (
                      <span 
                        key={index}
                        className="px-3 py-1 rounded-full text-xs"
                        style={{
                          backgroundColor: colors.primary + '20',
                          color: colors.primary
                        }}
                      >
                        {area}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <h4 className="text-sm font-medium mb-2" style={{ color: colors.textPrimary }}>
                      Demographics
                    </h4>
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Dominant Age:</span>
                        <span style={{ color: colors.textPrimary }}>{selectedDistrict.details.dominantAge}</span>
                      </div>
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Gender Ratio:</span>
                        <span style={{ color: colors.textPrimary }}>{selectedDistrict.details.genderRatio}</span>
                      </div>
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Population:</span>
                        <span style={{ color: colors.textPrimary }}>{selectedDistrict.population.toLocaleString()}</span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <h4 className="text-sm font-medium mb-2" style={{ color: colors.textPrimary }}>
                      Status
                    </h4>
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Severity:</span>
                        <span 
                          className="capitalize font-medium"
                          style={{ 
                            color: getMarkerColor(selectedDistrict.severity)
                          }}
                        >
                          {selectedDistrict.severity}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Trend:</span>
                        <span 
                          className="capitalize font-medium"
                          style={{ 
                            color: selectedDistrict.trend === 'increasing' ? colors.error : 
                                   selectedDistrict.trend === 'decreasing' ? colors.success : colors.warning
                          }}
                        >
                          {selectedDistrict.trend}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span style={{ color: colors.textSecondary }}>Last Updated:</span>
                        <span style={{ color: colors.textPrimary }}>{selectedDistrict.lastUpdated}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SwasyaMapLeaflet;