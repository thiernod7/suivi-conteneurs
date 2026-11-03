import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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
            icone: gagne ? Symbols.trending_up : Symbols.trending_down,
            mot: gagne ? 'Gagné' : 'Perdu',
            montant: court(t.resultat.abs()),
            couleur: gagne ? c.ok : c.alerte,
          ),
          CaseChiffre(
            grand: true,
            icone: Symbols.hourglass_bottom,
            mot: 'On me doit',
            montant: court(t.reste),
            couleur: c.alerte,
          ),
        ]),
        const SizedBox(height: 12),
        CarteListe(lignes: [
          LigneChiffre(icone: Symbols.shopping_cart, mot: 'Dépensé', montant: court(t.investi)),
          LigneChiffre(icone: Symbols.sell, mot: 'Vendu', montant: court(t.ventes)),
          LigneChiffre(icone: Symbols.payments, mot: 'Reçu', montant: court(t.encaisse), couleur: c.ok),
        ]),
        const TitreSection('Qui me doit ?', icone: Symbols.person_search),
        CarteListe(lignes: [
          for (final k in debiteurs.take(3))
            LigneClient(
              client: k.client,
              doit: k.doit,
              statut: k.statut,
              alerte: k.depasseLimite,
              onTap: () => context.push('/clients/${k.client.id}'),
            ),
        ]),
        const TitreSection('Mes conteneurs', icone: Symbols.package_2),
        Grille(largeurMin: 420, enfants: [
          for (final cc in conteneurs)
            LigneConteneur(cc, onTap: () => context.push('/conteneurs/${cc.conteneur.id}')),
        ]),
      ]),
    );
  }
}
