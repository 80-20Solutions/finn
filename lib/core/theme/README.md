# Flourishing Finances - Design System

Earth-toned, organic design system for Fin family budget app.

## Structure

```
theme/
├── app_colors.dart          # Color palette
├── app_constants.dart       # Spacing, radius, shadows
├── app_text_styles.dart     # Typography
├── app_theme.dart          # Main theme configuration
└── widgets/                # Reusable components
    ├── budget_card.dart
    ├── transaction_list_item.dart
    └── ai_assistant_card.dart
```

## Quick Start

```dart
import 'package:family_expense_tracker/core/theme/app_colors.dart';
import 'package:family_expense_tracker/core/theme/app_text_styles.dart';
import 'package:family_expense_tracker/core/theme/app_constants.dart';

// Use colors
Container(color: AppColors.sageGreen)

// Use text styles
Text('Title', style: AppTextStyles.h1)

// Use spacing
Padding(padding: EdgeInsets.all(AppSpacing.md))

// Use radius
Container(decoration: BoxDecoration(borderRadius: AppRadius.mediumRadius))

// Use shadows
Container(decoration: BoxDecoration(boxShadow: AppShadows.medium))
```

## Design Principles

- **Organic over mechanical** - Soft shadows, warm colors, rounded corners
- **Breathing space** - Generous padding and margins
- **Hierarchy through size** - Large display numbers, clear labels
- **Consistent semantics** - Green = positive/income, Terracotta = expense
- **Subtle animations** - Fade-ins, smooth transitions

## Color Palette

- **Sage Green** `#7A9B76` - Growth, balance, prosperity
- **Deep Forest** `#3D5A3C` - Stability, trust
- **Terracotta** `#D4846A` - Warmth, expenses
- **Amber Honey** `#E8B44F` - Optimism, goals
- **Warm Sand** `#F5EFE7` - Secondary background
- **Cream** `#FFFBF5` - Primary background

## Typography

- **Display/Numbers**: Crimson Pro (serif)
- **Body**: DM Sans (sans-serif)
- **Monospace**: JetBrains Mono

## Components

See `widgets/` directory for reusable components like:
- `BudgetCard` - Card with progress indicator
- `TransactionListItem` - Transaction list item
- `AIAssistantCard` - AI assistant card with gradient

## Migration from Old Theme

1. Replace color references:
   - `AppColors.terracotta` → `AppColors.sageGreen`
   - `AppColors.parchment` → `AppColors.bgPrimary`
   - `AppColors.cream` → `AppColors.bgCard`

2. Replace text styles:
   - `Theme.of(context).textTheme.headlineLarge` → `AppTextStyles.h1`
   - `Theme.of(context).textTheme.bodyMedium` → `AppTextStyles.bodyMedium`

3. Update border radius to use `AppRadius` constants

4. Update shadows to use `AppShadows` constants

See `DESIGN_SYSTEM_FLUTTER.md` in project root for full implementation guide.
