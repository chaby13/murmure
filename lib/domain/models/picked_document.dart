/// Un fichier choisi par l'utilisateur, avant son import.
class PickedDocument {
  const PickedDocument({required this.name, required this.path});

  /// Nom d'origine, par exemple « Cours d'anglais.pdf ».
  final String name;

  /// Chemin lisible par l'application (souvent une copie temporaire du
  /// sélecteur système).
  final String path;
}
