import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domaine/modeles.dart';
import 'theme.dart';

// Recherche et filtres, les mêmes sur toutes les listes :
// une case pour chercher, des filtres simples, et un filtre par conteneur (son carré de couleur).

/// Texte sans majuscules ni accents : « Keïta » se trouve en tapant « keita ».
String simplifier(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c');

/// Vrai si [recherche] apparaît dans l'un des [textes].
bool correspond(Iterable<String> textes, String recherche) {
  final r = simplifier(recherche.trim());
  return r.isEmpty || textes.any((t) => simplifier(t).contains(r));
}

class Filtre<T> {
  const Filtre(this.valeur, this.libelle, {this.icone});

  final T valeur;
  final String libelle;
  final IconData? icone;
}

/// La case de recherche, les filtres, puis les conteneurs.
class BarreRecherche<T> extends StatelessWidget {
  const BarreRecherche({
    super.key,
    required this.controleur,
    required this.indice,
    required this.filtres,
    required this.filtre,
    required this.nombre,
    required this.onFiltre,
    required this.conteneurs,
    required this.conteneur,
    required this.onConteneur,
    required this.onRecherche,
  });

  final TextEditingController controleur;

  /// Ce qu'on peut chercher, écrit en gris dans la case.
  final String indice;
  final List<Filtre<T>> filtres;
  final T filtre;

  /// Combien de résultats donnerait chaque filtre.
  final int Function(T) nombre;
  final ValueChanged<T> onFiltre;
  final List<Conteneur> conteneurs;

  /// Le conteneur choisi, ou null pour tous.
  final String? conteneur;
  final ValueChanged<String?> onConteneur;
  final ValueChanged<String> onRecherche;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ValueListenableBuilder(
        valueListenable: controleur,
        builder: (context, valeur, _) => TextField(
          controller: controleur,
          onChanged: onRecherche,
          decoration: InputDecoration(
            prefixIcon: const Icon(Symbols.search),
            hintText: indice,
            suffixIcon: valeur.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Symbols.close),
                    onPressed: () {
                      controleur.clear();
                      onRecherche('');
                    },
                  ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _Rangee(children: [
        for (final f in filtres)
          ChoiceChip(
            avatar: f.icone == null ? null : Icon(f.icone, size: 18),
            label: Text('${f.libelle}  ${nombre(f.valeur)}'),
            selected: filtre == f.valeur,
            onSelected: (_) => onFiltre(f.valeur),
          ),
      ]),
      if (conteneurs.length > 1) ...[
        const SizedBox(height: 8),
        _Rangee(children: [
          for (final k in conteneurs)
            ChoiceChip(
              avatar: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: c.conteneur(k.couleur), borderRadius: BorderRadius.circular(3)),
              ),
              label: Text(k.numeroCourt),
              selected: conteneur == k.id,
              // Toucher le conteneur choisi enlève le filtre.
              onSelected: (_) => onConteneur(conteneur == k.id ? null : k.id),
            ),
        ]),
      ],
    ]);
  }
}

/// Une rangée de filtres sur une seule ligne, qu'on fait glisser de côté si elle est trop longue.
class _Rangee extends StatelessWidget {
  const _Rangee({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(spacing: 8, children: children),
      );
}

/// Quand rien ne correspond : une icône, un mot, et un bouton pour tout revoir.
class AucunResultat extends StatelessWidget {
  const AucunResultat({super.key, required this.icone, required this.texte, required this.onToutVoir});

  final IconData icone;
  final String texte;
  final VoidCallback onToutVoir;

  @override
  Widget build(BuildContext context) {
    final muet = context.couleurs.muet;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(icone, size: 48, color: muet, weight: 200),
        const SizedBox(height: 8),
        Text(texte, style: TextStyle(fontSize: 18, color: muet)),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: onToutVoir, icon: const Icon(Symbols.refresh), label: const Text('Tout voir')),
      ]),
    );
  }
}
