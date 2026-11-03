import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// Un conteneur : combien il a coûté, combien il a rapporté, ce qui reste dedans, qui a pris quoi.
class EcranConteneur extends StatelessWidget {
  const EcranConteneur({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final calcul = suivi.conteneur(id);
    final c = calcul.conteneur;
    final couleurs = context.couleurs;
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    final gagne = calcul.resultat >= 0;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/conteneurs')),
        title: Row(children: [
          CarreConteneur(c, taille: 32),
          const SizedBox(width: 10),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Conteneur ${c.numeroCourt}'))),
        ]),
      ),
      body: PageContenu(enfants: [
        Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('${pays(c)} · arrivé le ${date(c.arrivee)}', style: TextStyle(color: muet, fontSize: 16)),
          Chip(
            avatar: Icon(calcul.provisoire ? Icons.storefront : Icons.done_all, size: 18),
            label: Text(calcul.provisoire ? 'En vente' : 'Tout vendu'),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 14),
        Grille(largeurMin: 180, colonnesMin: 2, enfants: [
          CaseChiffre(icone: Icons.shopping_cart_outlined, mot: 'Dépensé', montant: court(calcul.cout)),
          CaseChiffre(icone: Icons.sell_outlined, mot: 'Vendu', montant: court(calcul.ventes)),
          CaseChiffre(
            icone: Icons.hourglass_bottom,
            mot: 'On me doit',
            montant: court(calcul.reste),
            couleur: calcul.reste > 0 ? couleurs.alerte : couleurs.ok,
          ),
          CaseChiffre(
            icone: gagne ? Icons.trending_up : Icons.trending_down,
            mot: gagne ? 'Gagné' : 'Perdu',
            montant: court(calcul.resultat.abs()),
            couleur: gagne ? couleurs.ok : couleurs.alerte,
          ),
        ]),
        if (calcul.provisoire && calcul.valeurStock > 0) ...[
          const SizedBox(height: 10),
          _Note(
            icone: Icons.info_outline,
            texte: 'Pas encore tout vendu. Si tout part : ${calcul.resultatPrevu >= 0 ? 'gagné' : 'perdu'} '
                '${court(calcul.resultatPrevu.abs())} GNF.',
          ),
        ],
        const TitreSection('Dedans', icone: Icons.inventory_2_outlined),
        Grille(largeurMin: 300, enfants: [
          for (final p in calcul.produits) _CarteProduit(p, couleur: couleurs.conteneur(c.couleur)),
        ]),
        const TitreSection('Clients', icone: Icons.people_outline),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, part) in calcul.parClient.indexed) ...[
              if (i > 0) const Divider(height: 1),
              LigneClient(client: suivi.client(part.clientId).client, doit: part.doit, statut: part.statut),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _CarteProduit extends StatelessWidget {
  const _CarteProduit(this.p, {required this.couleur});

  final CalculProduit p;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    final recu = p.produit.quantiteRecue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconeDeProduit(p.produit.icone, taille: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(p.produit.nom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          BarreVente(part: recu == 0 ? 0 : p.vendu / recu, couleur: couleur),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, children: [
              Text('Vendu ${nombre(p.vendu)} / ${nombre(recu)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Reste ${nombre(p.stock)}', style: TextStyle(color: muet)),
            ]),
          ),
          if (p.rendu > 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.undo, size: 18, color: muet),
              const SizedBox(width: 4),
              Text('Rendus ${nombre(p.rendu)}${p.rebut > 0 ? ' · abîmés ${nombre(p.rebut)}' : ''}',
                  style: TextStyle(color: muet)),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icone, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(texte, style: const TextStyle(fontSize: 16))),
        ]),
      );
}
