import React from 'react'
import { 
  Hero, 
  AboutUs,
  HowItWorks, 
  CoreFeatures, 
  ImpactMetrics, 
  FAQ, 
  MobileAppCTA,
  Footer 
} from '../components/landing'

const Landing = () => {
  return (
    <div className="min-h-screen">
      <Hero />
      <AboutUs />
      <ImpactMetrics />
      <HowItWorks />
      <CoreFeatures />
      <FAQ />
      <MobileAppCTA />
      <Footer />
    </div>
  )
}

export default Landing
