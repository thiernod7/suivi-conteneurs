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
  const FormulaireProduit({super.key, this.conteneurId});

  /// Le conteneur déjà choisi (quand on vient de sa page).
  final String? conteneurId;

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
    final conteneurs = suivi.conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    return PageFormulaire(
      titre: 'Nouveau produit',
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
          builder: (etat) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
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
            ]),
            if (etat.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(etat.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.5)),
              ),
          ]),
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
        ChampNombre(controleur: _quantite, libelle: 'Quantité reçue', icone: Symbols.inventory_2, suffixe: _unite),
        espaceChamp,
        ChampNombre(controleur: _prix, libelle: 'Prix pour 1 ${_unite.substring(0, _unite.length - 1)}', icone: Symbols.sell),
      ],
    );
  }
}
