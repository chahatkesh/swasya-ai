import React from 'react'
import { colors } from '../../utils/colors'

const Hero = () => {
  const buttonStyles = {
    primary: {
      backgroundColor: colors.primary,
      color: colors.secondary,
      border: 'none',
    },
    secondary: {
      backgroundColor: 'transparent',
      color: colors.primary,
      border: `1px solid ${colors.primary}`,
    }
  };

  const handleButtonHover = (e, type) => {
    if (type === 'primary') {
      e.target.style.backgroundColor = colors.primaryHover;
    } else {
      e.target.style.color = colors.primaryHover;
      e.target.style.borderColor = colors.primaryHover;
    }
  };

  const handleButtonLeave = (e, type) => {
    if (type === 'primary') {
      e.target.style.backgroundColor = colors.primary;
    } else {
      e.target.style.color = colors.primary;
      e.target.style.borderColor = colors.primary;
    }
  };

  return (
    <section 
      className="h-screen flex items-center justify-center px-6" 
      style={{backgroundColor: colors.background}}
    >
      <div className="max-w-4xl mx-auto text-center">
        <div className="space-y-12">
          {/* Subtle product tag */}
          <div className="inline-block">
            <span 
              className="text-sm font-medium tracking-wide uppercase" 
              style={{color: colors.textTertiary}}
            >
              Swasya AI
            </span>
          </div>

          {/* Main Headline */}
          <div className="space-y-8">
            <h1 
              className="text-5xl md:text-6xl lg:text-7xl font-light leading-tight tracking-tight" 
              style={{color: colors.textPrimary}}
            >
              Turning dialogue into{' '}
              <span className="font-medium" style={{color: colors.primary}}>data</span>{' '}
              and data into{' '}
              <span className="font-medium" style={{color: colors.primary}}>clarity</span>.
            </h1>
            
            <p 
              className="text-xl md:text-2xl leading-relaxed max-w-3xl mx-auto font-light" 
              style={{color: colors.textSecondary}}
            >
              AI-powered medical transcription that listens, reads and summarizes, 
              so doctors get the complete patient story before consultation begins.
            </p>
          </div>

          {/* Clean CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <button 
              className="px-8 py-3 rounded-full text-base font-medium transition-colors duration-200"
              style={buttonStyles.primary}
              onMouseEnter={(e) => handleButtonHover(e, 'primary')}
              onMouseLeave={(e) => handleButtonLeave(e, 'primary')}
            >
              Get started
            </button>
            <button 
              className="px-8 py-3 text-base font-medium transition-colors duration-200 rounded-full"
              style={buttonStyles.secondary}
              onMouseEnter={(e) => handleButtonHover(e, 'secondary')}
              onMouseLeave={(e) => handleButtonLeave(e, 'secondary')}
            >
              Watch demo
            </button>
          </div>

          {/* Minimal feature highlights */}
          <div 
            className="flex flex-wrap justify-center items-center gap-8 text-sm font-light" 
            style={{color: colors.textSecondary}}
          >
            <span>Real-time transcription</span>
            <span style={{color: colors.separator}}>•</span>
            <span>AI medical insights</span>
            <span style={{color: colors.separator}}>•</span>
            <span>Seamless integration</span>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Hero