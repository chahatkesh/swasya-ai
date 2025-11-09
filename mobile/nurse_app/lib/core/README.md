# Swasya AI - Core Theme System

This folder contains the complete theme system for the Swasya AI mobile application. All design tokens, colors, typography, and spacing are centralized here for consistency and easy maintenance.

## Structure

```
lib/core/
├── theme/
│   ├── app_colors.dart       # Color palette
│   ├── app_typography.dart   # Typography system
│   ├── app_theme.dart        # Main theme configuration
│   ├── app_spacing.dart      # Spacing system
│   ├── app_animations.dart   # Animation constants
│   └── theme_extensions.dart # Helper extensions
├── constants/
│   └── app_constants.dart    # App-wide constants
└── core.dart                 # Central export file
```

## Usage

### Import the theme system

```dart
import 'package:nurse_app/core/core.dart';
```

### Using Colors

```dart
// Direct access
Container(
  color: AppColors.background,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// Using context extension
Container(
  color: context.colors.background,
  child: Text('Hello'),
)
```

### Using Typography

```dart
// Direct access
Text(
  'Welcome to Swasya AI',
  style: AppTypography.h1Hero,
)

// Using context extension
Text(
  'Section Title',
  style: context.typography.h2Section,
)

// Modify text styles
Text(
  'Accent Text',
  style: AppTypography.bodyRegular.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  ),
)

// Using extension methods
Text(
  'Error Message',
  style: AppTypography.bodySmall.error.bold,
)
```

### Using Spacing

```dart
// Padding
Padding(
  padding: EdgeInsets.all(AppSpacing.cardPadding), // 32px
  child: Column(
    spacing: AppSpacing.componentGap, // 32px gap
    children: [...],
  ),
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.cardRadius), // 24px
  ),
)

// Using context extension
Container(
  padding: EdgeInsets.all(context.spacing.lg), // 16px
)
```

### Using Theme

Apply the theme in your app:

```dart
import 'package:nurse_app/core/core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme, // Apply Swasya AI theme
      home: const HomeScreen(),
    );
  }
}
```

### Responsive Design

```dart
// Check screen size
if (context.isSmallScreen) {
  // Mobile layout
} else if (context.isMediumScreen) {
  // Tablet layout
} else {
  // Desktop layout
}

// Responsive typography
Text(
  'Hero Title',
  style: context.isSmallScreen 
    ? AppTypography.h1Hero 
    : AppTypography.h1HeroLarge,
)
```

### Using Animations

```dart
AnimatedContainer(
  duration: AppAnimations.standard, // 200ms
  curve: AppAnimations.ease,
  transform: Matrix4.identity()
    ..scale(_isHovered ? AppAnimations.scaleStandard : 1.0),
  child: child,
)
```

### Creating Custom Buttons

```dart
// Primary button (already styled by theme)
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

// Custom gradient button
Container(
  decoration: BoxDecoration(
    gradient: AppColors.ctaGradient,
    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    child: Text('Gradient CTA'),
  ),
)
```

## Design Tokens

### Colors

All colors from the Swasya AI design system:
- `AppColors.background` - #FDF9F6 (Soft cream)
- `AppColors.textPrimary` - #201510 (Deep brownish-black)
- `AppColors.primary` - #8A9663 (Soft olive green)
- `AppColors.accent` - #D48B75 (Muted peach-pink)
- And many more...

### Typography Scale

Based on Inter font with PT Serif for special cases:
- `h1Hero` - 36px (mobile) / 48px (tablet) / 56px (desktop)
- `h2Section` - 28px / 36px / 44px
- `h3Card` - 20px
- `bodyLarge` - 20px / 24px
- `bodyRegular` - 16px
- `bodySmall` - 14px
- `label` - 14px uppercase

### Spacing System

Based on 4px increments:
- `xs` - 4px
- `sm` - 8px
- `md` - 12px
- `lg` - 16px
- `xl` - 20px
- `xxl` - 24px
- `xxxl` - 32px
- `cardPadding` - 32px
- `cardRadius` - 24px

## Changing Theme Colors

To change colors throughout the app, simply modify `app_colors.dart`:

```dart
class AppColors {
  static const Color primary = Color(0xFF8A9663); // Change this hex value
  // All components using primary color will update automatically
}
```

## Alternative Themes

To use alternative color schemes:

```dart
MaterialApp(
  theme: AppTheme.blueTheme, // Blue variant
  // or
  theme: AppTheme.greenTheme, // Green variant
)
```

## Best Practices

1. **Always use theme colors** - Never hardcode colors
2. **Use semantic spacing** - Use `cardPadding`, `componentGap` instead of raw numbers
3. **Responsive typography** - Use conditional sizing based on screen size
4. **Consistent animations** - Use `AppAnimations` constants
5. **Context extensions** - Use `context.colors.primary` for cleaner code

## Reference Web Design

This theme matches the landing page design at [client React app]. The same color palette, typography, and spacing ensure visual consistency across platforms.

---

**Swasya AI** - AI Co-Pilot for Primary Healthcare
