import 'package:flutter/material.dart';

/// BARQ X Color Palette v2 - High-Fidelity Soft Neo-Brutalism
/// Refined color system with 2D comic accents and professional neo-brutalist styling
class AppColors {
  // Background & Atmosphere
  static const Color background = Color(0xFFFFF8DE); // Aged Cream
  static const Color gridOverlay = Color(0xFFD4F1F4); // Light Blue (15% opacity for grid)

  // Master Toggle & Header
  static const Color masterToggleActive = Color(0xFF75C6EB); // Sky Blue

  // Gesture Card Colors (NEW DESIGN)
  static const Color cardShake = Color(0xFFFF7B89); // Coral Red (Torch)
  static const Color cardTwist = Color(0xFFB2E2D4); // Mint Green (Camera)
  static const Color cardFlip = Color(0xFFA0A5FF); // Periwinkle (Smart Silence)
  static const Color cardBackTap = Color(0xFFFFB3BA); // Soft Pink (Strike)
  static const Color cardShield = Color(0xFFFFF2C6); // Pale Yellow (Protection)

  // Status Banner
  static const Color statusBanner = Color(0xFF8CA9FF); // Bright Blue

  // Text & Borders (Neo-Brutalist)
  static const Color textPrimary = Color(0xFF1A1A1A); // Heavy charcoal black
  static const Color textSecondary = Color(0xFF666666); // Medium grey

  // Outlines & Borders (3.5px)
  static const Color borderPrimary = Color(0xFF1A1A1A); // Heavy charcoal borders
  static const Color borderSecondary = Color(0xFF8CA9FF); // Blue accent border (optional)

  // Shadows (Hard, 8px offset, 10% opacity)
  static const Color shadowColor = Color(0xFF1A1A1A); // Hard shadows

  // Disabled & Accessibility
  static const Color disabledColor = Color(0xFFCCCCCC); // Light grey
  static const Color successGreen = Color(0xFF4CAF50); // Success indicator
  static const Color errorRed = Color(0xFFD32F2F); // Error red

  // Legacy (keeping for backward compatibility)
  static const Color accentPrimary = Color(0xFF75C6EB); // Sky Blue (now master toggle)
  static const Color accentSecondary = Color(0xFFB2E2D4); // Mint
  static const Color accentTertiary = Color(0xFFA0A5FF); // Periwinkle
  static const Color accentQuaternary = Color(0xFFFFB3BA); // Soft Pink
  static const Color toggleDisarmed = Color(0xFFE6E6E6); // Grey
  static const Color toggleArmed = Color(0xFF75C6EB); // Sky Blue
}
