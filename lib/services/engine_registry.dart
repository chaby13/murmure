import '../domain/services/local_engines.dart';
import 'asr/asr_engine_not_integrated.dart';
import 'ocr/ocr_engine_not_integrated.dart';
import 'pdf/pdf_engine_not_integrated.dart';
import 'pdf/pdfium_pdf_engine.dart';
import 'translation/translation_engine_not_integrated.dart';
import 'tts/combined_tts_engine.dart';
import 'tts/piper_tts_engine.dart';
import 'tts/system_tts_engine.dart';
import 'tts/tts_engine_not_integrated.dart';

/// Regroupe les moteurs locaux utilisés par l'application.
class EngineRegistry {
  const EngineRegistry({
    required this.pdf,
    required this.ocr,
    required this.tts,
    required this.asr,
    required this.translation,
  });

  /// Aucun moteur intégré (démonstration et tests).
  const EngineRegistry.notIntegrated()
    : pdf = const PdfEngineNotIntegrated(),
      ocr = const OcrEngineNotIntegrated(),
      tts = const TtsEngineNotIntegrated(),
      asr = const AsrEngineNotIntegrated(),
      translation = const TranslationEngineNotIntegrated();

  /// État actuel de l'application : moteur PDF, voix naturelles embarquées
  /// [naturalVoices] et voix de l'appareil,
  /// transcription [asr] (whisper.cpp quand son modèle est embarqué).
  EngineRegistry.current({required this.asr, PiperTtsEngine? naturalVoices})
    : pdf = const PdfiumPdfEngine(),
      ocr = const OcrEngineNotIntegrated(),
      tts = naturalVoices == null
          ? SystemTtsEngine()
          : CombinedTtsEngine(
              embedded: naturalVoices,
              system: SystemTtsEngine(),
            ),
      translation = const TranslationEngineNotIntegrated();

  final PdfEngine pdf;
  final OcrEngine ocr;
  final TtsEngine tts;
  final AsrEngine asr;
  final TranslationEngine translation;

  List<LocalEngine> get all => [pdf, ocr, tts, asr, translation];
}
