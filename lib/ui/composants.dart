import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      // En bas, de la place pour le bouton « + ».
      padding: EdgeInsets.fromLTRB(marge, 8, marge, 104),
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
        padding: const EdgeInsets.only(top: 28, bottom: 10, left: 2),
        child: Row(children: [
          Icon(icone, size: 22, color: context.couleurs.muet),
          const SizedBox(width: 8),
          Flexible(child: Text(titre, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
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
        if (enfants.isEmpty) return const SizedBox.shrink();
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

/// Carte blanche bordée d'un trait fin, dont les lignes sont séparées par un trait fin.
class CarteListe extends StatelessWidget {
  const CarteListe({super.key, required this.lignes});

  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < lignes.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            lignes[i],
          ],
        ]),
      );
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
          TextSpan(text: texte, style: TextStyle(fontSize: taille, fontWeight: FontWeight.w600, letterSpacing: -.3)),
          TextSpan(
            text: ' GNF',
            style: TextStyle(fontSize: taille * .42, fontWeight: FontWeight.w400, color: context.couleurs.muet),
          ),
        ]),
        style: TextStyle(color: couleur, fontFeatures: const [FontFeature.tabularFigures()]),
      );
}

/// Un chiffre clé : une icône fine et un mot, puis le montant en grand.
class CaseChiffre extends StatelessWidget {
  const CaseChiffre({super.key, required this.icone, required this.mot, required this.montant, this.couleur, this.grand = false});

  final IconData icone;
  final String mot;
  final String montant;
  final Color? couleur;
  final bool grand;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: EdgeInsets.all(grand ? 20 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icone, size: grand ? 24 : 22, color: couleur ?? context.couleurs.muet),
              const SizedBox(width: 8),
              Expanded(child: Text(mot, style: TextStyle(fontSize: grand ? 18 : 16, color: context.couleurs.muet))),
            ]),
            SizedBox(height: grand ? 10 : 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Montant(montant, couleur: couleur, taille: grand ? 38 : 26),
            ),
          ]),
        ),
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icone, color: couleur ?? context.couleurs.muet),
          const SizedBox(width: 12),
          Expanded(child: Text(mot, style: const TextStyle(fontSize: 17))),
          Montant(montant, couleur: couleur, taille: 21),
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
        StatutPaiement.solde => Symbols.check_circle,
        StatutPaiement.partiel => Symbols.clock_loader_40,
        StatutPaiement.impaye => Symbols.cancel,
      };

  @override
  Widget build(BuildContext context) {
    final couleur = context.couleurs.statut(statut);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: .08),
        border: Border.all(color: couleur.withValues(alpha: .35), width: .8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone(statut), size: 17, color: couleur, weight: 400),
        const SizedBox(width: 4),
        Text(mot(statut), style: TextStyle(color: couleur, fontWeight: FontWeight.w500, fontSize: 14)),
      ]),
    );
  }
}

/// Le carré de couleur qui représente un conteneur.
class CarreConteneur extends StatelessWidget {
  const CarreConteneur(this.conteneur, {super.key, this.taille = 52});

  final Conteneur conteneur;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: context.couleurs.conteneur(conteneur.couleur),
          borderRadius: BorderRadius.circular(taille * .24),
        ),
        child: Icon(Symbols.package_2, color: Colors.white, size: taille * .52, weight: 300),
      );
}

/// Petite étiquette d'un conteneur : un carré de couleur et ses 6 chiffres.
/// Un seul texte : il passe à la ligne au lieu de déborder quand la place manque.
class PuceConteneur extends StatelessWidget {
  const PuceConteneur(this.conteneur, {super.key});

  final Conteneur conteneur;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: context.couleurs.conteneur(conteneur.couleur),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          TextSpan(text: conteneur.numeroCourt),
        ]),
        style: TextStyle(fontSize: 13.5, color: context.couleurs.muet),
      );
}

/// Rond avec les initiales du client.
class AvatarClient extends StatelessWidget {
  const AvatarClient(this.client, {super.key, this.rayon = 22});

  final Client client;
  final double rayon;

  static String initiales(String nom) {
    final mots = nom.split(' ').where((m) => m.isNotEmpty).toList();
    return (mots.length >= 2 ? mots[mots.length - 2][0] + mots.last[0] : mots.first[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final teinte = Color(client.apparence.vetement);
    final sombre = Theme.of(context).brightness == Brightness.dark;
    // Couleur du texte : la teinte du client, foncée sur fond clair, éclaircie sur fond sombre.
    final hsl = HSLColor.fromColor(teinte);
    final texte = hsl.withLightness(sombre ? .78 : .32).toColor();
    return CircleAvatar(
      radius: rayon,
      backgroundColor: teinte.withValues(alpha: sombre ? .22 : .18),
      child: Text(initiales(client.nom),
          style: TextStyle(color: texte, fontWeight: FontWeight.w600, fontSize: rayon * .72)),
    );
  }
}

/// Barre fine, dans la couleur donnée.
class Barre extends StatelessWidget {
  const Barre({super.key, required this.part, required this.couleur});

  final double part;
  final Color couleur;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: part.clamp(0, 1),
          minHeight: 6,
          color: couleur,
          backgroundColor: context.couleurs.trait,
        ),
      );
}

