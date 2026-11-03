import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/modeles.dart';
import '../composants.dart';
import '../ecrans/facture.dart';
import '../ecrans/factures.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'champs.dart';

class FormulaireRetour extends StatefulWidget {
  const FormulaireRetour({super.key, this.facture});

  /// La facture déjà choisie (quand on vient de sa page).
  final String? facture;

  @override
  State<FormulaireRetour> createState() => _FormulaireRetourState();
}

class _FormulaireRetourState extends State<FormulaireRetour> {
  final _cle = GlobalKey<FormState>();
  late String? _facture = widget.facture;
  int? _ligne;
  final _quantite = TextEditingController();
  final _motif = TextEditingController();
  var _type = TypeAvoir.remisEnStock;
  late var _date = SuiviScope.depot(context).aujourdhui;

  static IconData icone(TypeAvoir t) => switch (t) {
        TypeAvoir.remisEnStock => Symbols.undo,
        TypeAvoir.rebut => Symbols.delete,
        TypeAvoir.remise => Symbols.sell,
      };

  @override
  void dispose() {
    _quantite.dispose();
    _motif.dispose();
    super.dispose();
  }

  void _enregistrer() {
    SuiviScope.depot(context).ajouterAvoir(
      facture: _facture!,
      ligne: _ligne!,
      quantite: lireNombre(_quantite),
      type: _type,
      date: _date,
      motif: _motif.text.trim(),
    );
    annoncer(context, 'Retour enregistré');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final factures = suivi.factures..sort((a, b) => b.facture.date.compareTo(a.facture.date));
    final f = _facture == null ? null : suivi.facture(_facture!);
    final ligne = (f == null || _ligne == null) ? null : f.lignes[_ligne!];
    final produit = ligne == null ? null : suivi.produit(ligne.ligne);
    final montant = ligne == null ? 0 : lireNombre(_quantite) * ligne.ligne.prix;

    return PageFormulaire(
      titre: 'Nouveau retour',
      cle: _cle,
      onEnregistrer: _enregistrer,
      enfants: [
        ChampChoix<String>(
          libelle: 'Facture',
          icone: Symbols.receipt_long,
          valeur: _facture,
          onChanged: (v) => setState(() {
            _facture = v;
            _ligne = null;
          }),
          options: [
            for (final x in factures)
              Option(
                valeur: x.facture.numero,
                titre: suivi.client(x.facture.clientId).client.nom,
                sousTitre: '${numeroCourt(x)} · ${date(x.facture.date)}',
                avant: AvatarClient(suivi.client(x.facture.clientId).client, rayon: 18),
              ),
          ],
        ),
        if (f != null) ...[
          espaceChamp,
          ChampChoix<int>(
            key: ValueKey(_facture),
            libelle: 'Produit',
            icone: Symbols.inventory_2,
            valeur: _ligne,
            vide: 'Rien à rendre',
            onChanged: (v) => setState(() => _ligne = v),
            options: [
              for (final (i, l) in f.lignes.indexed)
                if (l.quantiteGardee > 0)
                  Option(
                    valeur: i,
                    titre: suivi.produit(l.ligne).nom,
                    sousTitre: 'Pris ${nombre(l.quantiteGardee)} ${suivi.produit(l.ligne).unite}',
                    avant: IconeDeProduit(suivi.produit(l.ligne).icone, taille: 30),
                    apres: PuceConteneur(suivi.conteneur(l.ligne.conteneurId).conteneur),
                  ),
            ],
          ),
        ],
        const TitreChamps('Quoi ?', icone: Symbols.help),
        ChoixBoutons<TypeAvoir>(
          options: [for (final t in TypeAvoir.values) (t, EcranFacture.motAvoir(t), Icon(icone(t), size: 18))],
          valeur: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        espaceChamp,
        ChampNombre(
          controleur: _quantite,
          libelle: 'Quantité',
          icone: Symbols.inventory_2,
          suffixe: produit?.unite ?? '',
          maximum: ligne?.quantiteGardee,
          messageMaximum: 'Il en a pris ${nombre(ligne?.quantiteGardee ?? 0)}',
          onChanged: (_) => setState(() {}),
        ),
        if (montant > 0) ...[
          espaceChamp,
          Card(
            child: LigneChiffre(icone: Symbols.undo, mot: 'Retours', montant: '− ${court(montant)}', couleur: c.attention),
          ),
        ],
        espaceChamp,
        ChampTexte(controleur: _motif, libelle: 'Pourquoi ?', indice: 'Sacs mouillés', icone: Symbols.edit_note),
        espaceChamp,
        ChampDate(valeur: _date, onChanged: (d) => setState(() => _date = d)),
      ],
    );
  }
}
