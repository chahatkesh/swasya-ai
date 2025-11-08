/// Swasya AI Typography System
/// 
/// Typography scale for the entire application.
/// Based on Inter font family with PT Serif for special cases.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // ============================================================================
  // FONT FAMILIES
  // ============================================================================
  
  /// Primary font: Inter (Sans-serif)
  static TextStyle get _baseInter => GoogleFonts.inter();
  
  /// Serif font: PT Serif (for special cases)
  static TextStyle get _basePtSerif => GoogleFonts.ptSerif();

  // ============================================================================
  // HEADLINES (H1)
  // ============================================================================
  
  /// Hero headline - Extra large (Mobile: 36px, Tablet: 48px, Desktop: 56px)
  static TextStyle get h1Hero => _baseInter.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w300, // Light
    height: 1.25, // Line height
    letterSpacing: -0.025 * 36, // Tight letter spacing
    color: AppColors.textPrimary,
  );
  
  /// Hero headline for tablet/desktop
  static TextStyle get h1HeroLarge => h1Hero.copyWith(
    fontSize: 48,
    letterSpacing: -0.025 * 48,
  );
  
  /// Hero headline for large desktop
  static TextStyle get h1HeroXLarge => h1Hero.copyWith(
    fontSize: 56,
    letterSpacing: -0.025 * 56,
  );
  
  /// Accent span within hero headline
  static TextStyle get h1HeroAccent => h1Hero.copyWith(
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.primary,
  );

  // ============================================================================
  // SECTION HEADLINES (H2)
  // ============================================================================
  
  /// Section headline - Large (Mobile: 28px, Tablet: 36px, Desktop: 44px)
  static TextStyle get h2Section => _baseInter.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w300, // Light
    height: 1.25,
    letterSpacing: -0.025 * 28,
    color: AppColors.textPrimary,
  );
  
  /// Section headline for tablet/desktop
  static TextStyle get h2SectionLarge => h2Section.copyWith(
    fontSize: 36,
    letterSpacing: -0.025 * 36,
  );
  
  /// Section headline for large desktop
  static TextStyle get h2SectionXLarge => h2Section.copyWith(
    fontSize: 44,
    letterSpacing: -0.025 * 44,
  );

  // ============================================================================
  // CARD HEADLINES (H3)
  // ============================================================================
  
  /// Card headline - Medium (20px)
  static TextStyle get h3Card => _baseInter.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // BODY TEXT
  // ============================================================================
  
  /// Large body text (Subtitles) - 20px mobile, 24px tablet+
  static TextStyle get bodyLarge => _baseInter.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w300, // Light
    height: 1.625, // Relaxed line height
    color: AppColors.textSecondary,
  );
  
  /// Large body text for tablet/desktop
  static TextStyle get bodyLargeXL => bodyLarge.copyWith(
    fontSize: 24,
  );
  
  /// Regular body text - 16px
  static TextStyle get bodyRegular => _baseInter.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w300, // Light
    height: 1.625,
    color: AppColors.textSecondary,
  );
  
  /// Medium body text - 16px with medium weight
  static TextStyle get bodyMedium => bodyRegular.copyWith(
    fontWeight: FontWeight.w400, // Regular
  );
  
  /// Small body text (Micro-copy) - 14px
  static TextStyle get bodySmall => _baseInter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textTertiary,
  );
  
  /// Extra small text - 12px
  static TextStyle get bodyXSmall => _baseInter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // ============================================================================
  // PRODUCT TAGS & LABELS
  // ============================================================================
  
  /// Tag/label text - 14px uppercase
  static TextStyle get label => _baseInter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.025 * 14, // Wide letter spacing
    color: AppColors.textTertiary,
  );
  
  /// Label uppercase variant
  static TextStyle get labelUppercase => label.copyWith(
    // Use this with Text widget's textTransform or manually uppercase the text
  );
  
  /// Small label - 12px
  static TextStyle get labelSmall => _baseInter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.025 * 12,
    color: AppColors.textTertiary,
  );

  // ============================================================================
  // BUTTON TEXT
  // ============================================================================
  
  /// Primary button text - 16px medium
  static TextStyle get buttonPrimary => _baseInter.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.secondary,
  );
  
  /// Secondary button text - 16px medium
  static TextStyle get buttonSecondary => _baseInter.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
  
  /// Small button text - 14px medium
  static TextStyle get buttonSmall => _baseInter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
  );
  
  /// Text button - 14px medium with primary color
  static TextStyle get buttonText => _baseInter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // ============================================================================
  // SPECIAL TYPOGRAPHY
  // ============================================================================
  
  /// Serif body text (for special emphasis)
  static TextStyle get serifBody => _basePtSerif.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.75,
    color: AppColors.textPrimary,
  );
  
  /// Serif quote text
  static TextStyle get serifQuote => _basePtSerif.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.8,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  /// Apply size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
