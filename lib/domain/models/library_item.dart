enum LibraryItemType { pdf, audio, transcription }

/// Un élément de la bibliothèque locale.
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.sizeBytes,
    required this.isSample,
    this.pageCount,
    this.currentPage,
    this.duration,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final LibraryItemType type;
  final int sizeBytes;

  /// Vrai pour les données de démonstration du squelette. Elles doivent
  /// toujours être signalées comme telles dans l'interface.
  final bool isSample;

  final int? pageCount;
  final int? currentPage;
  final Duration? duration;
  final bool isFavorite;

  double? get progress {
    final pages = pageCount;
    final page = currentPage;
    if (pages == null || page == null || pages == 0) return null;
    return page / pages;
  }

  LibraryItem copyWith({bool? isFavorite, int? currentPage}) => LibraryItem(
    id: id,
    title: title,
    type: type,
    sizeBytes: sizeBytes,
    isSample: isSample,
    pageCount: pageCount,
    currentPage: currentPage ?? this.currentPage,
    duration: duration,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
