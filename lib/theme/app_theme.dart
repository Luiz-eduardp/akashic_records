import 'package:flutter/material.dart';
import 'google_fonts_safe.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme({required Color accentColor}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: accentColor,

      scaffoldBackgroundColor: AppColors.lightBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge(AppColors.lightText),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        actionsIconTheme: const IconThemeData(color: AppColors.lightText),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge(Colors.white),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge(accentColor),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.labelLarge(accentColor),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium(AppColors.lightTextSecondary),
        hintStyle: AppTextStyles.bodyMedium(AppColors.lightTextSecondary),
        errorStyle: AppTextStyles.bodySmall(AppColors.error),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        disabledColor: AppColors.disabled,
        selectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium(AppColors.lightText),
        secondaryLabelStyle: AppTextStyles.labelMedium(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.lightSurface,
        elevation: 4,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 16,
      ),

      textTheme: outfitTextThemeSafe().copyWith(
        displayLarge: AppTextStyles.displayLarge(AppColors.lightText),
        displayMedium: AppTextStyles.displayMedium(AppColors.lightText),
        displaySmall: AppTextStyles.displaySmall(AppColors.lightText),
        headlineLarge: AppTextStyles.headlineLarge(AppColors.lightText),
        headlineMedium: AppTextStyles.headlineMedium(AppColors.lightText),
        headlineSmall: AppTextStyles.headlineSmall(AppColors.lightText),
        titleLarge: AppTextStyles.titleLarge(AppColors.lightText),
        titleMedium: AppTextStyles.titleMedium(AppColors.lightText),
        titleSmall: AppTextStyles.titleSmall(AppColors.lightText),
        bodyLarge: AppTextStyles.bodyLarge(AppColors.lightText),
        bodyMedium: AppTextStyles.bodyMedium(AppColors.lightText),
        bodySmall: AppTextStyles.bodySmall(AppColors.lightTextSecondary),
        labelLarge: AppTextStyles.labelLarge(accentColor),
        labelMedium: AppTextStyles.labelMedium(accentColor),
        labelSmall: AppTextStyles.labelSmall(accentColor),
      ),

      iconTheme: const IconThemeData(color: AppColors.lightText, size: 24),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: Colors.grey.shade300,
      ),
    );
  }

  static ThemeData darkTheme({required Color accentColor}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accentColor,

      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge(AppColors.darkText),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        actionsIconTheme: const IconThemeData(color: AppColors.darkText),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge(Colors.white),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge(accentColor),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.labelLarge(accentColor),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium(AppColors.darkTextSecondary),
        hintStyle: AppTextStyles.bodyMedium(AppColors.darkTextSecondary),
        errorStyle: AppTextStyles.bodySmall(AppColors.error),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        disabledColor: AppColors.disabled.withOpacity(0.5),
        selectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTextStyles.labelMedium(AppColors.darkText),
        secondaryLabelStyle: AppTextStyles.labelMedium(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 16,
      ),

      textTheme: outfitTextThemeSafe(ThemeData.dark().textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge(AppColors.darkText),
        displayMedium: AppTextStyles.displayMedium(AppColors.darkText),
        displaySmall: AppTextStyles.displaySmall(AppColors.darkText),
        headlineLarge: AppTextStyles.headlineLarge(AppColors.darkText),
        headlineMedium: AppTextStyles.headlineMedium(AppColors.darkText),
        headlineSmall: AppTextStyles.headlineSmall(AppColors.darkText),
        titleLarge: AppTextStyles.titleLarge(AppColors.darkText),
        titleMedium: AppTextStyles.titleMedium(AppColors.darkText),
        titleSmall: AppTextStyles.titleSmall(AppColors.darkText),
        bodyLarge: AppTextStyles.bodyLarge(AppColors.darkText),
        bodyMedium: AppTextStyles.bodyMedium(AppColors.darkText),
        bodySmall: AppTextStyles.bodySmall(AppColors.darkTextSecondary),
        labelLarge: AppTextStyles.labelLarge(accentColor),
        labelMedium: AppTextStyles.labelMedium(accentColor),
        labelSmall: AppTextStyles.labelSmall(accentColor),
      ),

      iconTheme: const IconThemeData(color: AppColors.darkText, size: 24),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: AppColors.darkSurfaceVariant,
      ),
    );
  }
}
