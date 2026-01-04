// Configuration: Default Italian Categories seed data
// Feature: Italian Categories and Budget Management (004)
// Task: T017

/// Default Italian expense categories
/// These match the categories seeded in migration 035_seed_italian_categories.sql
class DefaultItalianCategories {
  static const List<String> categories = [
    'Spesa', // Groceries
    'Benzina', // Fuel
    'Ristoranti', // Restaurants
    'Bollette', // Bills/Utilities
    'Salute', // Health
    'Trasporti', // Transportation
    'Casa', // Home
    'Svago', // Entertainment
    'Abbigliamento', // Clothing
    'Varie', // Miscellaneous (fallback)
  ];

  /// Fallback category name for expenses without specific budget
  static const String fallbackCategory = 'Varie';

  /// Get display name for category (for future localization)
  static String getDisplayName(String categoryName) {
    return categoryName; // Currently just returns the Italian name
  }
}
