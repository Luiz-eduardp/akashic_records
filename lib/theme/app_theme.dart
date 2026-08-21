import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static const double kStandardRadius = 16.0;
  static const double kCardRadius = 16.0;
  static const double kPillRadius = 24.0;

  static ThemeData lightTheme({required Color accentColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.primaryContainer.withOpacity(0.8),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMedium(colorScheme.primary).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return AppTextStyles.labelMedium(colorScheme.onSurfaceVariant);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kStandardRadius)),
          textStyle: AppTextStyles.labelLarge(colorScheme.onPrimary).copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kStandardRadius)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kStandardRadius)),
          textStyle: AppTextStyles.labelLarge(colorScheme.primary),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2), width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kPillRadius)),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  static ThemeData darkTheme({required Color accentColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMedium(colorScheme.primary).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return AppTextStyles.labelMedium(colorScheme.onSurfaceVariant);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kStandardRadius)),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.15), width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kPillRadius)),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  static ThemeData oledTheme({required Color accentColor}) {
    final dark = darkTheme(accentColor: accentColor);
    return dark.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: dark.appBarTheme.copyWith(backgroundColor: Colors.black),
      cardTheme: dark.cardTheme.copyWith(color: const Color(0xFF0D0D0D)),
    );
  }
}
