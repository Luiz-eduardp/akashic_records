import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme outfitTextThemeSafe([TextTheme? base]) {
  return base ?? Typography.material2018().black;
}

TextStyle outfitSafe({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  try {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0,
      height: height,
    );
  } catch (_) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0,
      height: height,
    );
  }
}

TextStyle loraSafe({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
}) {
  try {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  } catch (_) {
    return TextStyle(
      fontFamily: 'serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
