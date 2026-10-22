import 'package:flutter/material.dart';

import 'chabane_logo.dart';

/// Crédit discret « Conçu par Chabane DEV » pour les zones secondaires.
class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: 'Conçu par Chabane DEV',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Conçu par', style: muted),
          const SizedBox(width: 6),
          Text(
            'Chabane DEV',
            style: muted?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          const ChabaneLogo(width: 22),
        ],
      ),
    );
  }
}
