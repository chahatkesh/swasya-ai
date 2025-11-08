/// Swasya AI Spacing System
/// 
/// Consistent spacing scale for the entire application.
/// Based on Tailwind CSS spacing convention.

class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ============================================================================
  // SPACING SCALE (Multiples of 4px)
  // ============================================================================
  
  /// 4px
  static const double xs = 4.0;
  
  /// 8px - gap-2, p-2
  static const double sm = 8.0;
  
  /// 12px - p-3
  static const double md = 12.0;
  
  /// 16px - gap-4, p-4
  static const double lg = 16.0;
  
  /// 20px - p-5
  static const double xl = 20.0;
  
  /// 24px - gap-6, p-6
  static const double xxl = 24.0;
  
  /// 32px - gap-8, p-8
  static const double xxxl = 32.0;
  
  /// 40px - p-10
  static const double huge = 40.0;
  
  /// 48px - m-12
  static const double massive = 48.0;
  
  /// 64px - m-16
  static const double giant = 64.0;
  
  /// 80px - py-20 (Section padding)
  static const double section = 80.0;
  
  /// 128px - py-32 (Impact section padding)
  static const double impact = 128.0;

  // ============================================================================
  // SEMANTIC SPACING
  // ============================================================================
  
  /// Standard padding for cards
  static const double cardPadding = xxxl; // 32px
  
  /// Standard gap between components
  static const double componentGap = xxxl; // 32px
  
  /// Standard gap between grid items
  static const double gridGap = xxxl; // 32px
  
  /// Standard section vertical padding
  static const double sectionVertical = section; // 80px
  
  /// Standard section horizontal padding
  static const double sectionHorizontal = xxl; // 24px
  
  /// Button padding horizontal
  static const double buttonHorizontal = xxxl; // 32px
  
  /// Button padding vertical
  static const double buttonVertical = md; // 12px
  
  /// Input field padding horizontal
  static const double inputHorizontal = xl; // 20px
  
  /// Input field padding vertical
  static const double inputVertical = lg; // 16px
  
  /// List item padding
  static const double listItemPadding = lg; // 16px
  
  /// Standard border radius for cards
  static const double cardRadius = xxl; // 24px
  
  /// Standard border radius for buttons
  static const double buttonRadius = 999.0; // Full rounded
  
  /// Standard border radius for inputs
  static const double inputRadius = lg; // 16px
  
  /// Small border radius
  static const double radiusSmall = sm; // 8px
  
  /// Medium border radius
  static const double radiusMedium = md; // 12px
  
  /// Large border radius
  static const double radiusLarge = lg; // 16px
  
  /// Extra large border radius
  static const double radiusXLarge = xl; // 20px

  // ============================================================================
  // ICON SIZES
  // ============================================================================
  
  /// Small icon size - 16px
  static const double iconSmall = 16.0;
  
  /// Medium icon size - 24px
  static const double iconMedium = 24.0;
  
  /// Large icon size - 32px
  static const double iconLarge = 32.0;
  
  /// Extra large icon size - 48px
  static const double iconXLarge = 48.0;
  
  /// Icon container size - 56px
  static const double iconContainer = 56.0;

  // ============================================================================
  // ELEVATION/SHADOW
  // ============================================================================
  
  /// No elevation
  static const double elevationNone = 0.0;
  
  /// Subtle elevation
  static const double elevationSubtle = 2.0;
  
  /// Card elevation
  static const double elevationCard = 4.0;
  
  /// Modal elevation
  static const double elevationModal = 8.0;
  
  /// Drawer elevation
  static const double elevationDrawer = 16.0;
}
