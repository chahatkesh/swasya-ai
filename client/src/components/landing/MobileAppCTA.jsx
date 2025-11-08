import React from 'react'
import { colors } from '../../utils/colors'

const MobileAppCTA = () => {
  const handleDownload = () => {
    // For demo purposes - could link to app stores
    alert('Mobile app download would be initiated here');
  };

  const gradientStyle = {
    background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.accent} 50%, ${colors.primary} 100%)`,
    borderRadius: '24px',
  };

  return (
    <section 
      className="py-20 px-6" 
      style={{backgroundColor: colors.background}}
    >
      <div className="md:max-w-[70vw] mx-auto">
        <div 
          className="relative overflow-hidden px-12 py-16 text-center"
          style={gradientStyle}
        >
          {/* Decorative elements matching the attached design */}
          <div className="absolute top-6 left-6">
            <div className="flex space-x-2">
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.3}}></div>
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.2}}></div>
            </div>
          </div>
          
          <div className="absolute top-6 right-6">
            <div className="grid grid-cols-2 gap-2">
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.3}}></div>
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.2}}></div>
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.2}}></div>
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.3}}></div>
            </div>
          </div>

          <div className="absolute bottom-6 left-6">
            <div className="flex space-x-2">
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.2}}></div>
              <div className="w-3 h-3 rounded-full" style={{backgroundColor: colors.secondary, opacity: 0.3}}></div>
            </div>
          </div>

          {/* Brand placeholder */}
          <div className="mb-8">
            <h3 className="text-lg font-medium mb-2" style={{color: colors.secondary}}>Swasya AI</h3>
          </div>

          {/* Main content */}
          <div className="max-w-2xl mx-auto space-y-8">
            <h2 className="text-lg md:text-xl font-light" style={{color: colors.secondary, opacity: 0.9}}>
              Download our mobile app for Nurses and Compounders to streamline patient care 
              and medical documentation on the go.
            </h2>
            <button 
              onClick={handleDownload}
              className="inline-flex items-center px-8 py-4 rounded-full text-md font-medium transition-all duration-200 hover:shadow-lg transform hover:scale-105"
              style={{
                backgroundColor: colors.secondary,
                color: colors.textPrimary,
              }}
              onMouseEnter={(e) => {
                e.target.style.backgroundColor = colors.surface;
              }}
              onMouseLeave={(e) => {
                e.target.style.backgroundColor = colors.secondary;
              }}
            >
              Download Mobile App
            </button>
          </div>
        </div>
      </div>
    </section>
  )
}

export default MobileAppCTA