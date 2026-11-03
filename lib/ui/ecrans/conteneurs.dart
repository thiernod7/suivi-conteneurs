import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../recherche.dart';
import '../suivi_scope.dart';

enum _Filtre { tous, enVente, toutVendu }

/// Les conteneurs, les plus récents d'abord. On cherche par numéro, pays, fournisseur ou produit.
class EcranConteneurs extends StatefulWidget {
  const EcranConteneurs({super.key});

  @override
  State<EcranConteneurs> createState() => _EcranConteneursState();
}

class _EcranConteneursState extends State<EcranConteneurs> {
  final _controleur = TextEditingController();
  var _recherche = '';
  var _filtre = _Filtre.tous;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  bool _garde(CalculConteneur c, _Filtre f) {
    final ok = switch (f) {
      _Filtre.tous => true,
      _Filtre.enVente => c.provisoire,
      _Filtre.toutVendu => !c.provisoire,
    };
    final k = c.conteneur;
    return ok && correspond([k.numero, k.origine, k.fournisseur, for (final p in k.produits) p.nom], _recherche);
  }

  void _toutVoir() => setState(() {
        _controleur.clear();
        _recherche = '';
        _filtre = _Filtre.tous;
      });

  @override
  Widget build(BuildContext context) {
    final tous = SuiviScope.of(context).conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    final visibles = tous.where((c) => _garde(c, _filtre)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Conteneurs')),
      body: PageContenu(enfants: [
        BarreRecherche<_Filtre>(
          controleur: _controleur,
          indice: 'Numéro, pays ou produit',
          onRecherche: (v) => setState(() => _recherche = v),
          filtres: const [
            Filtre(_Filtre.tous, 'Tous'),
            Filtre(_Filtre.enVente, 'En vente', icone: Symbols.storefront),
            Filtre(_Filtre.toutVendu, 'Tout vendu', icone: Symbols.done_all),
          ],
          titreFiltres: 'Vente',
          iconeFiltres: Symbols.sell,
          filtre: _filtre,
          conteneurs: const [],
          conteneur: null,
          nombre: (f, _) => tous.where((c) => _garde(c, f)).length,
          onAppliquer: (f, _) => setState(() => _filtre = f),
        ),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          AucunResultat(icone: Symbols.package_2, texte: 'Rien', onToutVoir: _toutVoir)
        else
          Grille(largeurMin: 420, enfants: [
            for (final c in visibles) LigneConteneur(c, onTap: () => context.push('/conteneurs/${c.conteneur.id}')),
          ]),
      ]),
    );
  }
}
