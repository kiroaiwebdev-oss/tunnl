import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color darkBg       = Color(0xFF070B14);
  static const Color darkBgMid    = Color(0xFF0A0E1A);
  static const Color darkSurface  = Color(0xFF111827);
  static const Color darkCard     = Color(0xFF1A2235);

  // Primary Accent
  static const Color neonCyan     = Color(0xFF00E5FF);
  static const Color neonCyanDim  = Color(0xFF00B8D4);

  // Secondary
  static const Color orange       = Color(0xFFFF6D00);
  static const Color yellow       = Color(0xFFFFD600);
  static const Color purple       = Color(0xFF7C3AED);
  static const Color purpleEnd    = Color(0xFFEC4899);

  // Status
  static const Color success      = Color(0xFF00E676);
  static const Color error        = Color(0xFFFF1744);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9CB6);
  static const Color textMuted     = Color(0xFF3D5068);

  // Ring colors
  static const Color ringOuter    = Color(0xFF1A2A3A);
  static const Color ringMid      = Color(0xFF1E3448);

  // Gradients
  static const LinearGradient splashBg = LinearGradient(
    colors: [
      Color(0xFF070B14),
      Color(0xFF0A1628),
      Color(0xFF070B14),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}