import '../../domain/models/library_item.dart';
import '../../domain/models/picked_document.dart';
import '../../domain/services/library_repository.dart';

/// Données d'EXEMPLE en mémoire pour le squelette. Aucun de ces fichiers
/// n'existe sur l'appareil ; l'interface les signale comme exemples.
class SampleLibraryRepository extends LibraryRepository {
  final List<LibraryItem> _items = [
    const LibraryItem(
      id: 'exemple-art-of-learning',
      title: 'The Art of Learning.pdf',
      type: LibraryItemType.pdf,
      pageCount: 126,
      currentPage: 48,
      sizeBytes: 12 * _mb,
      isFavorite: true,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-english-stories',
      title: 'English Stories.pdf',
      type: LibraryItemType.pdf,
      pageCount: 84,
      currentPage: 1,
      sizeBytes: 8 * _mb,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-cours-anglais',
      title: "Cours d'anglais.pdf",
      type: LibraryItemType.pdf,
      pageCount: 56,
      currentPage: 12,
      sizeBytes: 5 * _mb,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-mes-notes',
      title: 'Mes notes.pdf',
      type: LibraryItemType.pdf,
      pageCount: 23,
      sizeBytes: 2 * _mb,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-reunion',
      title: 'Réunion équipe.m4a',
      type: LibraryItemType.audio,
      duration: Duration(minutes: 32),
      sizeBytes: 28 * _mb,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-interview',
      title: 'Interview.mp3',
      type: LibraryItemType.audio,
      duration: Duration(minutes: 18),
      sizeBytes: 16 * _mb,
      isSample: true,
    ),
    const LibraryItem(
      id: 'exemple-note-trimestre',
      title: 'Note du trimestre.txt',
      type: LibraryItemType.transcription,
      duration: Duration(minutes: 3, seconds: 12),
      sizeBytes: 4 * 1024,
      isSample: true,
    ),
  ];

  static const _mb = 1024 * 1024;

  @override
  List<LibraryItem> get items => List.unmodifiable(_items);

  @override
  bool get containsSampleData => _items.any((item) => item.isSample);

  @override
  LibraryItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  LibraryItem? get lastRead {
    for (final item in _items) {
      if (item.type == LibraryItemType.pdf && item.currentPage != null) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      isFavorite: !_items[index].isFavorite,
    );
    notifyListeners();
  }

  @override
  Future<LibraryItem> importPdf(PickedDocument document) async =>
      throw const ImportException(
        'La bibliothèque d’exemple ne peut pas importer de fichiers.',
      );

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  @override
  Future<void> markOpened(String id) async {}
}
