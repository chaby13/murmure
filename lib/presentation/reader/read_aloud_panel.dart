import 'package:flutter/material.dart';

import '../../core/theme/murmure_colors.dart';
import '../../domain/models/app_language.dart';
import 'read_aloud_controller.dart';

const _speeds = [0.75, 1.0, 1.25, 1.5];

/// Panneau audio fixe en bas du lecteur. Sans [controller], il reste
/// désactivé et explique pourquoi.
class ReadAloudPanel extends StatelessWidget {
  const ReadAloudPanel({super.key, this.controller, this.unavailableReason});

  final ReadAloudController? controller;
  final String? unavailableReason;

  @override
  Widget build(BuildContext context) {
    const onPanel = Colors.white;
    final muted = onPanel.withValues(alpha: 0.7);
    final c = controller;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        color: MurmureColors.deepGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: c == null
            ? Row(
                children: [
                  const Icon(Icons.record_voice_over_outlined, color: onPanel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unavailableReason ?? 'Lecture à voix haute indisponible.',
                      style: const TextStyle(color: onPanel),
                    ),
                  ),
                ],
              )
            : ListenableBuilder(
                listenable: c,
                builder: (context, _) => _controls(context, c, muted),
              ),
      ),
    );
  }

  Widget _controls(BuildContext context, ReadAloudController c, Color muted) {
    const onPanel = Colors.white;
    final sentence = c.currentSentence;
    final String status;
    if (c.error != null) {
      status = c.error!;
    } else {
      status = switch (c.status) {
        ReadAloudStatus.loading => 'Préparation de la page ${c.page}…',
        ReadAloudStatus.playing => sentence ?? '',
        ReadAloudStatus.paused => 'En pause, page ${c.page}',
        ReadAloudStatus.finished => 'Lecture terminée',
        ReadAloudStatus.idle => 'Lire à voix haute depuis la page ${c.page}',
      };
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.record_voice_over_outlined, color: onPanel),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status,
                key: const Key('read-aloud-status'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.error != null ? const Color(0xFFFFD7D2) : onPanel,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            PopupMenuButton<AppLanguage?>(
              tooltip: 'Langue de la voix',
              initialValue: c.isLanguageAuto ? null : c.language,
              onSelected: c.setLanguage,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('Automatique')),
                for (final l in AppLanguage.values)
                  PopupMenuItem(value: l, child: Text(l.label)),
              ],
              child: _Chip(
                c.isLanguageAuto
                    ? '${c.language.code.toUpperCase()} auto'
                    : c.language.code.toUpperCase(),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Phrase précédente',
              color: onPanel,
              onPressed: () => c.skip(-1),
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filled(
              tooltip: c.isActive ? 'Pause' : 'Lire',
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: onPanel,
                foregroundColor: MurmureColors.deepGreen,
              ),
              onPressed: c.togglePlay,
              icon: Icon(c.isActive ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: 'Phrase suivante',
              color: onPanel,
              onPressed: () => c.skip(1),
              icon: const Icon(Icons.skip_next),
            ),
            const Spacer(),
            PopupMenuButton<double>(
              tooltip: 'Vitesse',
              initialValue: c.speed,
              onSelected: c.setSpeed,
              itemBuilder: (context) => [
                for (final s in _speeds)
                  PopupMenuItem(value: s, child: Text(_speedLabel(s))),
              ],
              child: _Chip(_speedLabel(c.speed)),
            ),
          ],
        ),
      ],
    );
  }

  static String _speedLabel(double s) =>
      '×${s.toStringAsFixed(s == s.roundToDouble() ? 0 : 2).replaceAll('.', ',')}';
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
