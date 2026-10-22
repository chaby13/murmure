import 'package:flutter/foundation.dart';

import '../models/library_item.dart';

/// Accès à la bibliothèque locale. L'implémentation SQLite arrivera avec
/// le ticket STORE-01 ; le squelette utilise un dépôt d'exemple en mémoire.
abstract class LibraryRepository extends ChangeNotifier {
  List<LibraryItem> get items;

  /// Vrai tant que le contenu provient de données d'exemple.
  bool get containsSampleData;

  LibraryItem? byId(String id);

  void toggleFavorite(String id);

  /// Le dernier PDF en cours de lecture, pour « Reprendre ma lecture ».
  LibraryItem? get lastRead;
}
