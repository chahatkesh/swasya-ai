/// Swasya AI Theme Extensions
/// 
/// Convenient extension methods for accessing theme values.

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

extension ThemeExtension on BuildContext {
  /// Get current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Get current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Quick access to app colors
  AppColorsAccess get colors => AppColorsAccess();
  
  /// Quick access to app typography
  AppTypographyAccess get typography => AppTypographyAccess();
  
  /// Quick access to app spacing
  AppSpacingAccess get spacing => AppSpacingAccess();
  
  /// Check if device is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Check if screen is small (< 600px)
  bool get isSmallScreen => MediaQuery.of(this).size.width < 600;
  
  /// Check if screen is medium (600px - 840px)
  bool get isMediumScreen {
    final width = MediaQuery.of(this).size.width;
    return width >= 600 && width < 840;
  }
  
  /// Check if screen is large (>= 840px)
  bool get isLargeScreen => MediaQuery.of(this).size.width >= 840;
  
  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
}

/// Helper class for accessing colors
class AppColorsAccess {
  Color get background => AppColors.background;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;
  Color get textTertiary => AppColors.textTertiary;
  Color get primary => AppColors.primary;
  Color get primaryHover => AppColors.primaryHover;
  Color get secondary => AppColors.secondary;
  Color get accent => AppColors.accent;
  Color get success => AppColors.success;
  Color get info => AppColors.info;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
  Color get border => AppColors.border;
  Color get separator => AppColors.separator;
  Color get surface => AppColors.surface;
  Color get surfaceSecondary => AppColors.surfaceSecondary;
  Color get shadow => AppColors.shadow;
  Color get overlay => AppColors.overlay;
  LinearGradient get ctaGradient => AppColors.ctaGradient;
}

/// Helper class for accessing typography
class AppTypographyAccess {
  TextStyle get h1Hero => AppTypography.h1Hero;
  TextStyle get h1HeroLarge => AppTypography.h1HeroLarge;
  TextStyle get h2Section => AppTypography.h2Section;
  TextStyle get h3Card => AppTypography.h3Card;
  TextStyle get bodyLarge => AppTypography.bodyLarge;
  TextStyle get bodyRegular => AppTypography.bodyRegular;
  TextStyle get bodyMedium => AppTypography.bodyMedium;
  TextStyle get bodySmall => AppTypography.bodySmall;
  TextStyle get label => AppTypography.label;
  TextStyle get buttonPrimary => AppTypography.buttonPrimary;
  TextStyle get buttonSecondary => AppTypography.buttonSecondary;
}

/// Helper class for accessing spacing
class AppSpacingAccess {
  double get xs => AppSpacing.xs;
  double get sm => AppSpacing.sm;
  double get md => AppSpacing.md;
  double get lg => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
  double get xxxl => AppSpacing.xxxl;
  double get cardPadding => AppSpacing.cardPadding;
  double get cardRadius => AppSpacing.cardRadius;
  double get buttonRadius => AppSpacing.buttonRadius;
  double get iconMedium => AppSpacing.iconMedium;
  double get iconLarge => AppSpacing.iconLarge;
}

/// Extension for easily applying text styles with color
extension TextStyleExtension on TextStyle {
  /// Apply primary text color
  TextStyle get primary => copyWith(color: AppColors.textPrimary);
  
  /// Apply secondary text color
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  
  /// Apply tertiary text color
  TextStyle get tertiary => copyWith(color: AppColors.textTertiary);
  
  /// Apply brand primary color
  TextStyle get brandPrimary => copyWith(color: AppColors.primary);
  
  /// Apply accent color
  TextStyle get accent => copyWith(color: AppColors.accent);
  
  /// Apply white color
  TextStyle get white => copyWith(color: AppColors.secondary);
  
  /// Apply error color
  TextStyle get error => copyWith(color: AppColors.error);
  
  /// Apply custom color
  TextStyle colored(Color color) => copyWith(color: color);
  
  /// Apply bold weight
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  
  /// Apply semi-bold weight
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  
  /// Apply medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  
  /// Apply light weight
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
}
