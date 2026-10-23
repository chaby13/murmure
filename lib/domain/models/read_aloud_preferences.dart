import 'app_language.dart';

/// Réglages de lecture retenus par l'utilisateur.
class ReadAloudPreferences {
  const ReadAloudPreferences({this.speed = 1, this.voices = const {}});

  final double speed;

  /// Voix choisie par langue (nom de voix de l'appareil).
  final Map<AppLanguage, String> voices;
}
