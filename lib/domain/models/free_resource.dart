/// Un site gratuit conseillé dans l'onglet Découvrir. Il s'ouvre dans le
/// navigateur : Murmure lui-même ne se connecte jamais.
class FreeResource {
  const FreeResource(this.name, this.description, this.url);

  final String name;
  final String description;
  final String url;

  /// Adresse courte affichée sous le nom (sans « https:// » ni « www. »).
  String get host => Uri.parse(url).host.replaceFirst('www.', '');
}

class ResourceSection {
  const ResourceSection(this.title, this.hint, this.resources);

  final String title;
  final String hint;
  final List<FreeResource> resources;
}

const freeResourceSections = [
  ResourceSection('Radios', 'Écouter en direct ou en podcast.', [
    FreeResource(
      'Radio France',
      'France Inter, France Culture, FIP, France Musique et leurs podcasts.',
      'https://www.radiofrance.fr',
    ),
    FreeResource(
      'RFI',
      'Radio France Internationale : l’actualité du monde en français.',
      'https://www.rfi.fr',
    ),
    FreeResource(
      'Radio Garden',
      'Des milliers de radios du monde entier, à choisir sur un globe.',
      'https://radio.garden',
    ),
    FreeResource(
      'BBC Sounds',
      'Radios et podcasts de la BBC, en anglais.',
      'https://www.bbc.co.uk/sounds',
    ),
  ]),
  ResourceSection(
    'Livres à lire gratuitement',
    'Téléchargez un PDF puis ouvrez-le dans Murmure pour l’écouter.',
    [
      FreeResource(
        'Gallica',
        'La bibliothèque numérique de la BnF : livres, journaux, revues.',
        'https://gallica.bnf.fr',
      ),
      FreeResource(
        'Wikisource',
        'Des milliers de textes libres en français, téléchargeables en PDF.',
        'https://fr.wikisource.org',
      ),
      FreeResource(
        'Ebooks libres et gratuits',
        'Classiques de la littérature française, en PDF.',
        'https://www.ebooksgratuits.com',
      ),
      FreeResource(
        'Bibebook',
        'Livres du domaine public, en PDF et ePub.',
        'https://www.bibebook.com',
      ),
      FreeResource(
        'Projet Gutenberg',
        'Plus de 70 000 livres gratuits, surtout en anglais.',
        'https://www.gutenberg.org',
      ),
      FreeResource(
        'Standard Ebooks',
        'Classiques anglais soigneusement mis en page.',
        'https://standardebooks.org',
      ),
    ],
  ),
  ResourceSection(
    'Livres audio gratuits',
    'Des livres lus par des voix humaines, à écouter ou télécharger.',
    [
      FreeResource(
        'Littérature audio',
        'Des milliers de livres audio gratuits en français.',
        'https://www.litteratureaudio.com',
      ),
      FreeResource(
        'Audiocité',
        'Livres audio gratuits en français : romans, contes, poésie.',
        'https://www.audiocite.net',
      ),
      FreeResource(
        'LibriVox',
        'Livres du domaine public lus par des bénévoles, dans de nombreuses '
            'langues.',
        'https://librivox.org',
      ),
    ],
  ),
];
