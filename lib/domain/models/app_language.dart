/// Langues prises en charge par Murmure (lecture, transcription, traduction).
enum AppLanguage {
  fr('Français'),
  en('Anglais');

  const AppLanguage(this.label);

  final String label;

  AppLanguage get other => this == fr ? en : fr;
}
