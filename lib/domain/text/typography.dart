import '../models/app_language.dart';

const nbsp = ' ';
const _narrowNbsp = ' ';

/// Remet en forme un texte dicté : espaces, majuscules en début de phrase,
/// et, en français, espaces insécables et guillemets « ».
String fixTypography(String text, AppLanguage language) {
  var t = text.replaceAll('\r', '');
  // Espaces multiples, espaces en fin de ligne.
  t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
  t = t.replaceAll(RegExp(r' *\n *'), '\n');
  // Pas d'espace avant . , ) ; espace après si un mot suit.
  // « mot .suite » : la ponctuation a été collée au mauvais mot.
  t = t.replaceAllMapped(
    RegExp(r' +([.,])(?=\p{L})', unicode: true),
    (m) => '${m[1]} ',
  );
  t = t.replaceAllMapped(RegExp(r' +([.,)…])'), (m) => m[1]!);
  t = t.replaceAllMapped(
    RegExp(r'([,;:!?…])(?=[\p{L}«(])', unicode: true),
    (m) => '${m[1]} ',
  );
  t = t.replaceAllMapped(
    RegExp(r'(?<=[»")\]])([.!?…])(?=\p{L})', unicode: true),
    (m) => '${m[1]} ',
  );
  t = t.replaceAllMapped(
    RegExp(r'(?<=[\p{Ll}])\.(?=[\p{Lu}])', unicode: true),
    (m) => '. ',
  );
  t = t.replaceAll('...', '…');
  t = t.replaceAll('’', "'");

  if (language == AppLanguage.fr) {
    // Guillemets droits appariés → « », avec espaces insécables.
    final parts = t.split('"');
    // Seulement si les guillemets vont par paires.
    if (parts.length > 1 && parts.length.isOdd) {
      final quoted = StringBuffer(parts.first);
      for (var i = 1; i < parts.length; i++) {
        quoted
          ..write(i.isOdd ? '«$nbsp' : '$nbsp»')
          ..write(parts[i]);
      }
      t = quoted.toString();
    }
    t = t.replaceAll(RegExp('«[ $nbsp]+'), '«$nbsp');
    t = t.replaceAll(RegExp('[ $nbsp]+»'), '$nbsp»');
    t = t.replaceAll(RegExp('«(?!$nbsp)'), '«$nbsp');
    t = t.replaceAll(RegExp('(?<!$nbsp)»'), '$nbsp»');
    // Espace insécable avant ; ! ? (fine) et : (normale).
    t = t.replaceAllMapped(
      RegExp('[ $nbsp$_narrowNbsp]*([;!?])'),
      (m) => '$_narrowNbsp${m[1]}',
    );
    t = t.replaceAllMapped(
      RegExp('(?<=[^\\d $nbsp$_narrowNbsp])[ $nbsp$_narrowNbsp]*:(?!//)'),
      (m) => '$nbsp:',
    );
    // Pas d'espace en début de ligne avant la ponctuation.
    t = t.replaceAll(RegExp('^[$_narrowNbsp$nbsp]+', multiLine: true), '');
  } else {
    t = t.replaceAllMapped(RegExp(r' +([;:!?])'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r"\bi\b(?=[ ',.!?;:]|$)"), (m) => 'I');
  }

  // Majuscule en début de texte, de ligne et après . ! ? …
  t = t.replaceAllMapped(
    RegExp(
      '(^|[.!?…][ $nbsp$_narrowNbsp»"]*[ \\n]|\\n)([«$nbsp ]*)(\\p{Ll})',
      unicode: true,
    ),
    (m) => '${m[1]}${m[2]}${m[3]!.toUpperCase()}',
  );
  return t.trim();
}
