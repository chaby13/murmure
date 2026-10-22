enum LibraryItemType { pdf, audio, transcription }

/// Un élément de la bibliothèque locale.
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.sizeBytes,
    required this.isSample,
    this.fileName,
    this.pageCount,
    this.currentPage,
    this.duration,
    this.isFavorite = false,
    this.addedAt,
    this.lastOpenedAt,
  });

  final String id;
  final String title;
  final LibraryItemType type;
  final int sizeBytes;

  /// Vrai pour les données de démonstration. Elles doivent toujours être
  /// signalées comme telles dans l'interface.
  final bool isSample;

  /// Nom du fichier dans le stockage privé de l'application.
  final String? fileName;

  /// Inconnu tant que le moteur PDF n'a pas analysé le document.
  final int? pageCount;
  final int? currentPage;
  final Duration? duration;
  final bool isFavorite;
  final DateTime? addedAt;
  final DateTime? lastOpenedAt;

  double? get progress {
    final pages = pageCount;
    final page = currentPage;
    if (pages == null || page == null || pages == 0) return null;
    return page / pages;
  }

  LibraryItem copyWith({
    bool? isFavorite,
    int? currentPage,
    DateTime? lastOpenedAt,
  }) => LibraryItem(
    id: id,
    title: title,
    type: type,
    sizeBytes: sizeBytes,
    isSample: isSample,
    fileName: fileName,
    pageCount: pageCount,
    currentPage: currentPage ?? this.currentPage,
    duration: duration,
    isFavorite: isFavorite ?? this.isFavorite,
    addedAt: addedAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
  );
}
