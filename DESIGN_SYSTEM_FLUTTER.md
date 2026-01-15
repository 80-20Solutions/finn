# Fin Design System - Flutter Implementation Guide

## Color Palette

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary Palette - Earth & Growth
  static const Color sageGreen = Color(0xFF7A9B76);
  static const Color deepForest = Color(0xFF3D5A3C);
  static const Color terracotta = Color(0xFFD4846A);
  static const Color warmSand = Color(0xFFF5EFE7);
  static const Color cream = Color(0xFFFFFBF5);

  // Accents
  static const Color amberHoney = Color(0xFFE8B44F);
  static const Color softCoral = Color(0xFFE88D7A);
  static const Color mistyBlue = Color(0xFFA8BFC4);
  static const Color charcoal = Color(0xFF2C3333);

  // Semantic Colors
  static const Color success = sageGreen;
  static const Color warning = amberHoney;
  static const Color error = softCoral;
  static const Color info = mistyBlue;

  // Backgrounds
  static const Color bgPrimary = cream;
  static const Color bgSecondary = warmSand;
  static const Color bgCard = Colors.white;

  // Text
  static const Color textPrimary = charcoal;
  static const Color textSecondary = Color(0xFF5A6363);
  static const Color textTertiary = Color(0xFF8A9494);
}
```

## Typography

```dart
// lib/core/theme/app_text_styles.dart

import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display - for large amounts and hero numbers
  static TextStyle display = GoogleFonts.crimsonPro(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.deepForest,
  );

  static TextStyle displayLarge = GoogleFonts.crimsonPro(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.deepForest,
  );

  // Headings
  static TextStyle h1 = GoogleFonts.crimsonPro(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.deepForest,
  );

  static TextStyle h2 = GoogleFonts.crimsonPro(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.deepForest,
  );

  static TextStyle h3 = GoogleFonts.crimsonPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.sageGreen,
  );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static TextStyle labelMedium = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // Monospace - for currency and codes
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
```

## Border Radius

```dart
class AppRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);
}
```

## Spacing

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

## Shadows

```dart
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: const Color(0xFF3D5A3C).withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: const Color(0xFF3D5A3C).withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: const Color(0xFF3D5A3C).withOpacity(0.16),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}
```

## Theme Configuration

```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimary,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.sageGreen,
        secondary: AppColors.terracotta,
        tertiary: AppColors.amberHoney,
        surface: AppColors.bgCard,
        background: AppColors.bgPrimary,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.deepForest),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
        ),
        shadowColor: const Color(0xFF3D5A3C).withOpacity(0.12),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF3D5A3C).withOpacity(0.12),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumRadius,
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageGreen,
          side: const BorderSide(color: AppColors.sageGreen, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumRadius,
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.bgSecondary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.bgSecondary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        labelStyle: AppTextStyles.labelLarge,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sageGreen.withOpacity(0.15),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.sageGreen,
        ),
        side: const BorderSide(color: AppColors.sageGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
```

## Component Examples

### Budget Card Widget

```dart
class BudgetCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final double? progressValue;

  const BudgetCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.progressValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.largeRadius,
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            NumberFormat.currency(symbol: '€').format(amount),
            style: AppTextStyles.display.copyWith(
              color: amount >= 0 ? AppColors.sageGreen : AppColors.terracotta,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildProgressBar(progressValue!),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilizzato', style: AppTextStyles.bodySmall),
            Text(
              '${(value * 100).toInt()}%',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.sageGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.bgSecondary,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.sageGreen,
            ),
          ),
        ),
      ],
    );
  }
}
```

### Transaction List Item Widget

```dart
class TransactionListItem extends StatelessWidget {
  final String name;
  final String category;
  final double amount;
  final String emoji;
  final bool isIncome;

  const TransactionListItem({
    Key? key,
    required this.name,
    required this.category,
    required this.amount,
    required this.emoji,
    this.isIncome = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.mediumRadius,
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.sageGreen : AppColors.terracotta)
                  .withOpacity(0.15),
              borderRadius: AppRadius.smallRadius,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '€').format(amount.abs())}',
            style: AppTextStyles.h3.copyWith(
              color: isIncome ? AppColors.sageGreen : AppColors.terracotta,
            ),
          ),
        ],
      ),
    );
  }
}
```

### AI Assistant Card Widget

```dart
class AIAssistantCard extends StatelessWidget {
  final String message;

  const AIAssistantCard({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sageGreen, AppColors.deepForest],
        ),
        borderRadius: AppRadius.largeRadius,
        boxShadow: AppShadows.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Consiglio di Finn',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Dependencies to Add

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.1.0
  intl: ^0.19.0  # For currency formatting
```

## Migration Steps

1. **Create theme files** in `lib/core/theme/`:
   - `app_colors.dart`
   - `app_text_styles.dart`
   - `app_theme.dart`
   - `app_constants.dart` (for spacing, radius, shadows)

2. **Update MaterialApp**:
   ```dart
   MaterialApp(
     theme: AppTheme.lightTheme,
     // ...
   )
   ```

3. **Replace colors progressively**:
   - Start with backgrounds and cards
   - Then buttons and inputs
   - Finally text colors

4. **Update typography**:
   - Replace all Text widgets to use AppTextStyles
   - Update currency displays to use display/mono styles

5. **Add shadows to cards and containers**

6. **Update border radius** to use AppRadius constants

## Design Principles

✅ **Organic over mechanical** - Soft shadows, warm colors, rounded corners
✅ **Breathing space** - Generous padding and margins
✅ **Hierarchy through size** - Large display numbers, clear labels
✅ **Consistent semantics** - Green = positive/income, Terracotta = expense
✅ **Subtle animations** - Fade-ins, smooth transitions

---

**Note**: Questo design system sostituisce completamente i colori attuali. Il risultato finale sarà professionale, distintivo e ottimista - perfetto per un'app di gestione budget familiare.
