import React from 'react'
import { colors } from '../../utils/colors'

const Footer = () => {

  return (
    <footer 
      className="py-12 px-6" 
      style={{backgroundColor: colors.background}}
    >
      <div className="max-w-4xl mx-auto">
        <div className="text-center space-y-6">
          {/* Brand */}
          <div>
            <h3 
              className="text-xl font-medium" 
              style={{color: colors.textPrimary}}
            >
              Swasya AI
            </h3>
            <p 
              className="text-base font-light mt-1" 
              style={{color: colors.textSecondary}}
            >
              From voice to diagnosis, instantly.
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer