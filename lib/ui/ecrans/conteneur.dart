import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('${pays(c)} · arrivé le ${date(c.arrivee)}', style: TextStyle(color: couleurs.muet, fontSize: 15.5)),
          Chip(
            avatar: Icon(calcul.provisoire ? Symbols.storefront : Symbols.done_all, size: 18),
            label: Text(calcul.provisoire ? 'En vente' : 'Tout vendu'),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 14),
        Grille(largeurMin: 180, colonnesMin: 2, enfants: [
          CaseChiffre(icone: Symbols.shopping_cart, mot: 'Dépensé', montant: court(calcul.cout)),
          CaseChiffre(icone: Symbols.sell, mot: 'Vendu', montant: court(calcul.ventes)),
          CaseChiffre(
            icone: Symbols.hourglass_bottom,
            mot: 'On me doit',
            montant: court(calcul.reste),
            couleur: calcul.reste > 0 ? couleurs.alerte : couleurs.ok,
          ),
          CaseChiffre(
            icone: gagne ? Symbols.trending_up : Symbols.trending_down,
            mot: gagne ? 'Gagné' : 'Perdu',
            montant: court(calcul.resultat.abs()),
            couleur: gagne ? couleurs.ok : couleurs.alerte,
          ),
        ]),
        if (calcul.provisoire && calcul.valeurStock > 0) ...[
          const SizedBox(height: 12),
          Note(
            icone: Symbols.info,
            texte: 'Pas encore tout vendu. Si tout part : ${calcul.resultatPrevu >= 0 ? 'gagné' : 'perdu'} '
                '${court(calcul.resultatPrevu.abs())} GNF.',
          ),
        ],
        const TitreSection('Dedans', icone: Symbols.package_2),
        Grille(largeurMin: 300, enfants: [
          for (final p in calcul.produits) _CarteProduit(p, couleur: couleurs.conteneur(c.couleur)),
        ]),
        const TitreSection('Clients', icone: Symbols.group),
        CarteListe(lignes: [
          for (final part in calcul.parClient)
            LigneClient(
              client: suivi.client(part.clientId).client,
              doit: part.doit,
              statut: part.statut,
              onTap: () => context.push('/clients/${part.clientId}'),
            ),
        ]),
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
    final muet = context.couleurs.muet;
    final recu = p.produit.quantiteRecue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconeDeProduit(p.produit.icone, taille: 36),
            const SizedBox(width: 12),
            Expanded(child: Text(p.produit.nom, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 14),
          Barre(part: recu == 0 ? 0 : p.vendu / recu, couleur: couleur),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, children: [
              Text('Vendu ${nombre(p.vendu)} / ${nombre(recu)}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Reste ${nombre(p.stock)}', style: TextStyle(color: muet)),
            ]),
          ),
          if (p.rendu > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Symbols.undo, size: 18, color: muet),
              const SizedBox(width: 4),
              Flexible(
                child: Text('Rendus ${nombre(p.rendu)}${p.rebut > 0 ? ' · abîmés ${nombre(p.rebut)}' : ''}',
                    style: TextStyle(color: muet)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
