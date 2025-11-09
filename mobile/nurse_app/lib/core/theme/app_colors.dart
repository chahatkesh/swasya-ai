/// Swasya AI Color System - Medical AI Theme
/// 
/// Color palette for the entire application.
/// Change colors here to update throughout the app.

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // PRIMARY COLOR PALETTE
  // ============================================================================
  
  /// Soft cream/off-white background - Main app background
  static const Color background = Color(0xFFFDF9F6);
  
  /// Deep brownish-black serif - Primary text color
  static const Color textPrimary = Color(0xFF201510);
  
  /// Warm muted brown - Secondary text color
  static const Color textSecondary = Color(0xFF9A7A6E);
  
  /// Warm beige-brown - Tertiary text color (micro-copy)
  static const Color textTertiary = Color(0xFFB48A6E);

  // ============================================================================
  // INTERACTIVE COLORS
  // ============================================================================
  
  /// Soft olive green - Primary brand color
  static const Color primary = Color(0xFF8A9663);
  
  /// Darker olive green - Hover/pressed state
  static const Color primaryHover = Color(0xFF7A8553);
  
  /// Pure white - Secondary color
  static const Color secondary = Color(0xFFFFFFFF);
  
  /// Muted peach-pink - Accent color for highlights
  static const Color accent = Color(0xFFD48B75);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================
  
  /// Success state - Soft olive green
  static const Color success = Color(0xFF8A9663);
  
  /// Info state - Warm beige-brown
  static const Color info = Color(0xFFB48A6E);
  
  /// Warning state - Muted peach-pink
  static const Color warning = Color(0xFFD48B75);
  
  /// Error state - Muted red
  static const Color error = Color(0xFFC85A54);

  // ============================================================================
  // BORDER & SEPARATOR COLORS
  // ============================================================================
  
  /// Light warm beige - Default border color
  static const Color border = Color(0xFFE5D5C8);
  
  /// Warm beige-brown - Separator lines
  static const Color separator = Color(0xFFB48A6E);

  // ============================================================================
  // SURFACE COLORS
  // ============================================================================
  
  /// Pure white - Card backgrounds
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Slightly darker cream - Secondary surface color
  static const Color surfaceSecondary = Color(0xFFF5F0EB);

  // ============================================================================
  // SHADOW & OVERLAY COLORS
  // ============================================================================
  
  /// Subtle shadow using primary text at 10% opacity
  static const Color shadow = Color(0x1A201510);
  
  /// Overlay using primary text at 50% opacity
  static const Color overlay = Color(0x80201510);

  // ============================================================================
  // OPACITY VARIATIONS
  // ============================================================================
  
  /// Primary color at 10% opacity
  static const Color primary10 = Color(0x1A8A9663);
  
  /// Primary color at 20% opacity
  static const Color primary20 = Color(0x338A9663);
  
  /// Primary color at 50% opacity
  static const Color primary50 = Color(0x808A9663);
  
  /// Text primary at 50% opacity
  static const Color textPrimary50 = Color(0x80201510);
  
  /// Text primary at 70% opacity
  static const Color textPrimary70 = Color(0xB3201510);

  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================
  
  /// CTA gradient: Primary → Accent → Primary
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      accent,
      primary,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // ALTERNATIVE THEME COLORS (for future use)
  // ============================================================================
  
  /// Blue theme variant
  static const Color blueThemePrimary = Color(0xFF3B82F6);
  static const Color blueThemePrimaryHover = Color(0xFF2563EB);
  static const Color blueThemeTertiary = Color(0xFF6B7280);
  
  /// Green theme variant
  static const Color greenThemePrimary = Color(0xFF10B981);
  static const Color greenThemePrimaryHover = Color(0xFF059669);
  static const Color greenThemeTertiary = Color(0xFF6B7280);
}
