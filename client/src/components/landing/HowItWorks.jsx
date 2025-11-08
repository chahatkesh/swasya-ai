import React from 'react'
import { colors } from '../../utils/colors'
import { 
  FiMic, 
  FiFileText, 
  FiMonitor, 
  FiMap,
  FiArrowRight
} from 'react-icons/fi'

const HowItWorks = () => {
  const steps = [
    {
      id: 1,
      icon: FiMic,
      title: "Nurse starts Swasya Listen",
      description: "Nurse opens the mobile app and starts the visit. Swasya Listen transcribes the conversation live.",
      microcopy: "Voice → Text → Key symptoms extracted.",
      alt: "Phone with microphone icon for voice transcription"
    },
    {
      id: 2,
      icon: FiFileText,
      title: "Nurse scans documents with Swasya Scan",
      description: "Scan prescriptions, reports and notes. AI builds a structured medical history and links it to UHID.",
      microcopy: "OCR + clinical data extraction.",
      alt: "Document with scan lines for OCR processing"
    },
    {
      id: 3,
      icon: FiMonitor,
      title: "Doctor sees everything on Swasya Sync",
      description: "Before the patient enters, the doctor views the AI-generated history, live transcript and summary.",
      microcopy: "Walk in prepared — diagnose faster.",
      alt: "Desktop dashboard showing patient information"
    },
    {
      id: 4,
      icon: FiMap,
      title: "Admin monitors with Swasya Map",
      description: "Admins and doctors see regional hotspots and trends that help prioritize resources.",
      microcopy: "Visual outbreak analytics for preventive action.",
      alt: "Map with heat spots showing regional data"
    }
  ];

  return (
    <section 
      className="py-20 px-6" 
      style={{backgroundColor: colors.background}}
    >
      <div className="max-w-4xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-6">
          <h2 
            className="text-4xl md:text-5xl lg:text-6xl font-light leading-tight tracking-tight" 
            style={{color: colors.textPrimary}}
          >
            How Swasya AI fits into your{' '}
            <span className="font-medium" style={{color: colors.primary}}>clinic workflow</span>
          </h2>
          
          <p 
            className="text-xl md:text-2xl leading-relaxed max-w-3xl mx-auto font-light" 
            style={{color: colors.textSecondary}}
          >
            From triage to consultation — we automate the parts that slow doctors down.
          </p>
        </div>

        {/* Steps List */}
        <div className="space-y-4">
          {steps.map((step, index) => {
            const IconComponent = step.icon;
            
            return (
              <div 
                key={step.id} 
                className="group cursor-pointer transition-all duration-200 hover:scale-[1.02]"
              >
                <div 
                  className="flex items-start gap-6 p-6 rounded-2xl transition-all duration-200"
                  style={{
                    backgroundColor: colors.surface,
                    border: `1px solid ${colors.border}`
                  }}
                >
                  {/* Icon */}
                  <div className="shrink-0 mt-1">
                    <div 
                      className="w-14 h-14 rounded-xl flex items-center justify-center"
                      style={{backgroundColor: colors.surfaceSecondary}}
                    >
                      <IconComponent 
                        size={24} 
                        style={{color: colors.primary}}
                        aria-label={step.alt}
                      />
                    </div>
                  </div>

                  {/* Content */}
                  <div className="flex-1 space-y-2">
                    <h3 
                      className="text-xl font-medium leading-tight" 
                      style={{color: colors.textPrimary}}
                    >
                      {step.title}
                    </h3>
                    
                    <p 
                      className="text-base leading-relaxed font-light" 
                      style={{color: colors.textSecondary}}
                    >
                      {step.description}
                    </p>
                    
                    <p 
                      className="text-sm font-medium" 
                      style={{color: colors.textTertiary}}
                    >
                      {step.microcopy}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* CTA */}
        <div className="text-center mt-12">
          <button 
            className="px-8 py-3 rounded-full text-base font-medium transition-colors duration-200"
            style={{
              backgroundColor: colors.primary,
              color: colors.secondary
            }}
            onMouseEnter={(e) => e.target.style.backgroundColor = colors.primaryHover}
            onMouseLeave={(e) => e.target.style.backgroundColor = colors.primary}
          >
            See it in action
          </button>
        </div>
      </div>
    </section>
  )
}

export default HowItWorks