import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale from Figma › Foundations (Inter). Colors are applied at use site.
abstract final class AppText {
  static TextStyle _inter(double size, double lineHeight, FontWeight weight,
          [double letterSpacing = 0]) =>
      GoogleFonts.inter(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static final display = _inter(32, 40, FontWeight.w700);
  static final headline = _inter(24, 32, FontWeight.w600, -0.24);
  static final title = _inter(18, 26, FontWeight.w600);
  static final body = _inter(16, 24, FontWeight.w400);
  static final bodyStrong = _inter(16, 24, FontWeight.w500);
  static final label = _inter(14, 20, FontWeight.w500);
  static final caption = _inter(13, 18, FontWeight.w400);

  /// Recording timer (56/64, Semi Bold). Tabular digits stop it jittering.
  static final timer = _inter(56, 64, FontWeight.w600, -1.12)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