/// « Chine » à partir de « Guangzhou, Chine ».
String pays(Conteneur c) => c.origine.split(',').last.trim();

/// Gagné ou perdu, avec la flèche et la couleur qui vont avec.
class Resultat extends StatelessWidget {
  const Resultat(this.montant, {super.key, this.taille = 21});

  final int montant;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final gagne = montant >= 0;
    final couleur = gagne ? context.couleurs.ok : context.couleurs.alerte;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(gagne ? Symbols.arrow_upward : Symbols.arrow_downward, color: couleur, size: taille, weight: 400),
      Text(court(montant.abs()), style: TextStyle(color: couleur, fontSize: taille, fontWeight: FontWeight.w600)),
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
    final muet = context.couleurs.muet;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              CarreConteneur(c),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.numeroCourt, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                  Text('${pays(c)} · ${date(c.arrivee)}', style: TextStyle(color: muet, fontSize: 14.5)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (final p in c.produits)
                      Padding(padding: const EdgeInsets.only(right: 8), child: IconeDeProduit(p.icone, taille: 22)),
                  ]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Resultat(calcul.resultat),
                Text(calcul.resultat >= 0 ? 'Gagné' : 'Perdu', style: TextStyle(color: muet, fontSize: 14)),
              ]),
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right, color: muet),
            ]),
            const SizedBox(height: 14),
            Barre(part: calcul.partVendue, couleur: context.couleurs.conteneur(c.couleur)),
            const SizedBox(height: 6),
            Row(children: [
              Text('Vendu ${pourcent(calcul.partVendue)}', style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(calcul.provisoire ? 'En vente' : 'Tout vendu', style: TextStyle(color: muet, fontSize: 14)),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Une ligne « client » : qui, ce qu'il doit, où il en est.
class LigneClient extends StatelessWidget {
  const LigneClient({
    super.key,
    required this.client,
    required this.doit,
    required this.statut,
    this.dessous,
    this.alerte = false,
    this.onTap,
  });

  final Client client;
  final int doit;
  final StatutPaiement statut;

  /// Une ligne en plus, sous le client, sur toute la largeur (par exemple ses conteneurs).
  final Widget? dessous;

  /// Le client doit plus que sa limite.
  final bool alerte;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AvatarClient(client),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(client.nom, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(client.quartier, style: TextStyle(color: c.muet, fontSize: 14)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (doit > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (alerte) ...[
                    Icon(Symbols.warning, size: 18, color: c.alerte, weight: 400),
                    const SizedBox(width: 4),
                  ],
                  Text(court(doit), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.alerte)),
                ]),
              const SizedBox(height: 4),
              StatutBadge(statut),
            ]),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right, color: c.muet),
            ],
          ]),
          if (dessous != null)
            Padding(padding: const EdgeInsets.only(left: 58, top: 8), child: dessous),
        ]),
      ),
    );
  }
}

/// Petit encadré d'information.
class Note extends StatelessWidget {
  const Note({super.key, required this.icone, required this.texte, this.couleur});

  final IconData icone;
  final String texte;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final teinte = couleur ?? context.couleurs.muet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: teinte.withValues(alpha: .07),
        border: Border.all(color: teinte.withValues(alpha: .3), width: .8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icone, size: 22, color: teinte),
        const SizedBox(width: 10),
        Expanded(child: Text(texte, style: TextStyle(fontSize: 15.5, color: couleur))),
      ]),
    );
  }
}

/// Le gros bouton « + » en bas d'une liste, qui ouvre un formulaire d'ajout.
class BoutonAjouter extends StatelessWidget {
  const BoutonAjouter(this.texte, {super.key, required this.chemin});

  final String texte;
  final String chemin;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: chemin,
        onPressed: () => context.push(chemin),
        icon: const Icon(Symbols.add, weight: 400),
        label: Text(texte, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      );
}

/// Ce qu'affiche une page quand ce qu'elle montrait a été supprimé.
class EcranSupprime extends StatelessWidget {
  const EcranSupprime({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Symbols.delete, size: 48, color: context.couleurs.muet, weight: 200),
            const SizedBox(height: 8),
            Text('Supprimé', style: TextStyle(fontSize: 18, color: context.couleurs.muet)),
          ]),
        ),
      );
}
