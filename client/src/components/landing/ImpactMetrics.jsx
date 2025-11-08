import React from 'react'
import { colors } from '../../utils/colors'
import { FiClock, FiCheck, FiUsers, FiTrendingUp } from 'react-icons/fi'

const ImpactMetrics = () => {
  const metrics = [
    {
      id: 1,
      icon: FiClock,
      number: "5 minutes",
      description: "Average time saved per patient consultation",
      alt: "Clock icon representing time savings"
    },
    {
      id: 2,
      icon: FiCheck,
      number: "Zero paperwork",
      description: "Digital records eliminate manual documentation",
      alt: "Check icon representing paperwork elimination"
    },
    {
      id: 3,
      icon: FiUsers,
      number: "3 languages",
      description: "Hindi, English, and regional language support",
      alt: "Users icon representing language support"
    },
    {
      id: 4,
      icon: FiTrendingUp,
      number: "Better outcomes",
      description: "Faster diagnosis with complete patient history",
      alt: "Trending up icon representing improved outcomes"
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
            Real impact for{' '}
            <span className="font-medium" style={{color: colors.primary}}>healthcare teams</span>
          </h2>
          
          <p 
            className="text-xl md:text-2xl leading-relaxed max-w-3xl mx-auto font-light" 
            style={{color: colors.textSecondary}}
          >
            Simple changes that make a big difference in daily clinic operations.
          </p>
        </div>

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {metrics.map((metric) => {
            const IconComponent = metric.icon;
            
            return (
              <div 
                key={metric.id} 
                className="text-center space-y-6 rounded-2xl p-6 transition-all duration-300 hover:scale-105"
                style={{
                  backgroundColor: colors.surface,
                  border: `1px solid ${colors.border}`
                }}
              >
                {/* Icon */}
                <div className="flex justify-center">
                  <div 
                    className="w-16 h-16 rounded-2xl flex items-center justify-center"
                    style={{backgroundColor: colors.surfaceSecondary}}
                  >
                    <IconComponent 
                      size={28} 
                      style={{color: colors.primary}}
                      aria-label={metric.alt}
                    />
                  </div>
                </div>

                {/* Content */}
                <div className="space-y-3">
                  <h3 
                    className="text-2xl md:text-3xl font-medium" 
                    style={{color: colors.textPrimary}}
                  >
                    {metric.number}
                  </h3>
                  
                  <p 
                    className="text-base leading-relaxed font-light" 
                    style={{color: colors.textSecondary}}
                  >
                    {metric.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {/* Simple CTA */}
        <div className="text-center mt-16">
          <p 
            className="text-lg font-light mb-6" 
            style={{color: colors.textSecondary}}
          >
            Ready to experience these improvements?
          </p>
          <button 
            className="px-8 py-3 rounded-full text-base font-medium transition-colors duration-200"
            style={{
              backgroundColor: colors.primary,
              color: colors.secondary
            }}
            onMouseEnter={(e) => e.target.style.backgroundColor = colors.primaryHover}
            onMouseLeave={(e) => e.target.style.backgroundColor = colors.primary}
          >
            Start free trial
          </button>
        </div>
      </div>
    </section>
  )
}

export default ImpactMetrics