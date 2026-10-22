import 'package:flutter/material.dart';

import '../../domain/models/library_item.dart';

class LibraryItemIcon extends StatelessWidget {
  const LibraryItemIcon({super.key, required this.type, this.size = 48});

  final LibraryItemType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, background) = switch (type) {
      LibraryItemType.pdf => (
        Icons.picture_as_pdf_outlined,
        scheme.tertiaryContainer,
      ),
      LibraryItemType.audio => (
        Icons.music_note_outlined,
        scheme.primaryContainer,
      ),
      LibraryItemType.transcription => (
        Icons.notes_outlined,
        scheme.secondaryContainer,
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }
}

String describeLibraryItem(LibraryItem item) {
  final size = _formatSize(item.sizeBytes);
  return switch (item.type) {
    LibraryItemType.pdf => '${item.pageCount} pages • $size',
    LibraryItemType.audio || LibraryItemType.transcription =>
      '${formatDuration(item.duration ?? Duration.zero)} • $size',
  };
}

String formatDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}

String _formatSize(int bytes) {
  const mb = 1024 * 1024;
  if (bytes >= mb) return '${(bytes / mb).round()} Mo';
  return '${(bytes / 1024).ceil()} Ko';
}
