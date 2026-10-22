import 'package:flutter/painting.dart';

/// Jetons de couleur Murmure, tirés de la charte (ivoire, vert foncé,
/// vert pâle, beige) et de leurs variantes sombres.
abstract final class MurmureColors {
  // Charte claire
  static const ivory = Color(0xFFF3EFE7);
  static const deepGreen = Color(0xFF344F49);
  static const paleGreen = Color(0xFFD9E3DE);
  static const beige = Color(0xFFE3D8CB);

  static const surfaceLight = Color(0xFFFBF8F2);
  static const inkLight = Color(0xFF22302C);
  static const mutedLight = Color(0xFF56625D);
  static const outlineLight = Color(0xFFD5CEC2);

  // Variante sombre
  static const backgroundDark = Color(0xFF151D1A);
  static const surfaceDark = Color(0xFF1E2925);
  static const surfaceHighDark = Color(0xFF283530);
  static const sageDark = Color(0xFFA3C6BA);
  static const onSageDark = Color(0xFF10211C);
  static const inkDark = Color(0xFFECE7DD);
  static const mutedDark = Color(0xFFB2BCB7);
  static const outlineDark = Color(0xFF3A4843);

  static const error = Color(0xFFA23B32);
  static const errorDark = Color(0xFFF2B8B0);
}

/// Ambiances du lecteur PDF.
enum ReaderMode {
  light('Clair', Color(0xFFFBF8F2), Color(0xFF22302C)),
  dark('Sombre', Color(0xFF1E2A26), Color(0xFFE6E1D6)),
  sepia('Sépia', Color(0xFFF1E4CC), Color(0xFF45372A));

  const ReaderMode(this.label, this.background, this.text);

  final String label;
  final Color background;
  final Color text;
}
