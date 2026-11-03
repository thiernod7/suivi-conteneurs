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

/// La case de recherche et le bouton « Filtres ». Les filtres se choisissent dans un panneau
/// qui monte du bas de l'écran ; ceux qui sont actifs s'affichent sous la recherche, avec une croix.
class BarreRecherche<T> extends StatelessWidget {
  const BarreRecherche({
    super.key,
    required this.controleur,
    required this.indice,
    required this.onRecherche,
    required this.titreFiltres,
    required this.iconeFiltres,
    required this.filtres,
    required this.filtre,
    required this.conteneurs,
    required this.conteneur,
    required this.nombre,
    required this.onAppliquer,
  });

  final TextEditingController controleur;

  /// Ce qu'on peut chercher, écrit en gris dans la case.
  final String indice;
  final ValueChanged<String> onRecherche;

  /// Titre et icône de la première partie du panneau (ex. « Paiement »).
  final String titreFiltres;
  final IconData iconeFiltres;

  /// Le premier filtre est celui « par défaut » (tout voir).
  final List<Filtre<T>> filtres;
  final T filtre;
  final List<Conteneur> conteneurs;

  /// Le conteneur choisi, ou null pour tous.
  final String? conteneur;

  /// Combien de résultats donneraient ce filtre et ce conteneur.
  final int Function(T filtre, String? conteneur) nombre;
  final void Function(T filtre, String? conteneur) onAppliquer;

  T get _defaut => filtres.first.valeur;
  int get _actifs => (filtre == _defaut ? 0 : 1) + (conteneur == null ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final choisi = filtres.firstWhere((f) => f.valeur == filtre);
    final k = conteneurs.where((k) => k.id == conteneur).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: ValueListenableBuilder(
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
        ),
        const SizedBox(width: 10),
        Badge.count(
          count: _actifs,
          isLabelVisible: _actifs > 0,
          child: IconButton.outlined(
            tooltip: 'Filtres',
            style: IconButton.styleFrom(
              minimumSize: const Size(54, 54),
              side: BorderSide(color: c.trait, width: .8),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            icon: const Icon(Symbols.tune),
            onPressed: () => _ouvrir(context),
          ),
        ),
      ]),
      if (_actifs > 0) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (filtre != _defaut)
            InputChip(
              avatar: choisi.icone == null ? null : Icon(choisi.icone, size: 18),
              label: Text(choisi.libelle),
              deleteButtonTooltipMessage: 'Enlever',
              onDeleted: () => onAppliquer(_defaut, conteneur),
            ),
          if (k != null)
            InputChip(
              avatar: _Carre(k),
              label: Text(k.numeroCourt),
              deleteButtonTooltipMessage: 'Enlever',
              onDeleted: () => onAppliquer(filtre, null),
            ),
        ]),
      ],
    ]);
  }

  Future<void> _ouvrir(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        builder: (context) {
          // Les choix ne comptent qu'après « Voir les résultats ».
          var f = filtre;
          var k = conteneur;
          return StatefulBuilder(builder: (context, setState) {
            final c = context.couleurs;
            Widget titre(String texte, IconData icone) => Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 10),
                  child: Row(children: [
                    Icon(icone, size: 20, color: c.muet),
                    const SizedBox(width: 8),
                    Text(texte, style: TextStyle(fontSize: 16, color: c.muet)),
                  ]),
                );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Filtres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                titre(titreFiltres, iconeFiltres),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final x in filtres)
                    ChoiceChip(
                      avatar: x.icone == null ? null : Icon(x.icone, size: 18),
                      label: Text('${x.libelle}  ${nombre(x.valeur, k)}'),
                      selected: f == x.valeur,
                      onSelected: (_) => setState(() => f = x.valeur),
                    ),
                ]),
                if (conteneurs.length > 1) ...[
                  titre('Conteneur', Symbols.package_2),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final x in conteneurs)
                      ChoiceChip(
                        avatar: _Carre(x),
                        label: Text(x.numeroCourt),
                        selected: k == x.id,
                        // Toucher à nouveau le conteneur choisi l'enlève.
                        onSelected: (_) => setState(() => k = k == x.id ? null : x.id),
                      ),
                  ]),
                ],
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                      onPressed: () => setState(() {
                        f = _defaut;
                        k = null;
                      }),
                      icon: const Icon(Symbols.restart_alt),
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Réinitialiser')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      onPressed: () {
                        onAppliquer(f, k);
                        Navigator.pop(context);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Voir les résultats · ${nombre(f, k)}', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ]),
              ]),
            );
          });
        },
      );
}

class _Carre extends StatelessWidget {
  const _Carre(this.conteneur);

  final Conteneur conteneur;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: context.couleurs.conteneur(conteneur.couleur),
          borderRadius: BorderRadius.circular(3),
        ),
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
