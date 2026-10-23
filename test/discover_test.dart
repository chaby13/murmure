import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/core/app_scope.dart';
import 'package:murmure/domain/models/free_resource.dart';
import 'package:murmure/domain/services/link_opener.dart';

import 'navigation_test.dart' show tapTab;
import 'test_app.dart';

class _FakeLinks implements LinkOpener {
  _FakeLinks({this.succeed = true});

  final bool succeed;
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return succeed;
  }
}

void main() {
  test('tous les liens sont en https et sans doublon', () {
    final urls = [
      for (final section in freeResourceSections)
        for (final resource in section.resources) resource.url,
    ];
    expect(urls, isNotEmpty);
    expect(urls.toSet().length, urls.length);
    for (final url in urls) {
      expect(Uri.parse(url).scheme, 'https', reason: url);
    }
  });

  testWidgets('Découvrir ouvre un site dans le navigateur', (tester) async {
    final links = _FakeLinks();
    await pumpMurmure(
      tester,
      dependencies: AppDependencies.sample(links: links),
    );
    await tapTab(tester, 'Découvrir');

    expect(find.byKey(const Key('discover-notice')), findsOneWidget);
    expect(find.text('Radios'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('LibriVox'), 200);
    await tester.tap(find.text('LibriVox'));
    await tester.pumpAndSettle();
    expect(links.opened, ['https://librivox.org']);
  });

  testWidgets('un lien qui ne s’ouvre pas est signalé', (tester) async {
    await pumpMurmure(
      tester,
      dependencies: AppDependencies.sample(links: _FakeLinks(succeed: false)),
    );
    await tapTab(tester, 'Découvrir');
    await tester.tap(find.text('Radio France'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Impossible d’ouvrir radiofrance.fr'),
      findsOneWidget,
    );
  });
}
