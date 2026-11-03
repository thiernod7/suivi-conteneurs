import 'package:flutter/material.dart';

import '../domaine/calculs.dart';
import '../domaine/modeles.dart';
import 'format.dart';
import 'illustrations/produits.dart';
import 'theme.dart';

/// Contenu d'une page : largeur limitée sur grand écran, marges réduites sur téléphone.
class PageContenu extends StatelessWidget {
  const PageContenu({super.key, required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(marge, marge, marge, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: enfants),
        ),
      ),
    );
  }
}

class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {super.key, required this.icone});

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Row(children: [
          Icon(icone, size: 24),
          const SizedBox(width: 8),
          Flexible(child: Text(titre, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700))),
        ]),
      );
}

/// Grille qui s'adapte à la largeur. La dernière ligne, si elle est incomplète, prend toute la largeur.
class Grille extends StatelessWidget {
  const Grille({super.key, required this.enfants, this.largeurMin = 200, this.colonnesMin = 1, this.espace = 12});

  final List<Widget> enfants;
  final double largeurMin;
  final int colonnesMin;
  final double espace;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final colonnes = ((c.maxWidth + espace) / (largeurMin + espace)).floor().clamp(colonnesMin, enfants.length);
        double largeur(int parLigne) => (c.maxWidth - espace * (parLigne - 1)) / parLigne;
        final derniers = enfants.length % colonnes;
        return Wrap(spacing: espace, runSpacing: espace, children: [
          for (var i = 0; i < enfants.length; i++)
            SizedBox(
              width: derniers > 0 && i >= enfants.length - derniers ? largeur(derniers) : largeur(colonnes),
              child: enfants[i],
            ),
        ]);
      });
}

/// Un montant en grand, « GNF » en petit à côté.
class Montant extends StatelessWidget {
  const Montant(this.texte, {super.key, this.couleur, this.taille = 30});

  final String texte;
  final Color? couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: texte, style: TextStyle(fontSize: taille, fontWeight: FontWeight.w700)),
          TextSpan(text: ' GNF', style: TextStyle(fontSize: taille * .45, fontWeight: FontWeight.w700)),
        ]),
        style: TextStyle(color: couleur, fontFeatures: const [FontFeature.tabularFigures()]),
      );
}

/// Un chiffre clé : une icône, un mot, un montant.
class CaseChiffre extends StatelessWidget {
  const CaseChiffre({super.key, required this.icone, required this.mot, required this.montant, this.couleur, this.grand = false});

  final IconData icone;
  final String mot;
  final String montant;
  final Color? couleur;
  final bool grand;

  @override
  Widget build(BuildContext context) {
    final teinte = couleur ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: grand ? 22 : 18,
              backgroundColor: teinte.withValues(alpha: .14),
              child: Icon(icone, color: teinte, size: grand ? 26 : 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mot, style: TextStyle(fontSize: grand ? 20 : 17, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Montant(montant, couleur: couleur, taille: grand ? 36 : 26),
          ),
        ]),
      ),
    );
  }
}

/// Un chiffre sur une ligne : icône, mot à gauche, montant à droite.
class LigneChiffre extends StatelessWidget {
  const LigneChiffre({super.key, required this.icone, required this.mot, required this.montant, this.couleur});

  final IconData icone;
  final String mot;
  final String montant;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icone, color: couleur ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(mot, style: const TextStyle(fontSize: 18))),
          Montant(montant, couleur: couleur, taille: 22),
        ]),
      );
}

/// Le statut de paiement : une icône, un mot, une couleur.
class StatutBadge extends StatelessWidget {
  const StatutBadge(this.statut, {super.key});

  final StatutPaiement statut;

  static String mot(StatutPaiement s) => switch (s) {
        StatutPaiement.solde => 'Payé',
        StatutPaiement.partiel => 'En partie',
        StatutPaiement.impaye => 'Pas payé',
      };

