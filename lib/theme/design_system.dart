import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF5D4037);     // Dark Brown
  static const Color primaryLight = Color(0xFF8D6E63); // Light Brown
  static const Color accent = Color(0xFFFFA726);      // Orange (New Wallet)

  // Background colors
  static const Color background = Color(0xFFFDF7F2);  // Warm Cream
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF3E2723); // Darkest Brown
  static const Color textSecondary = Color(0xFF8D6E63); // Brown Grey
  static const Color textLight = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF9CCC65);     // Light Green
  static const Color warning = Color(0xFFFFB74D);     // Orange/Yellow (Material Orange 300)
  static const Color danger = Color(0xFFEF5350);      // Light Red
  static const Color dangerDark = Color(0xFFC62828);  // Dark Red (Material Red 800)

  // Border and divider
  static const Color border = Color(0xFFEFEBE9);      // Light Brown ish
  static const Color divider = Color(0xFFD7CCC8);

  // Progress bar
  static const Color progressBackground = Color(0xFFEFEBE9);
  static const Color progressValue = Color(0xFFFFA726);
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 32;
}

class AppShadows {
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04), // Updated to use withValues
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
