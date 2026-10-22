import 'package:flutter/material.dart';

/// Explique qu'une fonction n'est pas encore disponible, sans rien simuler.
void showNotIntegrated(BuildContext context, String feature, String ticket) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '$feature : pas encore disponible (ticket $ticket). '
          'Aucun traitement n’a été effectué.',
        ),
      ),
    );
}
