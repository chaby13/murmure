import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/app_language.dart';
import '../../domain/models/library_item.dart';
import '../../domain/services/library_repository.dart';
import '../../domain/services/local_engines.dart';
import '../../domain/text/text_analysis.dart';
import '../../domain/text/typography.dart';

enum TranscriptionStatus { running, done, failed }

/// Transcription en cours ou terminée, visible depuis n'importe quel écran.
class TranscriptionJob {
  const TranscriptionJob({
    required this.audioTitle,
    required this.status,
    this.progress = 0,
    this.error,
    this.resultId,
  });

  final String audioTitle;
  final TranscriptionStatus status;

  /// De 0 à 100.
  final int progress;
  final String? error;

  /// Identifiant de la transcription enregistrée dans la bibliothèque.
  final String? resultId;
}

/// Lance les transcriptions une par une et range le texte obtenu dans la
/// bibliothèque. Survit aux changements d'onglet.
class TranscriptionJobs extends ChangeNotifier {
  TranscriptionJobs({
    required this.library,
    required this.asr,
    this.vocabulary,
  });

  final LibraryRepository library;
  final AsrEngine asr;

  /// Mots du dictionnaire personnel, à reconnaître en priorité.
  final List<String> Function()? vocabulary;

  TranscriptionJob? _current;
  TranscriptionJob? get current => _current;
  bool get isBusy => _current?.status == TranscriptionStatus.running;

  /// Transcrit [audio] et renvoie la transcription ajoutée à la
  /// bibliothèque, ou null en cas d'échec (le détail est dans [current]).
  Future<LibraryItem?> transcribe(
    LibraryItem audio, {
    AppLanguage? language,
  }) async {
    if (isBusy) return null;
    final file = library.fileOf(audio);
    _set(
      TranscriptionJob(
        audioTitle: audio.title,
        status: TranscriptionStatus.running,
      ),
    );
    try {
      if (file == null) {
        throw const AsrException('Le fichier audio est introuvable.');
      }
      final words = vocabulary?.call() ?? const <String>[];
      final raw = await asr.transcribe(
        file.path,
        language: language,
        vocabulary: words,
        onProgress: (percent) => _set(
          TranscriptionJob(
            audioTitle: audio.title,
            status: TranscriptionStatus.running,
            progress: percent.clamp(0, 100),
          ),
        ),
      );
      // Typographie remise au propre : majuscules, espaces, guillemets.
      var text = raw.trim().isEmpty
          ? ''
          : fixTypography(raw, language ?? TextAnalysis.languageOf(raw));
      // Les mots du dictionnaire personnel gardent leur écriture exacte.
      for (final w in words) {
        text = text.replaceAll(
          RegExp(
            '(?<![\\p{L}])${RegExp.escape(w)}(?![\\p{L}])',
            caseSensitive: false,
            unicode: true,
          ),
          w,
        );
      }
      if (text.isEmpty) {
        throw const AsrException(
          'Aucune parole n’a été reconnue dans cet audio.',
        );
      }
      final item = await library.addTranscription(
        title: '${p.basenameWithoutExtension(audio.title)}.txt',
        text: text,
      );
      _set(
        TranscriptionJob(
          audioTitle: audio.title,
          status: TranscriptionStatus.done,
          progress: 100,
          resultId: item.id,
        ),
      );
      return item;
    } catch (e) {
      _set(
        TranscriptionJob(
          audioTitle: audio.title,
          status: TranscriptionStatus.failed,
          error: e is AsrException || e is ImportException
              ? e.toString()
              : 'La transcription a échoué.',
        ),
      );
      return null;
    }
  }

  /// Efface le dernier résultat affiché.
  void clear() {
    if (isBusy) return;
    _set(null);
  }

  void _set(TranscriptionJob? job) {
    _current = job;
    notifyListeners();
  }
}
