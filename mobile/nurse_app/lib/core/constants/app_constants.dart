/// Swasya AI Application Constants
/// 
/// Global constants used throughout the application.

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================================================
  // APP INFORMATION
  // ============================================================================
  
  static const String appName = 'Swasya AI';
  static const String appTagline = 'Turning dialogue into data and data into clarity.';
  static const String appVersion = '1.0.0';

  // ============================================================================
  // BREAKPOINTS (for responsive design)
  // ============================================================================
  
  /// Small screen breakpoint (Mobile)
  static const double breakpointSmall = 640;
  
  /// Medium screen breakpoint (Tablet)
  static const double breakpointMedium = 768;
  
  /// Large screen breakpoint (Desktop)
  static const double breakpointLarge = 1024;
  
  /// Extra large screen breakpoint
  static const double breakpointXLarge = 1280;

  // ============================================================================
  // MAXIMUM WIDTHS
  // ============================================================================
  
  /// Maximum content width for centered layouts
  static const double maxContentWidth = 1152; // 6xl in Tailwind
  
  /// Maximum form width
  static const double maxFormWidth = 640;
  
  /// Maximum card width
  static const double maxCardWidth = 400;

  // ============================================================================
  // GRID CONFIGURATION
  // ============================================================================
  
  /// Mobile grid columns
  static const int gridColumnsMobile = 1;
  
  /// Tablet grid columns
  static const int gridColumnsTablet = 2;
  
  /// Desktop grid columns
  static const int gridColumnsDesktop = 3;

  // ============================================================================
  // ANIMATION SETTINGS
  // ============================================================================
  
  /// Respect reduced motion preference
  static const bool respectReducedMotion = true;

  // ============================================================================
  // IMAGE/ASSET PATHS
  // ============================================================================
  
  static const String assetLogoPath = 'assets/images/logo.png';
  static const String assetIconPath = 'assets/icons/';
  
  // ============================================================================
  // DATE/TIME FORMATS
  // ============================================================================
  
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // ============================================================================
  // VALIDATION RULES
  // ============================================================================
  
  static const int phoneNumberLength = 10;
  static const int minAge = 0;
  static const int maxAge = 120;
  static const int uhidMinLength = 1;
  static const int uhidMaxLength = 50;
}
