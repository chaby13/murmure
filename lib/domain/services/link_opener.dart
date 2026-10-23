/// Ouvre une adresse web dans le navigateur de l'appareil.
abstract interface class LinkOpener {
  /// Renvoie false si aucun navigateur n'a pu l'ouvrir.
  Future<bool> open(String url);
}
