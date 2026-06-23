import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.onSurface,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackground: AppColors.background,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.darkOnSurface,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackground: AppColors.darkBackground,
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surfaceVariant,
    required Color onSurfaceVariant,
    required Color outline,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),

      // NavigationBar (BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primaryContainer,
        height: AppSpacing.bottomBarHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.labelSmall.copyWith(color: onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: onSurfaceVariant, size: 24);
        }),
      ),

      // NavigationRail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primaryContainer,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(color: onSurfaceVariant, size: 24),
        selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
          color: onSurfaceVariant,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 0),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: onSurfaceVariant,
        ),
      ),

      // Text
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: onSurfaceVariant),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: onSurfaceVariant),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
