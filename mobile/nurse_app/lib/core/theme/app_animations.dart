/// Swasya AI Animation Configuration
/// 
/// Consistent animation timings and curves for the entire application.

import 'package:flutter/material.dart';

class AppAnimations {
  // Private constructor to prevent instantiation
  AppAnimations._();

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  
  /// Fast animation - 150ms (micro-interactions)
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Standard animation - 200ms (most transitions)
  static const Duration standard = Duration(milliseconds: 200);
  
  /// Medium animation - 300ms (cards, transforms)
  static const Duration medium = Duration(milliseconds: 300);
  
  /// Slow animation - 400ms (complex transitions)
  static const Duration slow = Duration(milliseconds: 400);
  
  /// Very slow animation - 600ms (page transitions)
  static const Duration verySlow = Duration(milliseconds: 600);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================
  
  /// Standard ease curve (default for most animations)
  static const Curve ease = Curves.easeInOut;
  
  /// Ease in curve (for exits)
  static const Curve easeIn = Curves.easeIn;
  
  /// Ease out curve (for entrances)
  static const Curve easeOut = Curves.easeOut;
  
  /// Emphasized ease curve (Material 3 standard)
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  
  /// Bounce curve (for playful interactions)
  static const Curve bounce = Curves.bounceOut;

  // ============================================================================
  // SCALE TRANSFORMS
  // ============================================================================
  
  /// Subtle scale for list items (1.02)
  static const double scaleSubtle = 1.02;
  
  /// Standard scale for cards (1.05)
  static const double scaleStandard = 1.05;
  
  /// Large scale for buttons (1.1)
  static const double scaleLarge = 1.1;

  // ============================================================================
  // TRANSLATE TRANSFORMS
  // ============================================================================
  
  /// Small translate (4px) - for arrow icons on hover
  static const double translateSmall = 4.0;
  
  /// Medium translate (8px) - for slide effects
  static const double translateMedium = 8.0;
  
  /// Large translate (16px) - for larger slide effects
  static const double translateLarge = 16.0;

  // ============================================================================
  // OPACITY VALUES
  // ============================================================================
  
  /// Disabled opacity
  static const double opacityDisabled = 0.5;
  
  /// Subtle opacity
  static const double opacitySubtle = 0.7;
  
  /// Coming soon badge opacity
  static const double opacityComingSoon = 0.6;
  
  /// Full opacity
  static const double opacityFull = 1.0;

  // ============================================================================
  // PRESET ANIMATIONS
  // ============================================================================
  
  /// Fade in animation
  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: easeOut),
    );
  }
  
  /// Fade out animation
  static Animation<double> fadeOut(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: easeIn),
    );
  }
  
  /// Scale up animation
  static Animation<double> scaleUp(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: emphasized),
    );
  }
  
  /// Scale down animation
  static Animation<double> scaleDown(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: controller, curve: emphasized),
    );
  }
  
  /// Slide in from bottom
  static Animation<Offset> slideInFromBottom(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: emphasized));
  }
  
  /// Slide in from right
  static Animation<Offset> slideInFromRight(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: emphasized));
  }
}
