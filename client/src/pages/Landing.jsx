import React from 'react'
import { 
  Hero, 
  HowItWorks, 
  CoreFeatures, 
  ImpactMetrics, 
  FAQ, 
  Footer 
} from '../components/landing'

const Landing = () => {
  return (
    <div className="min-h-screen">
      <Hero />
      <ImpactMetrics />
      <HowItWorks />
      <CoreFeatures />
      <FAQ />
      <Footer />
    </div>
  )
}

export default Landing
