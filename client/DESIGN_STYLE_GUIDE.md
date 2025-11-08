# Swasya AI Landing Page Design Style Guide

## Overview
This document defines the comprehensive design system used across the Swasya AI landing page. The design follows a modern, minimal aesthetic with healthcare-inspired warm tones and clean typography.

---

## 🎨 Color Palette

### Primary Colors
```css
--color-background: #FDF9F6          /* Soft cream/off-white background */
--color-text-primary: #201510        /* Deep brownish-black for headings */
--color-text-secondary: #9A7A6E      /* Warm muted brown for body text */
--color-text-tertiary: #B48A6E       /* Warm beige-brown for micro-copy */
--color-primary: #8A9663             /* Soft olive green for CTAs */
--color-primary-hover: #7A8553       /* Darker olive green for hover states */
--color-secondary: #FFFFFF           /* Pure white */
--color-accent: #D48B75              /* Muted peach-pink for highlights */
```

### Surface Colors
```css
--color-surface: #FFFFFF             /* Card backgrounds */
--color-surface-secondary: #F5F0EB   /* Slightly darker cream for sections */
--color-border: #E5D5C8              /* Light warm beige for borders */
--color-separator: #B48A6E           /* Warm beige-brown for separators */
```

### Semantic Colors
```css
--color-success: #8A9663             /* Success states */
--color-info: #B48A6E                /* Informational states */
--color-warning: #D48B75             /* Warning states */
--color-error: #C85A54               /* Error states */
```

