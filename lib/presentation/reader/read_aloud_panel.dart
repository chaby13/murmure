import 'package:flutter/material.dart';

import '../../core/theme/murmure_colors.dart';
import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';
import 'read_aloud_controller.dart';

const _speeds = [0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5];

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
        // Navigation : page, paragraphe, lecture/pause.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              tooltip: 'Page précédente',
              icon: Icons.skip_previous,
              onPressed: c.page > 1 ? () => c.skipPage(-1) : null,
            ),
            _NavButton(
              tooltip: 'Paragraphe précédent',
              icon: Icons.fast_rewind,
              onPressed: () => c.skipParagraph(-1),
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
            _NavButton(
              tooltip: 'Paragraphe suivant',
              icon: Icons.fast_forward,
              onPressed: () => c.skipParagraph(1),
            ),
            _NavButton(
              tooltip: 'Page suivante',
              icon: Icons.skip_next,
              onPressed: c.page < c.pageCount ? () => c.skipPage(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Réglages : langue, voix, vitesse.
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
            const SizedBox(width: 8),
            Expanded(
              child: PopupMenuButton<String>(
                tooltip: 'Choisir la voix',
                enabled: c.voices.isNotEmpty,
                initialValue: c.voiceName,
                onSelected: c.setVoice,
                itemBuilder: (context) => [
                  for (final v in c.voices)
                    PopupMenuItem(value: v.name, child: Text(_voiceLabel(v))),
                ],
                child: _Chip(
                  c.voiceName == null
                      ? 'Voix'
                      : 'Voix : ${_shortName(c.voiceName!)}',
                  key: const Key('voice-chip'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<double>(
              tooltip: 'Vitesse',
              initialValue: c.speed,
              onSelected: c.setSpeed,
              itemBuilder: (context) => [
                for (final s in _speeds)
                  PopupMenuItem(
                    value: s,
                    child: Text(
                      s == 1 ? '${_speedLabel(s)} (normale)' : _speedLabel(s),
                    ),
                  ),
              ],
              child: _Chip(_speedLabel(c.speed)),
            ),
          ],
        ),
      ],
    );
  }

  /// « Microsoft Hortense - French (France) » → « Hortense ».
  static String _shortName(String name) {
    var short = name.replaceFirst(RegExp(r'^Microsoft\s+'), '');
    final dash = short.indexOf(' - ');
    if (dash > 0) short = short.substring(0, dash);
    return short;
  }

  static String _voiceLabel(TtsVoice v) {
    final gender = switch (v.gender) {
      'female' => ' · voix féminine',
      'male' => ' · voix masculine',
      _ => '',
    };
    return '${_shortName(v.name)} (${v.locale})$gender';
  }

  static String _speedLabel(double s) =>
      '×${s.toStringAsFixed(s == s.roundToDouble() ? 0 : 2).replaceAll('.', ',')}';
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    color: Colors.white,
    disabledColor: Colors.white38,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {super.key});

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
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
