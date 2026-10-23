/// Langues prises en charge par Murmure (lecture, transcription, traduction).
enum AppLanguage {
  fr('Français', 'fr'),
  en('Anglais', 'en');

  const AppLanguage(this.label, this.code);

  final String label;

  /// Code de langue BCP 47 (« fr », « en »).
  final String code;

  AppLanguage get other => this == fr ? en : fr;
}
