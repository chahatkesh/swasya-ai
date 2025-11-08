import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FiMenu } from 'react-icons/fi';
import { colors } from '../utils/colors';

const SwasyaMap = () => {
  const navigate = useNavigate();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [lastRefresh] = useState(new Date());

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    });
  };

  const handleDashboardClick = () => {
    navigate('/dashboard');
  };

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  return (
    <div 
      className="h-screen flex flex-col"
      style={{ backgroundColor: colors.background }}
    >
      <div 
        className="h-16 flex items-center justify-between px-4 sm:px-6 border-b"
        style={{ 
          backgroundColor: colors.surface,
          borderColor: colors.border 
        }}
      >
        <div className="flex items-center gap-3 sm:gap-6">
          <h1 
            className="text-lg sm:text-xl font-ptserif font-medium"
            style={{ color: colors.textSecondary }}
          >
            Swasya AI
          </h1>
          
          {/* Desktop Dashboard Label & Navigation */}
          <div className="hidden sm:flex items-center gap-4">
            <div 
              className="h-4 w-px"
              style={{ backgroundColor: colors.border }}
            />
            <span 
              className="text-sm font-medium"
              style={{ color: colors.primary }}
            >
              Swasya Map
            </span>
          </div>
          
          {/* Desktop Navigation Buttons */}
          <div className="hidden lg:flex items-center gap-3 ml-6">
            <button
              onClick={handleDashboardClick}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 hover:opacity-80"
              style={{
                backgroundColor: colors.primary,
                color: colors.surface
              }}
            >
              Dashboard
            </button>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={toggleMobileMenu}
            className="lg:hidden p-2 rounded-lg transition-colors"
            style={{
              backgroundColor: isMobileMenuOpen ? colors.primary20 : 'transparent',
              color: colors.textPrimary
            }}
          >
            <FiMenu size={20} />
          </button>
        </div>

        <div className="flex items-center gap-2 sm:gap-4">
          {/* Mobile Navigation Dropdown */}
          {isMobileMenuOpen && (
            <div 
              className="absolute top-16 left-0 right-0 lg:hidden border-b z-50"
              style={{
                backgroundColor: colors.surface,
                borderColor: colors.border
              }}
            >
              <div className="p-4 space-y-3">
                <button
                  onClick={handleDashboardClick}
                  className="w-full flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                  style={{
                    backgroundColor: colors.primary,
                    color: colors.surface
                  }}
                >
                  Dashboard
                </button>
              </div>
            </div>
          )}
          
          <div className="text-right">
            <div 
              className="text-sm font-medium"
              style={{ color: colors.textPrimary }}
            >
              Dr. Shubham
            </div>
            <div 
              className="text-xs hidden sm:block"
              style={{ color: colors.textSecondary }}
            >
              Last refresh: {formatTime(lastRefresh)}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <h2 
            className="text-2xl font-ptserif font-medium mb-4"
            style={{ color: colors.textPrimary }}
          >
            Swasya Map
          </h2>
          <p 
            className="text-lg"
            style={{ color: colors.textSecondary }}
          >
            Map content will be added here
          </p>
        </div>
      </div>
    </div>
  );
};

export default SwasyaMap;
