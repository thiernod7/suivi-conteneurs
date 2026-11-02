import 'package:flutter/material.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../format.dart';
import '../illustrations/port.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// Tableau de bord : l'histoire en une image, les totaux, puis les conteneurs.
class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final t = suivi.totaux;
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    return PageContenu(enfants: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 16,
        runSpacing: 8,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Etiquette('Marché de Madina · Conakry'),
            const SizedBox(height: 6),
            Text('DU BATEAU\nAU CLIENT', style: Theme.of(context).textTheme.displaySmall),
          ]),
          Text('Situation au ${date(suivi.aujourdhui)} · données d\'exemple', style: TextStyle(color: muet)),
        ],
      ),
      const SizedBox(height: 20),
      Card(clipBehavior: Clip.antiAlias, child: ScenePort(nombreConteneurs: suivi.conteneurs.length)),
      const SizedBox(height: 20),
      Grille(largeurMin: 190, colonnesMin: 2, enfants: [
        Indicateur(
          etiquette: 'Investi',
          valeur: court(t.investi),
          detail: '${suivi.conteneurs.length} conteneurs',
        ),
        Indicateur(etiquette: 'Ventes', valeur: court(t.ventes), detail: 'après retours et remises'),
        Indicateur(
          etiquette: 'Encaissé',
          valeur: court(t.encaisse),
          detail: '${pourcent(t.encaisse / t.ventes)} des ventes',
        ),
        Indicateur(
          etiquette: 'Reste à percevoir',
          valeur: court(t.reste),
          detail: '${suivi.clients.where((k) => k.doit > 0).length} clients doivent encore',
          couleur: context.couleurs.alerte,
        ),
        Indicateur(
          etiquette: 'Résultat à ce jour',
          valeur: signe(t.resultat),
          detail: 'ventes − coûts des conteneurs',
          couleur: t.resultat >= 0 ? context.couleurs.ok : context.couleurs.alerte,
        ),
      ]),
      TitreSection('Conteneurs', detail: 'Du plus récent au plus ancien'),
      ListeConteneurs(suivi.conteneurs),
    ]);
  }
}

class ListeConteneurs extends StatelessWidget {
  const ListeConteneurs(this.conteneurs, {super.key});

  final List<CalculConteneur> conteneurs;

  @override
  Widget build(BuildContext context) {
    final tries = [...conteneurs]..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    return Grille(largeurMin: 420, espace: 14, enfants: [for (final c in tries) CarteConteneur(c)]);
  }
}
