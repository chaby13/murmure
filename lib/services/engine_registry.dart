import '../domain/services/local_engines.dart';
import 'asr/asr_engine_not_integrated.dart';
import 'ocr/ocr_engine_not_integrated.dart';
import 'pdf/pdf_engine_not_integrated.dart';
import 'pdf/pdfium_pdf_engine.dart';
import 'translation/translation_engine_not_integrated.dart';
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

  /// État actuel de l'application : seul le moteur PDF est intégré.
  const EngineRegistry.current()
    : pdf = const PdfiumPdfEngine(),
      ocr = const OcrEngineNotIntegrated(),
      tts = const TtsEngineNotIntegrated(),
      asr = const AsrEngineNotIntegrated(),
      translation = const TranslationEngineNotIntegrated();

  final PdfEngine pdf;
  final OcrEngine ocr;
  final TtsEngine tts;
  final AsrEngine asr;
  final TranslationEngine translation;

  List<LocalEngine> get all => [pdf, ocr, tts, asr, translation];
}
