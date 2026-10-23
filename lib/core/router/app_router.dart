import 'package:go_router/go_router.dart';

import '../../presentation/about/about_screen.dart';
import '../../presentation/about/privacy_policy_screen.dart';
import '../../presentation/discover/discover_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/library/library_screen.dart';
import '../../presentation/reader/reader_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/transcription/transcript_screen.dart';
import '../../presentation/transcription/transcription_screen.dart';

abstract final class AppRoutes {
  static const home = '/accueil';
  static const library = '/bibliotheque';
  static const transcription = '/transcrire';
  static const discover = '/decouvrir';
  static const settings = '/parametres';
  static const about = '/parametres/a-propos';
  static const privacy = '/parametres/confidentialite';

  static String reader(String id) => '/lecteur/$id';
  static String transcript(String id) => '/texte/$id';
}

GoRouter createRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.transcription,
              builder: (context, state) => const TranscriptionScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discover,
              builder: (context, state) => const DiscoverScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/lecteur/:id',
      builder: (context, state) =>
          ReaderScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/texte/:id',
      builder: (context, state) =>
          TranscriptScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'a-propos',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: 'confidentialite',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
      ],
    ),
  ],
);
