import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/modeles.dart';
import '../composants.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import 'champs.dart';

class FormulaireProduit extends StatefulWidget {
  const FormulaireProduit({super.key, this.conteneurId, this.produitId});

  /// Le conteneur déjà choisi (quand on vient de sa page).
  final String? conteneurId;

  /// Le produit à modifier, ou null pour un nouveau produit.
  final String? produitId;

  @override
  State<FormulaireProduit> createState() => _FormulaireProduitState();
}

class _FormulaireProduitState extends State<FormulaireProduit> {
  final _cle = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _quantite = TextEditingController();
  final _prix = TextEditingController();
  late String? _conteneur = widget.conteneurId;
  IconeProduit? _icone;
  var _unite = 'sacs';
  var _pret = false;

  bool get _modification => widget.produitId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret || !_modification) return;
    _pret = true;
    final p = SuiviScope.of(context)
        .conteneur(widget.conteneurId!)
        .conteneur
        .produits
        .firstWhere((p) => p.id == widget.produitId);
    _nom.text = p.nom;
    _icone = p.icone;
    _unite = p.unite;
    ecrireNombre(_quantite, p.quantiteRecue);
    ecrireNombre(_prix, p.prix);
  }

  static const unites = ['sacs', 'bidons', 'cartons', 'pièces'];

  /// Nom proposé pour chaque image.
  static const noms = {
    IconeProduit.sac: 'Riz',
    IconeProduit.sucre: 'Sucre',
    IconeProduit.bidon: 'Huile',
    IconeProduit.carton: 'Pâtes',
    IconeProduit.tomate: 'Tomate concentrée',
    IconeProduit.lait: 'Lait en poudre',
    IconeProduit.pneu: 'Pneus',
    IconeProduit.batterie: 'Batteries',
  };

  @override
  void dispose() {
    for (final c in [_nom, _quantite, _prix]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enregistrer() {
    if (_modification) {
      SuiviScope.depot(context).modifierProduit(
        widget.conteneurId!,
        widget.produitId!,
        nom: _nom.text.trim(),
        unite: _unite,
        quantite: lireNombre(_quantite),
        prix: lireNombre(_prix),
        icone: _icone!,
      );
      annoncer(context, 'Modifié');
      context.pop();
      return;
    }
    SuiviScope.depot(context).ajouterProduit(
      _conteneur!,
      nom: _nom.text.trim(),
      unite: _unite,
      quantite: lireNombre(_quantite),
      prix: lireNombre(_prix),
      icone: _icone!,
    );
    annoncer(context, '${_nom.text.trim()} ajouté');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final conteneurs = [
      for (final c in suivi.conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee)))
        // En modification, le produit reste dans son conteneur.
        if (!_modification || c.conteneur.id == widget.conteneurId) c,
    ];
    final calcul = !_modification
        ? null
        : suivi
              .conteneurOuNull(widget.conteneurId!)
              ?.produits
              .where((p) => p.produit.id == widget.produitId)
              .firstOrNull;
    final dejaSorti = calcul == null ? 0 : calcul.vendu + calcul.rebut;
    final depot = SuiviScope.depot(context);
    return PageFormulaire(
      titre: _modification ? 'Modifier le produit' : 'Nouveau produit',
      supprimer: !_modification
          ? null
          : Suppression(
              texte: 'Supprimer ce produit',
              message: '${_nom.text} sera effacé du conteneur.',
              raisonImpossible: depot.raisonGarderProduit(widget.produitId!),
              onSupprimer: () {
                context.pop();
                depot.supprimerProduit(widget.conteneurId!, widget.produitId!);
                annoncer(context, 'Produit supprimé');
              },
            ),
      cle: _cle,
      onEnregistrer: _enregistrer,
      enfants: [
        ChampChoix<String>(
          libelle: 'Conteneur',
          icone: Symbols.package_2,
          valeur: _conteneur,
          onChanged: (v) => setState(() => _conteneur = v),
          options: [
            for (final c in conteneurs)
              Option(
                valeur: c.conteneur.id,
                titre: c.conteneur.numeroCourt,
                sousTitre: '${pays(c.conteneur)} · ${date(c.conteneur.arrivee)}',
                avant: CarreConteneur(c.conteneur, taille: 36),
              ),
          ],
        ),
        const TitreChamps('Image', icone: Symbols.image),
        FormField<IconeProduit>(
          validator: (_) => _icone == null ? 'Choisir une image' : null,
          builder: (etat) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final i in IconeProduit.values)
                    ChoiceChip(
                      padding: const EdgeInsets.all(8),
                      label: IconeDeProduit(i, taille: 34),
                      tooltip: noms[i],
                      selected: _icone == i,
                      onSelected: (_) {
                        setState(() {
                          _icone = i;
                          if (_nom.text.trim().isEmpty) _nom.text = noms[i]!;
                        });
                        etat.didChange(i);
                      },
                    ),
                ],
              ),
              if (etat.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    etat.errorText!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.5),
                  ),
                ),
            ],
          ),
        ),
        espaceChamp,
        ChampTexte(controleur: _nom, libelle: 'Nom', indice: 'Riz parfumé 25 kg', icone: Symbols.label),
        const TitreChamps('Unité', icone: Symbols.inventory_2),
        ChoixBoutons<String>(
          options: [for (final u in unites) (u, u, null)],
          valeur: _unite,
          onChanged: (u) => setState(() => _unite = u),
        ),
        espaceChamp,
        ChampNombre(
          controleur: _quantite,
          libelle: 'Quantité reçue',
          icone: Symbols.inventory_2,
          suffixe: _unite,
          minimum: dejaSorti > 0 ? dejaSorti : 1,
          messageMinimum: dejaSorti > 0 ? 'Déjà vendu ${nombre(dejaSorti)}' : null,
        ),
        espaceChamp,
        ChampNombre(
          controleur: _prix,
          libelle: 'Prix pour 1 ${_unite.substring(0, _unite.length - 1)}',
          icone: Symbols.sell,
        ),
      ],
    );
  }
}
