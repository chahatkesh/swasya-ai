import React from 'react'
import { Routes, Route } from 'react-router-dom'
import Landing from './pages/Landing'
import Dashboard from './pages/Dashboard'
import Admin from './pages/Admin'
import SwasyaMap from './pages/SwasyaMap'

const App = () => {
  return (
    <main>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/admin" element={<Admin />} />
        <Route path="/swasya-map" element={<SwasyaMap />} />
      </Routes>
    </main>
  )
}

export default App