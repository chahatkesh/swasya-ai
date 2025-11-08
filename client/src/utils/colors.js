// Color System Utilities
// Easy access to CSS custom properties in JavaScript

export const colors = {
  // Primary Color Palette
  background: 'var(--color-background)',
  textPrimary: 'var(--color-text-primary)',
  textSecondary: 'var(--color-text-secondary)',
  textTertiary: 'var(--color-text-tertiary)',
  
  // Interactive Colors
  primary: 'var(--color-primary)',
  primaryHover: 'var(--color-primary-hover)',
  secondary: 'var(--color-secondary)',
  accent: 'var(--color-accent)',
  
  // Semantic Colors
  success: 'var(--color-success)',
  info: 'var(--color-info)',
  warning: 'var(--color-warning)',
  error: 'var(--color-error)',
  
  // Border & Separator Colors
  border: 'var(--color-border)',
  separator: 'var(--color-separator)',
  
  // Surface Colors
  surface: 'var(--color-surface)',
  surfaceSecondary: 'var(--color-surface-secondary)',
  
  // Shadow & Overlay Colors
  shadow: 'var(--color-shadow)',
  overlay: 'var(--color-overlay)',
  
  // Opacity Variations
  primary10: 'var(--color-primary-10)',
  primary20: 'var(--color-primary-20)',
  primary50: 'var(--color-primary-50)',
  textPrimary50: 'var(--color-text-primary-50)',
  textPrimary70: 'var(--color-text-primary-70)',
};

// Helper function to get CSS custom property value
export const getCSSVariable = (variable) => {
  return getComputedStyle(document.documentElement).getPropertyValue(variable).trim();
};

// Helper function to set CSS custom property value
export const setCSSVariable = (variable, value) => {
  document.documentElement.style.setProperty(variable, value);
};

// Theme switching utility
export const setTheme = (themeName) => {
  document.documentElement.setAttribute('data-theme', themeName);
};

// Available themes
export const themes = {
  default: 'default',
  blue: 'blue',
  green: 'green',
};

// Color palette presets for easy switching
export const colorPalettes = {
  medical: {
    '--color-background': '#FDF9F6',
    '--color-text-primary': '#201510',
    '--color-text-secondary': '#9A7A6E',
    '--color-text-tertiary': '#B48A6E',
    '--color-primary': '#8A9663',
    '--color-primary-hover': '#7A8553',
    '--color-accent': '#D48B75',
  },
  
  corporate: {
    '--color-background': '#FFFFFF',
    '--color-text-primary': '#1F2937',
    '--color-text-secondary': '#6B7280',
    '--color-text-tertiary': '#9CA3AF',
    '--color-primary': '#3B82F6',
    '--color-primary-hover': '#2563EB',
    '--color-accent': '#F59E0B',
  },
  
  nature: {
    '--color-background': '#F7F9F7',
    '--color-text-primary': '#1F2F1F',
    '--color-text-secondary': '#4A6741',
    '--color-text-tertiary': '#7A9471',
    '--color-primary': '#10B981',
    '--color-primary-hover': '#059669',
    '--color-accent': '#F59E0B',
  }
};

// Function to apply a complete color palette
export const applyColorPalette = (paletteName) => {
  const palette = colorPalettes[paletteName];
  if (!palette) {
    console.warn(`Color palette "${paletteName}" not found`);
    return;
  }
  
  Object.entries(palette).forEach(([variable, value]) => {
    setCSSVariable(variable, value);
  });
};

export default colors;