import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle _baseFontStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color,
    double? letterSpacing,
    double? height,
  ) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0,
      height: height,
    );
  }

  static TextStyle displayLarge(Color color) =>
      _baseFontStyle(57, FontWeight.bold, color, 0, 1.12);

  static TextStyle displayMedium(Color color) =>
      _baseFontStyle(45, FontWeight.bold, color, 0, 1.16);

  static TextStyle displaySmall(Color color) =>
      _baseFontStyle(36, FontWeight.bold, color, 0, 1.22);

  static TextStyle headlineLarge(Color color) =>
      _baseFontStyle(32, FontWeight.w700, color, 0, 1.25);

  static TextStyle headlineMedium(Color color) =>
      _baseFontStyle(28, FontWeight.w700, color, 0, 1.29);

  static TextStyle headlineSmall(Color color) =>
      _baseFontStyle(24, FontWeight.w700, color, 0, 1.33);

  static TextStyle titleLarge(Color color) =>
      _baseFontStyle(22, FontWeight.w700, color, 0, 1.27);

  static TextStyle titleMedium(Color color) =>
      _baseFontStyle(16, FontWeight.w600, color, 0.15, 1.5);

  static TextStyle titleSmall(Color color) =>
      _baseFontStyle(14, FontWeight.w600, color, 0.1, 1.43);

  static TextStyle bodyLarge(Color color) =>
      _baseFontStyle(16, FontWeight.w400, color, 0.5, 1.5);

  static TextStyle bodyMedium(Color color) =>
      _baseFontStyle(14, FontWeight.w400, color, 0.25, 1.43);

  static TextStyle bodySmall(Color color) =>
      _baseFontStyle(12, FontWeight.w400, color, 0.4, 1.33);

  static TextStyle labelLarge(Color color) =>
      _baseFontStyle(14, FontWeight.w600, color, 0.1, 1.43);

  static TextStyle labelMedium(Color color) =>
      _baseFontStyle(12, FontWeight.w600, color, 0.5, 1.33);

  static TextStyle labelSmall(Color color) =>
      _baseFontStyle(11, FontWeight.w600, color, 0.5, 1.45);

  static TextStyle sectionHeader(Color color) =>
      _baseFontStyle(18, FontWeight.w700, color, 0, 1.27);

  static TextStyle description(Color color) =>
      _baseFontStyle(13, FontWeight.w400, color, 0, 1.38);

  static TextStyle buttonSmall(Color color) =>
      _baseFontStyle(12, FontWeight.w600, color, 0.5, 1.33);

  static TextStyle breadcrumb(Color color) =>
      _baseFontStyle(12, FontWeight.w500, color, 0, 1.33);

  static TextStyle codeBlock(Color color) => TextStyle(
    fontFamily: 'Courier New',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle errorText(Color color) =>
      _baseFontStyle(12, FontWeight.w500, color, 0, 1.33);

  static TextStyle hintText(Color color) =>
      _baseFontStyle(14, FontWeight.w400, color, 0.25, 1.43);

  static TextStyle readerBodyLight(double fontSize) => GoogleFonts.lora(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.readerTextLight,
    height: 1.6,
  );

  static TextStyle readerBodyDark(double fontSize) => GoogleFonts.lora(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.readerTextDark,
    height: 1.6,
  );

  static TextStyle readerChapterTitle(Color color) => GoogleFonts.lora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.2,
  );

  static TextStyle readerBookTitle(Color color) => GoogleFonts.lora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );
}

extension TextStylesExtension on BuildContext {
  Color get textColor =>
      Theme.of(this).brightness == Brightness.light
          ? AppColors.lightText
          : AppColors.darkText;

  Color get textSecondaryColor =>
      Theme.of(this).brightness == Brightness.light
          ? AppColors.lightTextSecondary
          : AppColors.darkTextSecondary;

  TextStyle get displayLarge => AppTextStyles.displayLarge(textColor);
  TextStyle get displayMedium => AppTextStyles.displayMedium(textColor);
  TextStyle get displaySmall => AppTextStyles.displaySmall(textColor);

  TextStyle get headlineLarge => AppTextStyles.headlineLarge(textColor);
  TextStyle get headlineMedium => AppTextStyles.headlineMedium(textColor);
  TextStyle get headlineSmall => AppTextStyles.headlineSmall(textColor);

  TextStyle get titleLarge => AppTextStyles.titleLarge(textColor);
  TextStyle get titleMedium => AppTextStyles.titleMedium(textColor);
  TextStyle get titleSmall => AppTextStyles.titleSmall(textColor);

  TextStyle get bodyLarge => AppTextStyles.bodyLarge(textColor);
  TextStyle get bodyMedium => AppTextStyles.bodyMedium(textColor);
  TextStyle get bodySmall => AppTextStyles.bodySmall(textColor);

  TextStyle get labelLarge => AppTextStyles.labelLarge(textColor);
  TextStyle get labelMedium => AppTextStyles.labelMedium(textColor);
  TextStyle get labelSmall => AppTextStyles.labelSmall(textColor);

  TextStyle get sectionHeader => AppTextStyles.sectionHeader(textColor);
  TextStyle get description => AppTextStyles.description(textSecondaryColor);
}
