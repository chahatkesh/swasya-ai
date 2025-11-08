import React from 'react'
import { colors } from '../../utils/colors'
import { FiShield, FiLock, FiUsers, FiLink, FiCloud, FiCheck } from 'react-icons/fi'

const SecurityCompliance = () => {
  const securityFeatures = [
    {
      id: 1,
      icon: FiLock,
      title: "End-to-end encryption",
      alt: "Lock icon for encryption"
    },
    {
      id: 2,
      icon: FiUsers,
      title: "Role-based access control",
      alt: "Users icon for access control"
    },
    {
      id: 3,
      icon: FiLink,
      title: "UHID linkage",
      alt: "Link icon for UHID integration"
    },
    {
      id: 4,
      icon: FiCloud,
      title: "Secure cloud storage",
      alt: "Cloud icon for secure storage"
    }
  ];

  return (
    <section 
      className="py-20 px-6" 
      style={{backgroundColor: colors.surfaceSecondary}}
    >
      <div className="max-w-6xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Content */}
          <div className="space-y-8">
            <h2 
              className="text-4xl md:text-5xl lg:text-6xl font-light leading-tight tracking-tight" 
              style={{color: colors.textPrimary}}
            >
              Privacy-first,{' '}
              <span className="font-medium" style={{color: colors.primary}}>medical-grade security</span>
            </h2>
            
            <p 
              className="text-xl md:text-2xl leading-relaxed font-light" 
              style={{color: colors.textSecondary}}
            >
              End-to-end encryption, role-based access control, UHID linkage, and secure cloud storage. 
              Designed to integrate with ABHA and national standards in future iterations.
            </p>

            {/* Security Features Checklist */}
            <div className="space-y-4">
              {securityFeatures.map((feature) => {
                const IconComponent = feature.icon;
                
                return (
                  <div key={feature.id} className="flex items-center gap-4">
                    <div 
                      className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                      style={{backgroundColor: colors.surface}}
                    >
                      <IconComponent 
                        size={20} 
                        style={{color: colors.primary}}
                        aria-label={feature.alt}
                      />
                    </div>
                    <p 
                      className="text-lg font-light" 
                      style={{color: colors.textPrimary}}
                    >
                      {feature.title}
                    </p>
                    <FiCheck 
                      size={20} 
                      style={{color: colors.primary}}
                      className="ml-auto"
                    />
                  </div>
                );
              })}
            </div>
          </div>

          {/* Visual */}
          <div className="flex justify-center">
            <div 
              className="w-80 h-80 rounded-full flex items-center justify-center"
              style={{
                backgroundColor: colors.surface,
                border: `2px solid ${colors.border}`
              }}
            >
              <div 
                className="w-32 h-32 rounded-full flex items-center justify-center"
                style={{backgroundColor: colors.primary}}
              >
                <FiShield 
                  size={64} 
                  style={{color: colors.secondary}}
                  aria-label="Security shield representing privacy and compliance"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default SecurityCompliance