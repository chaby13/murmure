#!/usr/bin/env python3
"""Construit les listes de mots du correcteur d'orthographe de Murmure.

Développe les dictionnaires Hunspell (toutes les formes : pluriels,
conjugaisons…) et les classe par fréquence d'usage. Les élisions (l', d',
qu'…) sont gérées par l'appli, pas par la liste.

Usage : tool/build_dictionaries.py FR.aff FR.dic FR_FREQ.txt fr \
                                   EN.aff EN.dic EN_FREQ.txt en  SORTIE/
Sortie : SORTIE/<langue>.txt.gz, un mot par ligne, du plus courant au
plus rare.

Sources utilisées pour assets/dictionaries/ :
  - paquets Ubuntu hunspell-fr-classical (7.0) et hunspell-en-us
    (apt-get download, puis dpkg -x) ;
  - https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/
    content/2018/{fr,en}/{fr,en}_full.txt
"""
import gzip, re, sys
from collections import defaultdict


def parse_flags(s, long):
    if not s:
        return []
    if long:
        return [s[i:i + 2] for i in range(0, len(s), 2)]
    if ',' in s:
        return s.split(',')
    return list(s)


def load_aff(path):
    long = False
    rules = {}  # flag -> (kind, cross, [(strip, add, contflags, regex)])
    special = {}
    lines = open(path, encoding='utf-8').read().splitlines()
    i = 0
    while i < len(lines):
        parts = lines[i].split()
        i += 1
        if not parts or parts[0].startswith('#'):
            continue
        if parts[0] == 'FLAG' and parts[1] == 'long':
            long = True
        elif parts[0] in ('NEEDAFFIX', 'FORBIDDENWORD', 'ONLYINCOMPOUND'):
            special[parts[0]] = parts[1]
        elif parts[0] in ('PFX', 'SFX') and len(parts) == 4 and parts[3].isdigit():
            kind, flag, cross, n = parts[0], parts[1], parts[2] == 'Y', int(parts[3])
            entries = []
            for _ in range(n):
                p = lines[i].split()
                i += 1
                strip = '' if p[2] == '0' else p[2]
                add, _, cont = p[3].partition('/')
                add = '' if add == '0' else add
                cond = p[4] if len(p) > 4 else '.'
                regex = re.compile(('^' + cond) if kind == 'PFX' else (cond + '$'))
                entries.append((strip, add, parse_flags(cont, long), regex))
            rules[flag] = (kind, cross, entries)
    return rules, special, long


def apply(word, rule):
    kind, _, entries = rule
    for strip, add, cont, regex in entries:
        if not regex.search(word):
            continue
        if kind == 'SFX':
            if strip and not word.endswith(strip):
                continue
            yield (word[:len(word) - len(strip)] if strip else word) + add, cont
        else:
            if strip and not word.startswith(strip):
                continue
            yield add + word[len(strip):], cont


def expand(aff, dic):
    rules, special, long = load_aff(aff)
    need = special.get('NEEDAFFIX')
    forbidden = special.get('FORBIDDENWORD')
    only_compound = special.get('ONLYINCOMPOUND')
    words = set()
    lines = open(dic, encoding='utf-8').read().splitlines()[1:]
    for line in lines:
        line = line.split('\t')[0].split(' ')[0].strip()
        if not line:
            continue
        # « / » échappé : rare, ignoré.
        base, _, f = line.partition('/')
        flags = parse_flags(f, long)
        if forbidden in flags or only_compound in flags:
            continue
        forms = []
        if need not in flags:
            forms.append(base)
        sfx = [rules[x] for x in flags if x in rules and rules[x][0] == 'SFX']
        pfx = [rules[x] for x in flags if x in rules and rules[x][0] == 'PFX']
        suffixed = []
        for r in sfx:
            for w, cont in apply(base, r):
                if need not in cont:
                    suffixed.append((w, r[1]))
                # Double suffixe (suffixe de suffixe).
                for c in cont:
                    if c in rules and rules[c][0] == 'SFX':
                        for w2, cont2 in apply(w, rules[c]):
                            if need not in cont2:
                                suffixed.append((w2, rules[c][1]))
        forms += [w for w, _ in suffixed]
        for r in pfx:
            # Les élisions (l', d', qu'…) sont traitées par l'appli.
            if any(add.endswith(("'", "’")) for _, add, _, _ in r[2]):
                continue
            for w, cont in apply(base, r):
                if need not in cont:
                    forms.append(w)
            if r[1]:
                for s, cross in suffixed:
                    if cross:
                        forms += [w for w, _ in apply(s, r)]
        for w in forms:
            w = w.replace('’', "'")
            if w and not any(ch.isdigit() for ch in w):
                words.add(w)
    return words


def frequencies(path):
    freq = {}
    for line in open(path, encoding='utf-8'):
        parts = line.split()
        if len(parts) == 2 and parts[1].isdigit():
            freq.setdefault(parts[0], int(parts[1]))
    return freq


def main():
    args = sys.argv[1:]
    out = args[-1]
    for k in range(0, len(args) - 1, 4):
        aff, dic, freqfile, lang = args[k:k + 4]
        words = expand(aff, dic)
        freq = frequencies(freqfile)
        # Les sous-titres sont en minuscules : un mot avec majuscule (nom
        # propre, sigle) prend la fréquence de sa forme minuscule, réduite
        # s'il existe aussi en minuscules.
        def score(w):
            low = w.lower()
            if w == low:
                return freq.get(w, 0)
            return freq.get(low, 0) // (100 if low in words else 1)
        ranked = sorted(words, key=lambda w: (-score(w), w))
        with gzip.open(f'{out}/{lang}.txt.gz', 'wt', encoding='utf-8', compresslevel=9) as f:
            f.write('\n'.join(ranked) + '\n')
        known = sum(1 for w in words if w.lower() in freq)
        print(lang, len(words), 'mots,', known, 'avec fréquence')


if __name__ == '__main__':
    main()
