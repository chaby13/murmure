import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../domain/models/app_language.dart';
import '../../domain/models/library_item.dart';
import '../../domain/services/audio_recorder.dart';
import '../../domain/services/library_repository.dart';
import '../../services/transcription/transcription_jobs.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_item_icon.dart';
import '../widgets/not_integrated.dart';
import 'transcribe_audio.dart';

enum _TranscriptionTab { record, file, results }

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  _TranscriptionTab _tab = _TranscriptionTab.record;
  AppLanguage? _language = AppLanguage.fr;
  bool _recording = false;
  final _elapsed = Stopwatch();
  Timer? _ticker;
  late AudioRecorderService _recorder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recorder = AppScope.of(context).recorder;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_recording) _recorder.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Transcription')),
      body: ListenableBuilder(
        listenable: Listenable.merge([deps.transcriptions, deps.library]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            SegmentedButton<_TranscriptionTab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _TranscriptionTab.record,
                  label: Text('Enregistrer'),
                ),
                ButtonSegment(
                  value: _TranscriptionTab.file,
                  label: Text('Fichier audio'),
                ),
                ButtonSegment(
                  value: _TranscriptionTab.results,
                  label: Text('Résultats'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
            const SizedBox(height: 16),
            if (deps.transcriptions.current case final job?) _JobCard(job: job),
            ...switch (_tab) {
              _TranscriptionTab.record => _recordTab(context),
              _TranscriptionTab.file => _fileTab(context),
              _TranscriptionTab.results => _resultsTab(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _recordTab(BuildContext context) {
    final theme = Theme.of(context);
    final deps = AppScope.of(context);
    final ready =
        deps.recorder.isAvailable &&
        deps.engines.asr.isAvailable &&
        !deps.library.containsSampleData;
    final String hint;
    if (!deps.engines.asr.isAvailable) {
      hint =
          'Transcription non disponible dans cette version : aucun son '
          'n’est enregistré.';
    } else if (!deps.recorder.isAvailable || deps.library.containsSampleData) {
      hint = 'Enregistrement non disponible sur cet appareil.';
    } else if (_recording) {
      hint = 'Enregistrement en cours. Touchez pour arrêter et transcrire.';
    } else {
      hint =
          'Touchez le micro pour enregistrer. Le son et le texte restent '
          'sur cet appareil.';
    }

    return [
      const SizedBox(height: 8),
      Center(
        child: Semantics(
          button: true,
          label: _recording
              ? 'Arrêter l’enregistrement'
              : 'Démarrer l’enregistrement',
          excludeSemantics: true,
          child: InkWell(
            key: const Key('record-button'),
            customBorder: const CircleBorder(),
            onTap: ready
                ? (_recording ? _stopRecording : _startRecording)
                : () => showNotIntegrated(
                    context,
                    'Enregistrement et transcription',
                    deps.engines.asr.ticket,
                  ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: _recording
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: _recording
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                child: Icon(
                  _recording ? Icons.stop : Icons.mic,
                  size: 40,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _clock(_elapsed.elapsed),
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      Text(
        hint,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_recording)
        Center(
          child: TextButton(
            onPressed: _cancelRecording,
            child: const Text('Annuler sans garder'),
          ),
        ),
      const SizedBox(height: 24),
      Text('Langue parlée', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      LanguageChoice(
        value: _language,
        onChanged: (value) => setState(() => _language = value),
      ),
    ];
  }

  List<Widget> _fileTab(BuildContext context) {
    final deps = AppScope.of(context);
    final theme = Theme.of(context);
    final available =
        deps.engines.asr.isAvailable && !deps.library.containsSampleData;
    return [
      EmptyState(
        icon: Icons.audio_file_outlined,
        title: 'Transcrire un fichier audio',
        message: available
            ? 'Choisissez un enregistrement (WAV, MP3, M4A…). Il est copié '
                  'dans Murmure puis transcrit sur cet appareil.'
            : 'La transcription n’est pas disponible dans cette version.',
        action: FilledButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Choisir un fichier'),
          onPressed: available
              ? _pickAudio
              : () => showNotIntegrated(
                  context,
                  'Import audio',
                  deps.engines.asr.ticket,
                ),
        ),
      ),
      Text('Langue parlée', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      LanguageChoice(
        value: _language,
        onChanged: (value) => setState(() => _language = value),
      ),
    ];
  }

  List<Widget> _resultsTab(BuildContext context) {
    final library = AppScope.of(context).library;
    final results = [
      for (final item in library.items)
        if (item.type == LibraryItemType.transcription && !item.isSample) item,
    ];
    if (results.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.notes_outlined,
          title: 'Aucune transcription',
          message:
              'Vos transcriptions apparaîtront ici, modifiables '
              'et exportables en TXT.',
        ),
      ];
    }
    return [
      for (final item in results)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: LibraryItemIcon(type: item.type),
          title: Text(item.title),
          subtitle: Text(
            item.addedAt == null
                ? describeLibraryItem(item)
                : '${formatDate(item.addedAt!)} • ${describeLibraryItem(item)}',
          ),
          onTap: () => context.push(AppRoutes.transcript(item.id)),
        ),
    ];
  }

  Future<void> _startRecording() async {
    final deps = AppScope.of(context);
    if (deps.transcriptions.isBusy) {
      _show('Attendez la fin de la transcription en cours.');
      return;
    }
    try {
      await deps.recorder.start();
    } on RecorderException catch (e) {
      _show(e.message);
      return;
    }
    _elapsed
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
    setState(() => _recording = true);
  }

  Future<void> _stopRecording() async {
    final deps = AppScope.of(context);
    _ticker?.cancel();
    _elapsed.stop();
    setState(() => _recording = false);
    final path = await deps.recorder.stop();
    if (!mounted) return;
    if (path == null) {
      _show('Rien n’a été enregistré.');
      return;
    }
    final LibraryItem audio;
    try {
      audio = await deps.library.addAudio(
        path,
        title: 'Enregistrement du ${_stamp(DateTime.now())}.wav',
        duration: _elapsed.elapsed,
        move: true,
      );
    } on ImportException catch (e) {
      _show(e.message);
      return;
    }
    if (!mounted) return;
    await transcribeAndOpen(context, audio, language: _language);
  }

  Future<void> _cancelRecording() async {
    _ticker?.cancel();
    _elapsed
      ..stop()
      ..reset();
    setState(() => _recording = false);
    await AppScope.of(context).recorder.cancel();
  }

  Future<void> _pickAudio() async {
    final deps = AppScope.of(context);
    if (deps.transcriptions.isBusy) {
      _show('Attendez la fin de la transcription en cours.');
      return;
    }
    final picked = await deps.picker.pickAudio();
    if (picked == null || !mounted) return;
    final LibraryItem audio;
    try {
      audio = await deps.library.addAudio(picked.path, title: picked.name);
    } on ImportException catch (e) {
      _show(e.message);
      return;
    }
    if (!mounted) return;
    await transcribeAndOpen(context, audio, language: _language);
  }

  void _show(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  static String _clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
        '${two(d.inSeconds.remainder(60))}';
  }

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}-${two(d.month)} à ${two(d.hour)}h${two(d.minute)}';
  }
}

/// État de la transcription en cours ou du dernier résultat.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final TranscriptionJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = AppScope.of(context).transcriptions;
    final Widget body = switch (job.status) {
      TranscriptionStatus.running => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcription de « ${job.audioTitle} »… ${job.progress} %',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: job.progress == 0 ? null : job.progress / 100,
          ),
          const SizedBox(height: 6),
          Text(
            'Cela peut prendre un moment selon la longueur de l’audio. '
            'Vous pouvez changer d’onglet.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      TranscriptionStatus.done => Row(
        children: [
          const Icon(Icons.check_circle_outline),
          const SizedBox(width: 8),
          Expanded(child: Text('« ${job.audioTitle} » est transcrit.')),
          TextButton(
            onPressed: () => context.push(AppRoutes.transcript(job.resultId!)),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
      TranscriptionStatus.failed => Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(job.error ?? 'La transcription a échoué.')),
          IconButton(
            tooltip: 'Fermer',
            onPressed: jobs.clear,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    };
    return Card(
      key: const Key('transcription-job'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(padding: const EdgeInsets.all(12), child: body),
    );
  }
}
