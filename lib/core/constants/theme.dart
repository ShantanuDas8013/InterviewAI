import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1a237e); // Indigo 900
  static const Color primaryDarkColor = Color(0xFF0d1137); // Darker Indigo
  static const Color accentColor = Color(0xFF7C4DFF); // Deep Purple Accent
  static const Color secondaryAccentColor = Color(0xFF536DFE); // Indigo Accent

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color infoColor = Color(0xFF2196F3); // Blue

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, primaryDarkColor],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [accentColor, secondaryAccentColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Text Colors
  static const Color textPrimaryColor = Colors.white;
  static final Color textSecondaryColor = Colors.white.withValues(alpha: 0.8);
  static final Color textHintColor = Colors.white.withValues(alpha: 0.6);

  // Background Colors
  static final Color cardBackgroundColor = Colors.white.withValues(alpha: 0.05);
  static final Color inputBackgroundColor = Colors.white.withValues(alpha: 0.1);
  static final Color borderColor = Colors.white.withValues(alpha: 0.3);

  // Border Radius
  static const double cardBorderRadius = 24.0;
  static const double inputBorderRadius = 16.0;
  static const double buttonBorderRadius = 16.0;

  // Spacing
  static const double paddingXS = 8.0;
  static const double paddingS = 16.0;
  static const double paddingM = 24.0;
  static const double paddingL = 32.0;
  static const double paddingXL = 40.0;

  // Font Sizes
  static const double fontSizeSmall = 14.0;
  static const double fontSizeRegular = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Colors.purpleAccent.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 5,
    ),
  ];
}
