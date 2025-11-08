import React from 'react'
import { colors } from '../../utils/colors'
import { 
  FiMic, 
  FiMonitor, 
  FiMap,
  FiLink,
  FiWifi,
  FiArrowRight
} from 'react-icons/fi'
import { IoMdQrScanner } from 'react-icons/io'

const CoreFeatures = () => {
  const features = [
    {
      id: 1,
      icon: FiMic,
      title: "Swasya Listen",
      description: "Real-time multi-language transcription and one-line medical summaries.",
      microcopy: "Converts conversation to concise clinical notes.",
      cta: "Try voice capture",
      alt: "Microphone icon for voice transcription"
    },
    {
      id: 2,
      icon: IoMdQrScanner,
      title: "Swasya Scan",
      description: "OCR scanning that converts prescriptions and reports into structured history.",
      microcopy: "No more lost paper reports.",
      cta: "See OCR demo",
      alt: "Scanner icon for document processing"
    },
    {
      id: 3,
      icon: FiMonitor,
      title: "Swasya Sync",
      description: "Live web dashboard showing queue, transcripts, summaries and annotated records.",
      microcopy: "Doctor-ready patient context at a glance.",
      cta: "View dashboard",
      alt: "Monitor icon for dashboard interface"
    },
    {
      id: 4,
      icon: FiMap,
      title: "Swasya Map",
      description: "Localized outbreak maps and hotspot alerts for doctors and administrators.",
      microcopy: "Early detection and targeted responses.",
      cta: "Explore maps",
      alt: "Map icon for regional analytics"
    },
    {
      id: 5,
      icon: FiLink,
      title: "Secure UHID Linking",
      description: "Patient records linked to unique IDs for continuity of care.",
      microcopy: "Consistent history, less repetition.",
      cta: "Learn about UHID",
      alt: "Link icon for patient record connectivity"
    },
    {
      id: 6,
      icon: FiWifi,
      title: "Offline-first Support",
      description: "Works in low-connectivity settings with sync on restore.",
      microcopy: "Designed for rural PHCs.",
      cta: "Coming soon",
      alt: "Wifi icon for connectivity features",
      isComingSoon: true
    }
  ];

  return (
    <section 
      className="py-20 px-6" 
      style={{backgroundColor: colors.surfaceSecondary}}
    >
      <div className="max-w-6xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-6">
          <h2 
            className="text-4xl md:text-5xl lg:text-6xl font-light leading-tight tracking-tight" 
            style={{color: colors.textPrimary}}
          >
            Core features — built for{' '}
            <span className="font-medium" style={{color: colors.primary}}>speed and clarity</span>
          </h2>
          
          <p 
            className="text-xl md:text-2xl leading-relaxed max-w-3xl mx-auto font-light" 
            style={{color: colors.textSecondary}}
          >
            Everything a PHC needs to capture, summarize and act on patient data.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature) => {
            const IconComponent = feature.icon;
            
            return (
              <div 
                key={feature.id} 
                className="rounded-3xl p-8 space-y-6 transition-all duration-300 hover:scale-105"
                style={{
                  backgroundColor: colors.surface,
                  border: `1px solid ${colors.border}`
                }}
              >
                {/* Icon */}
                <div className="flex justify-start">
                  <div 
                    className="w-14 h-14 rounded-2xl flex items-center justify-center"
                    style={{
                      backgroundColor: feature.isComingSoon ? colors.textTertiary : colors.primary,
                      opacity: feature.isComingSoon ? 0.6 : 1
                    }}
                  >
                    <IconComponent 
                      size={24} 
                      style={{color: colors.secondary}}
                      aria-label={feature.alt}
                    />
                  </div>
                </div>

                {/* Content */}
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    <h3 
                      className="text-xl font-medium leading-tight" 
                      style={{color: colors.textPrimary}}
                    >
                      {feature.title}
                    </h3>
                    {feature.isComingSoon && (
                      <span 
                        className="text-xs px-2 py-1 rounded-full font-medium"
                        style={{
                          backgroundColor: colors.textTertiary,
                          color: colors.secondary
                        }}
                      >
                        Future
                      </span>
                    )}
                  </div>
                  
                  <p 
                    className="text-base leading-relaxed font-light" 
                    style={{color: colors.textSecondary}}
                  >
                    {feature.description}
                  </p>
                  
                  <p 
                    className="text-sm font-medium" 
                    style={{color: colors.textTertiary}}
                  >
                    {feature.microcopy}
                  </p>
                </div>

                {/* Micro CTA */}
                <div className="pt-2">
                  <button 
                    className="group flex items-center gap-2 text-sm font-medium transition-colors duration-200"
                    style={{
                      color: feature.isComingSoon ? colors.textTertiary : colors.primary
                    }}
                    disabled={feature.isComingSoon}
                    onMouseEnter={(e) => {
                      if (!feature.isComingSoon) {
                        e.target.style.color = colors.primaryHover;
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (!feature.isComingSoon) {
                        e.target.style.color = colors.primary;
                      }
                    }}
                  >
                    {feature.cta}
                    {!feature.isComingSoon && (
                      <FiArrowRight 
                        size={14} 
                        className="transition-transform duration-200 group-hover:translate-x-1"
                      />
                    )}
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {/* Optional Bottom CTA */}
        <div className="text-center mt-16 space-y-4">
          <p 
            className="text-lg font-light" 
            style={{color: colors.textSecondary}}
          >
            Ready to streamline your clinic workflow?
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <button 
              className="px-8 py-3 rounded-full text-base font-medium transition-colors duration-200"
              style={{
                backgroundColor: colors.primary,
                color: colors.secondary
              }}
              onMouseEnter={(e) => e.target.style.backgroundColor = colors.primaryHover}
              onMouseLeave={(e) => e.target.style.backgroundColor = colors.primary}
            >
              Schedule a demo
            </button>
            <button 
              className="px-8 py-3 text-base font-medium transition-colors duration-200 rounded-full"
              style={{
                backgroundColor: 'transparent',
                color: colors.primary,
                border: `1px solid ${colors.primary}`
              }}
              onMouseEnter={(e) => {
                e.target.style.color = colors.primaryHover;
                e.target.style.borderColor = colors.primaryHover;
              }}
              onMouseLeave={(e) => {
                e.target.style.color = colors.primary;
                e.target.style.borderColor = colors.primary;
              }}
            >
              Contact sales
            </button>
          </div>
        </div>
      </div>
    </section>
  )
}

export default CoreFeatures