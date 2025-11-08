import React from 'react'
import { 
  Hero, 
  AboutUs,
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
      <AboutUs />
      <ImpactMetrics />
      <HowItWorks />
      <CoreFeatures />
      <FAQ />
      <Footer />
    </div>
  )
}

export default Landing
