import React, { useState, useEffect } from 'react';
import { colors } from '../../utils/colors';
import { FiMic, FiFileText, FiCheck, FiLoader } from 'react-icons/fi';
import { IoMdQrScanner } from 'react-icons/io';

const LiveEncounter = ({ encounterData, selectedPatient }) => {
  const [typingText, setTypingText] = useState('');
  const [currentSection, setCurrentSection] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  // Simulate AI typing effect for SOAP notes
  useEffect(() => {
    if (!encounterData?.scribeData?.soapNote || encounterData.scribeData.isProcessing) return;

    const soapSections = [
      { key: 'subjective', label: 'Subjective', text: encounterData.scribeData.soapNote.subjective },
      { key: 'objective', label: 'Objective', text: encounterData.scribeData.soapNote.objective },
      { key: 'assessment', label: 'Assessment', text: encounterData.scribeData.soapNote.assessment },
      { key: 'plan', label: 'Plan', text: encounterData.scribeData.soapNote.plan }
    ];

    let sectionIndex = 0;
    let charIndex = 0;
    setIsTyping(true);
    setTypingText('');

    const typeNextChar = () => {
      if (sectionIndex >= soapSections.length) {
        setIsTyping(false);
        return;
      }

      const currentSectionData = soapSections[sectionIndex];
      
      if (charIndex === 0) {
        setCurrentSection(currentSectionData.label);
      }

      if (charIndex < currentSectionData.text.length) {
        setTypingText(prev => prev + currentSectionData.text[charIndex]);
        charIndex++;
        setTimeout(typeNextChar, 30); // Typing speed
      } else {
        // Move to next section
        setTypingText(prev => prev + '\n\n');
        sectionIndex++;
        charIndex = 0;
        setTimeout(typeNextChar, 200); // Pause between sections
      }
    };

    // Start typing after a short delay
    const timer = setTimeout(typeNextChar, 1000);
    return () => clearTimeout(timer);
  }, [encounterData]);

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
            Select a Ready Patient
          </h3>
          <p 
            className="text-base font-light"
            style={{ color: colors.textSecondary }}
          >
            Choose a patient from the queue to view their live encounter data and AI-generated insights.
          </p>
        </div>
      </div>
    );
  }

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
                backgroundColor: colors.success20,
                color: colors.success 
              }}
            >
              Patient Ready
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

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-6 space-y-6">
          
          {/* AI Scribe Module */}
          <div 
            className="rounded-2xl p-6 border"
            style={{ 
              backgroundColor: colors.background,
              borderColor: colors.border 
            }}
          >
            <div className="flex items-center gap-3 mb-6">
              <div 
                className="w-10 h-10 rounded-xl flex items-center justify-center"
                style={{ backgroundColor: colors.primary20 }}
              >
                <FiMic size={18} style={{ color: colors.primary }} />
              </div>
              <div>
                <h3 
                  className="text-lg font-medium"
                  style={{ color: colors.textPrimary }}
                >
                  AI Scribe (SOAP Note)
                </h3>
                <p 
                  className="text-sm"
                  style={{ color: colors.textSecondary }}
                >
                  Real-time conversation analysis
                </p>
              </div>
              {isTyping && (
                <div className="ml-auto">
                  <FiLoader size={16} className="animate-spin" style={{ color: colors.primary }} />
                </div>
              )}
            </div>

            {/* Raw Transcript */}
            <div className="mb-6">
              <h4 
                className="text-sm font-medium mb-3"
                style={{ color: colors.textSecondary }}
              >
                Raw Transcript (Hindi)
              </h4>
              <div 
                className="p-4 rounded-xl opacity-60 text-sm font-light"
                style={{ 
                  backgroundColor: colors.surfaceSecondary,
                  color: colors.textSecondary 
                }}
              >
                {encounterData?.scribeData?.rawTranscript || "बुखार और खाँसी... तीन दिन से..."}
              </div>
            </div>

            {/* AI Structured Note */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 
                  className="text-sm font-medium"
                  style={{ color: colors.textPrimary }}
                >
                  VACA AI Structured Note
                </h4>
                {isTyping && (
                  <span 
                    className="text-xs font-medium px-2 py-1 rounded-full"
                    style={{
                      backgroundColor: colors.primary20,
                      color: colors.primary
                    }}
                  >
                    Generating {currentSection}...
                  </span>
                )}
              </div>
              
              <div 
                className="p-4 rounded-xl border-2 min-h-[200px]"
                style={{ 
                  backgroundColor: colors.surface,
                  borderColor: isTyping ? colors.primary : colors.border,
                  borderStyle: isTyping ? 'dashed' : 'solid'
                }}
              >
                {encounterData?.scribeData?.isProcessing ? (
                  <div className="flex items-center justify-center h-32">
                    <FiLoader size={24} className="animate-spin" style={{ color: colors.primary }} />
                  </div>
                ) : (
                  <pre 
                    className="text-sm font-light whitespace-pre-wrap leading-relaxed"
                    style={{ color: colors.textPrimary }}
                  >
                    {typingText || `Subjective: ${encounterData?.scribeData?.soapNote?.subjective || 'Processing...'}

Objective: ${encounterData?.scribeData?.soapNote?.objective || 'Processing...'}

Assessment: ${encounterData?.scribeData?.soapNote?.assessment || 'Processing...'}

Plan: ${encounterData?.scribeData?.soapNote?.plan || 'Processing...'}`}
                  </pre>
                )}
              </div>

              {encounterData?.scribeData?.confidence && (
                <div className="mt-3 flex items-center justify-between">
                  <span 
                    className="text-xs"
                    style={{ color: colors.textSecondary }}
                  >
                    AI Confidence: {Math.round(encounterData.scribeData.confidence * 100)}%
                  </span>
                  <FiCheck size={14} style={{ color: colors.success }} />
                </div>
              )}
            </div>
          </div>

          {/* AI Digitizer Module */}
          <div 
            className="rounded-2xl p-6 border"
            style={{ 
              backgroundColor: colors.background,
              borderColor: colors.border 
            }}
          >
            <div className="flex items-center gap-3 mb-6">
              <div 
                className="w-10 h-10 rounded-xl flex items-center justify-center"
                style={{ backgroundColor: colors.accent + '20' }}
              >
                <IoMdQrScanner size={18} style={{ color: colors.accent }} />
              </div>
              <div>
                <h3 
                  className="text-lg font-medium"
                  style={{ color: colors.textPrimary }}
                >
                  AI Digitizer (Before & After)
                </h3>
                <p 
                  className="text-sm"
                  style={{ color: colors.textSecondary }}
                >
                  Prescription scanning & extraction
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Panel - Scanned Image */}
              <div>
                <h4 
                  className="text-sm font-medium mb-3"
                  style={{ color: colors.textSecondary }}
                >
                  Scanned Prescription
                </h4>
                <div 
                  className="aspect-3/4 rounded-xl border-2 border-dashed p-4 flex items-center justify-center"
                  style={{ borderColor: colors.border }}
                >
                  <div className="text-center space-y-2">
                    <IoMdQrScanner size={32} style={{ color: colors.textTertiary }} />
                    <p 
                      className="text-sm font-light"
                      style={{ color: colors.textSecondary }}
                    >
                      Handwritten prescription image would appear here
                    </p>
                  </div>
                </div>
              </div>

              {/* Right Panel - Extracted Data */}
              <div>
                <h4 
                  className="text-sm font-medium mb-3"
                  style={{ color: colors.textPrimary }}
                >
                  Extracted & Structured
                </h4>
                <div 
                  className="p-4 rounded-xl border space-y-4"
                  style={{ 
                    backgroundColor: colors.surface,
                    borderColor: colors.border 
                  }}
                >
                  {encounterData?.digitizedData?.extractedData?.medications?.map((med, index) => (
                    <div 
                      key={index}
                      className="p-3 rounded-lg"
                      style={{ backgroundColor: colors.surfaceSecondary }}
                    >
                      <div className="grid grid-cols-1 gap-2 text-sm">
                        <div>
                          <span 
                            className="font-medium"
                            style={{ color: colors.textSecondary }}
                          >
                            Medication: 
                          </span>
                          <span 
                            className="ml-2 font-medium"
                            style={{ color: colors.textPrimary }}
                          >
                            {med.name}
                          </span>
                        </div>
                        <div>
                          <span 
                            className="font-medium"
                            style={{ color: colors.textSecondary }}
                          >
                            Dosage: 
                          </span>
                          <span 
                            className="ml-2"
                            style={{ color: colors.textPrimary }}
                          >
                            {med.dosage}
                          </span>
                        </div>
                        <div>
                          <span 
                            className="font-medium"
                            style={{ color: colors.textSecondary }}
                          >
                            Frequency: 
                          </span>
                          <span 
                            className="ml-2"
                            style={{ color: colors.textPrimary }}
                          >
                            {med.frequency}
                          </span>
                        </div>
                      </div>
                    </div>
                  )) || (
                    <div className="text-center py-8">
                      <FiLoader size={24} className="animate-spin mx-auto mb-2" style={{ color: colors.primary }} />
                      <p 
                        className="text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        Processing prescription...
                      </p>
                    </div>
                  )}

                  {encounterData?.digitizedData?.confidence && (
                    <div className="pt-3 border-t flex items-center justify-between" style={{ borderColor: colors.border }}>
                      <span 
                        className="text-xs"
                        style={{ color: colors.textSecondary }}
                      >
                        Extraction Confidence: {Math.round(encounterData.digitizedData.confidence * 100)}%
                      </span>
                      <FiCheck size={14} style={{ color: colors.success }} />
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LiveEncounter;