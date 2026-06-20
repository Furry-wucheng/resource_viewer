import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const TextStyle _base = TextStyle(
    fontFamily: 'Segoe UI',
    fontFamilyFallback: [
      '-apple-system',
      'BlinkMacSystemFont',
      'Roboto',
      'Noto Sans SC',
      'sans-serif',
    ],
  );

  static final TextStyle headlineLarge = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static final TextStyle headlineMedium = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static final TextStyle titleLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static final TextStyle bodyLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static final TextStyle bodyMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static final TextStyle bodySmall = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static final TextStyle labelLarge = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static final TextStyle labelSmall = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}
