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
      padding: EdgeInsets.fromLTRB(marge, marge, marge, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: enfants),
        ),
      ),
    );
  }
}

/// Petit texte en capitales au-dessus d'une valeur.
class Etiquette extends StatelessWidget {
  const Etiquette(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Text(
        texte.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {super.key, this.detail});

  final String titre;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(titre.toUpperCase(), style: Theme.of(context).textTheme.headlineSmall),
            if (detail != null)
              Text(detail!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

/// Pastille arrondie : statut de paiement ou de conteneur.
class Pastille extends StatelessWidget {
  const Pastille(this.texte, {super.key, required this.couleur, required this.fond});

  Pastille.paiement(StatutPaiement s, BuildContext context, {Key? key})
      : this(s.libelle, key: key, couleur: context.couleurs.statut(s), fond: context.couleurs.statutFond(s));

  final String texte;
  final Color couleur;
  final Color fond;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(99)),
        child: Text(texte, style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// Un chiffre clé : étiquette, valeur en grand, précision en petit.
class Indicateur extends StatelessWidget {
  const Indicateur({super.key, required this.etiquette, required this.valeur, this.detail, this.couleur});

  final String etiquette;
  final String valeur;
  final String? detail;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Etiquette(etiquette),
              const SizedBox(height: 4),
              Text(
                valeur,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontSize: 30, color: couleur, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      );
}

/// Grille qui s'adapte à la largeur : [largeurMin] par élément, au moins [colonnesMin] colonnes.
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
        // La dernière ligne, si elle est incomplète, se partage toute la largeur.
        final derniers = enfants.length % colonnes;
        return Wrap(
          spacing: espace,
          runSpacing: espace,
          children: [
            for (var i = 0; i < enfants.length; i++)
              SizedBox(
                width: derniers > 0 && i >= enfants.length - derniers ? largeur(derniers) : largeur(colonnes),
                child: enfants[i],
              ),
          ],
        );
      });
}

class NumeroConteneur extends StatelessWidget {
  const NumeroConteneur(this.conteneur, {super.key, this.taille = 15});

  final Conteneur conteneur;
  final double taille;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 14, color: context.couleurs.conteneur(conteneur.couleur)),
          const SizedBox(width: 8),
          Text(conteneur.numero, style: TextStyle(fontFamily: policeNumero, fontSize: taille, fontWeight: FontWeight.w500)),
        ],
      );
}

/// Carte d'un conteneur : d'où il vient, ce qu'il contient, où en est la vente et son résultat.
class CarteConteneur extends StatelessWidget {
  const CarteConteneur(this.calcul, {super.key});

  final CalculConteneur calcul;

  @override
  Widget build(BuildContext context) {
    final c = calcul.conteneur;
    final couleur = context.couleurs.conteneur(c.couleur);
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    final gain = calcul.resultat >= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 8, color: couleur),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(c.numero,
                            style: const TextStyle(fontFamily: policeNumero, fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      c.statut == StatutConteneur.vendu
                          ? Pastille(c.statut.libelle, couleur: context.couleurs.ok, fond: context.couleurs.okFond)
                          : Pastille(c.statut.libelle,
                              couleur: context.couleurs.attention, fond: context.couleurs.attentionFond),
                    ]),
                    const SizedBox(height: 2),
                    Text('${c.type.libelle} · ${c.origine} · arrivé le ${date(c.arrivee)}',
                        style: TextStyle(fontSize: 13, color: muet)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      for (final p in c.produits)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          IconeDeProduit(p.icone, taille: 22),
                          const SizedBox(width: 6),
                          Text('${nombre(p.quantiteRecue)} ${p.unite}', style: const TextStyle(fontSize: 13)),
                        ]),
                    ]),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: calcul.partVendue,
                        minHeight: 7,
                        color: couleur,
                        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vendu ${pourcent(calcul.partVendue)} · encaissé ${calcul.ventes == 0 ? '0 %' : pourcent(calcul.encaisse / calcul.ventes)} des ventes',
                      style: TextStyle(fontSize: 12.5, color: muet),
                    ),
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Etiquette(gain ? 'Bénéfice' : 'Perte'),
                        Text(
                          '${signe(calcul.resultat)} GNF',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: gain ? context.couleurs.ok : context.couleurs.alerte,
                              fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ]),
                      const SizedBox(width: 10),
                      if (calcul.provisoire)
                        Expanded(
                          child: Text(
                            'provisoire · prévu ${signe(calcul.resultatPrevu)} si tout est vendu',
                            style: TextStyle(fontSize: 12.5, color: muet),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