  static IconData icone(StatutPaiement s) => switch (s) {
        StatutPaiement.solde => Icons.check_circle,
        StatutPaiement.partiel => Icons.timelapse,
        StatutPaiement.impaye => Icons.cancel,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(color: c.statutFond(statut), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone(statut), size: 18, color: c.statut(statut)),
        const SizedBox(width: 4),
        Text(mot(statut), style: TextStyle(color: c.statut(statut), fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

/// Le carré de couleur qui représente un conteneur, avec la partie du numéro qu'on retient.
class CarreConteneur extends StatelessWidget {
  const CarreConteneur(this.conteneur, {super.key, this.taille = 56});

  final Conteneur conteneur;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: context.couleurs.conteneur(conteneur.couleur),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.inventory_2, color: Colors.white, size: taille * .5),
      );
}

/// Rond avec les initiales du client.
class AvatarClient extends StatelessWidget {
  const AvatarClient(this.client, {super.key, this.rayon = 22});

  final Client client;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    final mots = client.nom.split(' ').where((m) => m.isNotEmpty).toList();
    final initiales = (mots.length >= 2 ? mots[mots.length - 2][0] + mots.last[0] : mots.first[0]).toUpperCase();
    return CircleAvatar(
      radius: rayon,
      backgroundColor: Color(client.apparence.vetement),
      child: Text(initiales,
          style: TextStyle(
              color: Color(client.apparence.vetement).computeLuminance() > .5 ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: rayon * .75)),
    );
  }
}

/// Barre « vendu » dans la couleur du conteneur.
class BarreVente extends StatelessWidget {
  const BarreVente({super.key, required this.part, required this.couleur});

  final double part;
  final Color couleur;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: part,
          minHeight: 10,
          color: couleur,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
}

/// « Chine » à partir de « Guangzhou, Chine ».
String pays(Conteneur c) => c.origine.split(',').last.trim();

/// Gagné ou perdu, avec la flèche et la couleur qui vont avec.
class Resultat extends StatelessWidget {
  const Resultat(this.montant, {super.key, this.taille = 22});

  final int montant;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final gagne = montant >= 0;
    final couleur = gagne ? context.couleurs.ok : context.couleurs.alerte;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(gagne ? Icons.arrow_upward : Icons.arrow_downward, color: couleur, size: taille),
      Text(court(montant.abs()),
          style: TextStyle(color: couleur, fontSize: taille, fontWeight: FontWeight.w700)),
    ]);
  }
}

/// Une ligne de la liste des conteneurs.
class LigneConteneur extends StatelessWidget {
  const LigneConteneur(this.calcul, {super.key, required this.onTap});

  final CalculConteneur calcul;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = calcul.conteneur;
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              CarreConteneur(c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.numeroCourt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('${pays(c)} · ${date(c.arrivee)}', style: TextStyle(color: muet)),
                  const SizedBox(height: 4),
                  Row(children: [
                    for (final p in c.produits)
                      Padding(padding: const EdgeInsets.only(right: 6), child: IconeDeProduit(p.icone, taille: 24)),
                  ]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Resultat(calcul.resultat),
                Text(calcul.resultat >= 0 ? 'Gagné' : 'Perdu', style: TextStyle(color: muet)),
              ]),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: muet),
            ]),
            const SizedBox(height: 12),
            BarreVente(part: calcul.partVendue, couleur: context.couleurs.conteneur(c.couleur)),
            const SizedBox(height: 4),
            Row(children: [
              Text('Vendu ${pourcent(calcul.partVendue)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(calcul.provisoire ? 'En vente' : 'Tout vendu', style: TextStyle(color: muet)),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Une ligne « client » : qui, combien il doit, où il en est.
class LigneClient extends StatelessWidget {
  const LigneClient({super.key, required this.client, required this.doit, required this.statut});

  final Client client;
  final int doit;
  final StatutPaiement statut;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          AvatarClient(client),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(client.nom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text(client.quartier, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (doit > 0)
              Text(court(doit),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.couleurs.alerte)),
            const SizedBox(height: 2),
            StatutBadge(statut),
          ]),
        ]),
      );
}
