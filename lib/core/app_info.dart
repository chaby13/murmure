/// Coordonnées de l'éditeur, configurables au build sans rien inventer :
///   flutter run --dart-define=MURMURE_DEV_WEBSITE=https://...
///               --dart-define=MURMURE_DEV_CONTACT=contact@...
/// Laissées vides, elles ne sont pas affichées.
abstract final class AppInfo {
  static const developerName = 'Chabane DEV';
  static const developerWebsite = String.fromEnvironment('MURMURE_DEV_WEBSITE');
  static const developerContact = String.fromEnvironment('MURMURE_DEV_CONTACT');
}