### Usage Guidelines
- **Background**: Soft cream (#FDF9F6) creates a warm, medical-friendly environment
- **Primary Text**: Deep brownish-black (#201510) for maximum readability
- **Interactive Elements**: Soft olive green (#8A9663) conveys healthcare and nature
- **Accent**: Muted peach-pink (#D48B75) for highlights and coming soon badges

---

## 📝 Typography

### Font Families
```css
/* Primary Font Stack */
font-family: 'Inter', 'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif;

/* Serif for Special Cases */
.font-ptserif {
  font-family: 'PT Serif', serif;
}
```

### Typography Scale

#### Headlines (H1)
```css
/* Hero Headlines */
font-size: 5xl md:6xl lg:7xl        /* 48px → 60px → 72px */
font-weight: light (300)
line-height: tight (1.25)
letter-spacing: tight (-0.025em)
color: var(--color-text-primary)

/* With accent spans */
span.accent {
  font-weight: medium (500)
  color: var(--color-primary)
}
```

#### Section Headlines (H2)
```css
font-size: 4xl md:5xl lg:6xl        /* 36px → 48px → 60px */
font-weight: light (300)
line-height: tight (1.25)
letter-spacing: tight (-0.025em)
color: var(--color-text-primary)
```

#### Card Headlines (H3)
```css
font-size: xl                       /* 20px */
font-weight: medium (500)
line-height: tight (1.25)
color: var(--color-text-primary)
```

#### Body Text
```css
/* Large Body (Subtitles) */
font-size: xl md:2xl                /* 20px → 24px */
font-weight: light (300)
line-height: relaxed (1.625)
color: var(--color-text-secondary)

/* Regular Body */
font-size: base                     /* 16px */
font-weight: light (300)
line-height: relaxed (1.625)
color: var(--color-text-secondary)

/* Small Body (Micro-copy) */
font-size: sm                       /* 14px */
font-weight: medium (500)
color: var(--color-text-tertiary)
```

#### Product Tags & Labels
```css
font-size: sm                       /* 14px */
font-weight: medium (500)
letter-spacing: wide (0.025em)
text-transform: uppercase
color: var(--color-text-tertiary)
```

---

## 🔘 Button Styles

### Primary Button
```css
.btn-primary {
  background-color: var(--color-primary);
  color: var(--color-secondary);
  border: none;
  border-radius: 9999px;              /* Full rounded */
  padding: 12px 32px;                 /* py-3 px-8 */
  font-size: 16px;                    /* text-base */
  font-weight: 500;                   /* font-medium */
  transition: background-color 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  background-color: var(--color-primary-hover);
}
```

### Secondary Button
```css
.btn-secondary {
  background-color: transparent;
  color: var(--color-primary);
  border: 1px solid var(--color-primary);
  border-radius: 9999px;              /* Full rounded */
  padding: 12px 32px;                 /* py-3 px-8 */
  font-size: 16px;                    /* text-base */
  font-weight: 500;                   /* font-medium */
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-secondary:hover {
  color: var(--color-primary-hover);
  border-color: var(--color-primary-hover);
}
```

### Text Button (Micro CTA)
```css
.btn-text {
  background: none;
  border: none;
  color: var(--color-primary);
  font-size: 14px;                    /* text-sm */
  font-weight: 500;                   /* font-medium */
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: color 200ms ease;
  cursor: pointer;
}

.btn-text:hover {
  color: var(--color-primary-hover);
}

.btn-text:disabled {
  color: var(--color-text-tertiary);
  cursor: not-allowed;
}
```

---

## 📦 Component Patterns

### Section Layout
```css
.section {
  padding: 80px 24px;                 /* py-20 px-6 */
  max-width: 1152px;                  /* max-w-6xl */
  margin: 0 auto;                     /* mx-auto */
}

.section-header {
  text-align: center;
  margin-bottom: 64px;                /* mb-16 */
  space-y: 24px;                      /* space-y-6 */
}
```

### Card Components
```css
.card {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 24px;                /* rounded-3xl */
  padding: 32px;                      /* p-8 */
  transition: transform 300ms ease;
}

.card:hover {
  transform: scale(1.05);             /* hover:scale-105 */
}
```

### Icon Containers
```css
.icon-container {
  width: 56px;                        /* w-14 */
  height: 56px;                       /* h-14 */
  border-radius: 16px;                /* rounded-2xl */
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-primary);
}

.icon-container-secondary {
  background-color: var(--color-surface-secondary);
}

.icon-container svg {
  width: 24px;
  height: 24px;
  color: var(--color-secondary);
}
```

---

## 🎯 Interactive Elements

### Hover Effects
- **Scale Transform**: `transform: scale(1.05)` for cards
- **Scale Transform**: `transform: scale(1.02)` for list items
- **Color Transitions**: 200ms ease for all color changes
- **Button Hovers**: Background color changes with smooth transitions

### Transitions
```css
/* Standard transition for most elements */
transition: all 200ms ease;

/* Transform transitions for cards */
transition: transform 300ms ease;

/* Color-only transitions */
transition: color 200ms ease;
transition: background-color 200ms ease;
```

### States
- **Disabled State**: Reduced opacity and `cursor: not-allowed`
- **Coming Soon**: Special badge with reduced opacity (0.6)
- **Active/Focus**: Consistent with hover states

---

## 📐 Spacing System

### Consistent Spacing Scale (Tailwind-based)
```css
/* Small spacing */
gap: 8px;          /* gap-2 */
gap: 16px;         /* gap-4 */
gap: 24px;         /* gap-6 */
gap: 32px;         /* gap-8 */

/* Medium spacing */
padding: 24px;     /* p-6 */
padding: 32px;     /* p-8 */
margin: 48px;      /* m-12 */
margin: 64px;      /* m-16 */

/* Large spacing */
padding: 80px 24px; /* py-20 px-6 */
padding: 128px 24px; /* py-32 px-6 */
```

### Section Spacing
- **Component Spacing**: 32px between major components within a section
- **Section Spacing**: 80px vertical padding for most sections
- **Impact Section**: 128px vertical padding for emphasis
- **Grid Gaps**: 32px between grid items

---

## 🔧 Special Components

### Tag/Badge Component
```css
.tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;                  /* px-4 py-2 */
  border-radius: 9999px;              /* rounded-full */
  background-color: var(--color-primary);
  font-size: 14px;                    /* text-sm */
  font-weight: 500;                   /* font-medium */
  letter-spacing: 0.025em;            /* tracking-wide */
  color: var(--color-secondary);
}

.tag-dot {
  width: 8px;                         /* w-2 */
  height: 8px;                        /* h-2 */
  border-radius: 50%;                 /* rounded-full */
  background-color: var(--color-secondary);
}
```

### Coming Soon Badge
```css
.coming-soon-badge {
  font-size: 12px;                    /* text-xs */
  padding: 4px 8px;                   /* px-2 py-1 */
  border-radius: 9999px;              /* rounded-full */
  font-weight: 500;                   /* font-medium */
  background-color: var(--color-text-tertiary);
  color: var(--color-secondary);
}
```

### Gradient CTA Section
```css
.gradient-cta {
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-accent) 50%, var(--color-primary) 100%);
  border-radius: 24px;                /* rounded-3xl */
  padding: 64px 48px;                 /* px-12 py-16 */
  position: relative;
  overflow: hidden;
}
```

---

## 📱 Responsive Design

### Breakpoints
```css
/* Mobile-first approach */
/* sm: 640px */
/* md: 768px */
/* lg: 1024px */
/* xl: 1280px */
```

### Typography Responsiveness
```css
/* Headlines scale down on smaller screens */
.hero-headline {
  font-size: 3rem;                    /* 48px mobile */
}

@media (min-width: 768px) {
  .hero-headline {
    font-size: 3.75rem;               /* 60px tablet */
  }
}

@media (min-width: 1024px) {
  .hero-headline {
    font-size: 4.5rem;                /* 72px desktop */
  }
}
```

### Grid Responsiveness
```css
/* Feature grids */
.features-grid {
  display: grid;
  grid-template-columns: 1fr;        /* 1 column mobile */
  gap: 32px;
}

@media (min-width: 768px) {
  .features-grid {
    grid-template-columns: repeat(2, 1fr); /* 2 columns tablet */
  }
}

@media (min-width: 1024px) {
  .features-grid {
    grid-template-columns: repeat(3, 1fr); /* 3 columns desktop */
  }
}
```

---

## ♿ Accessibility

### Color Contrast
- All text meets WCAG AA standards
- Primary text (#201510) on background (#FDF9F6): High contrast
- Secondary text (#9A7A6E) on background: Adequate contrast

### Interactive Elements
- All buttons have clear focus states
- Icon buttons include `aria-label` attributes
- Hover states are clearly distinguishable

### Semantic HTML
- Proper heading hierarchy (h1 → h2 → h3)
- Semantic section elements
- Meaningful alt text for decorative elements

---

## 🔄 Animation Guidelines

### Micro-interactions
- **Hover Animations**: Scale transforms (1.02 - 1.05)
- **Button Feedback**: Color transitions (200ms)
- **Arrow Icons**: Translate X on hover (4px)

### Performance
- Use `transform` and `opacity` for animations
- Avoid animating layout properties
- Respect `prefers-reduced-motion` settings

---

## 📏 Implementation Notes

### CSS Custom Properties
All colors are defined as CSS custom properties for easy theming and consistency.

### Utility-First Approach
The design uses Tailwind CSS utilities with custom components for complex patterns.

### Component Reusability
Common patterns (buttons, cards, sections) are designed for maximum reusability across the application.

### Performance Considerations
- Minimal use of box-shadows for better performance
- Optimized transitions and animations
- Efficient grid layouts

---

This style guide ensures consistency across the entire Swasya AI landing page and provides clear guidelines for future development and design iterations.