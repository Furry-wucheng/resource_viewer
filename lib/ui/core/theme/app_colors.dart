import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- 中性色 ---
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceVariant = Color(0xFF757575);
  static const Color outline = Color(0xFFE0E0E0);

  // --- 主色 ---
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryContainer = Color(0xFFD1E4FF);

  // --- 功能色 ---
  static const Color error = Color(0xFFD32F2F);
  static const Color star = Color(0xFFFFC107);
  static const Color viewerBackground = Color(0xFF000000);

  // --- 深色主题 ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnSurfaceVariant = Color(0xFF9E9E9E);
  static const Color darkOutline = Color(0xFF424242);

  // --- 标签预设 12 色 ---
  static const Color tagRed = Color(0xFFE53935);
  static const Color tagPink = Color(0xFFD81B60);
  static const Color tagPurple = Color(0xFF8E24AA);
  static const Color tagDeepBlue = Color(0xFF1E88E5);
  static const Color tagBlue = Color(0xFF039BE5);
  static const Color tagCyan = Color(0xFF00ACC1);
  static const Color tagGreen = Color(0xFF43A047);
  static const Color tagLime = Color(0xFF7CB342);
  static const Color tagOrange = Color(0xFFFB8C00);
  static const Color tagBrown = Color(0xFF6D4C41);
  static const Color tagBlueGrey = Color(0xFF546E7A);
  static const Color tagGrey = Color(0xFF757575);

  static const List<Color> tagPresets = [
    tagRed,
    tagPink,
    tagPurple,
    tagDeepBlue,
    tagBlue,
    tagCyan,
    tagGreen,
    tagLime,
    tagOrange,
    tagBrown,
    tagBlueGrey,
    tagGrey,
  ];
}
