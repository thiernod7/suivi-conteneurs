import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../composants.dart';
import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// L'essentiel en un coup d'œil : ce que j'ai gagné, ce qu'on me doit, qui me doit, mes conteneurs.
class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final t = suivi.totaux;
    final c = context.couleurs;
    final gagne = t.resultat >= 0;
    final debiteurs = suivi.clients.where((k) => k.doit > 0).toList()..sort((a, b) => b.doit.compareTo(a.doit));
    final conteneurs = [...suivi.conteneurs]..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: PageContenu(enfants: [
        Grille(largeurMin: 300, enfants: [
          CaseChiffre(
            grand: true,
            icone: gagne ? Icons.trending_up : Icons.trending_down,
            mot: gagne ? 'Gagné' : 'Perdu',
            montant: court(t.resultat.abs()),
            couleur: gagne ? c.ok : c.alerte,
          ),
          CaseChiffre(
            grand: true,
            icone: Icons.hourglass_bottom,
            mot: 'On me doit',
            montant: court(t.reste),
            couleur: c.alerte,
          ),
        ]),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            LigneChiffre(icone: Icons.shopping_cart_outlined, mot: 'Dépensé', montant: court(t.investi)),
            const Divider(height: 1),
            LigneChiffre(icone: Icons.sell_outlined, mot: 'Vendu', montant: court(t.ventes)),
            const Divider(height: 1),
            LigneChiffre(icone: Icons.payments_outlined, mot: 'Reçu', montant: court(t.encaisse), couleur: c.ok),
          ]),
        ),
        const TitreSection('Qui me doit ?', icone: Icons.person_search),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, k) in debiteurs.take(3).indexed) ...[
              if (i > 0) const Divider(height: 1),
              LigneClient(client: k.client, doit: k.doit, statut: k.statut),
            ],
          ]),
        ),
        const TitreSection('Mes conteneurs', icone: Icons.inventory_2_outlined),
        Grille(largeurMin: 420, enfants: [
          for (final cc in conteneurs)
            LigneConteneur(cc, onTap: () => context.push('/conteneurs/${cc.conteneur.id}')),
        ]),
      ]),
    );
  }
}
