import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../../domaine/modeles.dart';
import '../composants.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../recherche.dart';
import '../suivi_scope.dart';
import '../theme.dart';

enum _Filtre { tous, enStock, toutVendu }

/// Tous les produits de tous les conteneurs : reçu, vendu, reste, prix.
class EcranProduits extends StatefulWidget {
  const EcranProduits({super.key});

  @override
  State<EcranProduits> createState() => _EcranProduitsState();
}

class _EcranProduitsState extends State<EcranProduits> {
  final _controleur = TextEditingController();
  var _recherche = '';
  var _filtre = _Filtre.tous;
  String? _conteneur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  bool _garde((Conteneur, CalculProduit) x, _Filtre f, String? conteneur) {
    final (k, p) = x;
    final ok = switch (f) {
      _Filtre.tous => true,
      _Filtre.enStock => p.stock > 0,
      _Filtre.toutVendu => p.stock == 0,
    };
    return ok && (conteneur == null || k.id == conteneur) && correspond([p.produit.nom, k.numero], _recherche);
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final conteneurs = suivi.conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    final tous = [for (final k in conteneurs) for (final p in k.produits) (k.conteneur, p)];
    final visibles = tous.where((x) => _garde(x, _filtre, _conteneur)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Produits')),
      floatingActionButton: const BoutonAjouter('Nouveau produit', chemin: '/nouveau/produit'),
      body: PageContenu(enfants: [
        BarreRecherche<_Filtre>(
          controleur: _controleur,
          indice: 'Produit ou conteneur',
          onRecherche: (v) => setState(() => _recherche = v),
          titreFiltres: 'Stock',
          iconeFiltres: Symbols.inventory_2,
          filtres: const [
            Filtre(_Filtre.tous, 'Tous'),
            Filtre(_Filtre.enStock, 'En stock', icone: Symbols.inventory_2),
            Filtre(_Filtre.toutVendu, 'Tout vendu', icone: Symbols.done_all),
          ],
          filtre: _filtre,
          conteneurs: [for (final k in conteneurs) k.conteneur],
          conteneur: _conteneur,
          nombre: (f, id) => tous.where((x) => _garde(x, f, id)).length,
          onAppliquer: (f, id) => setState(() {
            _filtre = f;
            _conteneur = id;
          }),
        ),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          AucunResultat(
            icone: Symbols.inventory_2,
            texte: 'Rien',
            onToutVoir: () => setState(() {
              _controleur.clear();
              _recherche = '';
              _filtre = _Filtre.tous;
              _conteneur = null;
            }),
          )
        else
          CarteListe(lignes: [
            for (final (k, p) in visibles)
              InkWell(
                onTap: () => context.push('/conteneurs/${k.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    IconeDeProduit(p.produit.icone, taille: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.produit.nom, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Wrap(spacing: 12, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          PuceConteneur(k),
                          Text('${court(p.produit.prix)} / ${p.produit.unite.substring(0, p.produit.unite.length - 1)}',
                              style: TextStyle(color: c.muet, fontSize: 13.5)),
                        ]),
                        const SizedBox(height: 8),
                        Barre(
                          part: p.produit.quantiteRecue == 0 ? 0 : p.vendu / p.produit.quantiteRecue,
                          couleur: c.conteneur(k.couleur),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Reste', style: TextStyle(color: c.muet, fontSize: 13.5)),
                      Text(nombre(p.stock), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(p.produit.unite, style: TextStyle(color: c.muet, fontSize: 13.5)),
                    ]),
                  ]),
                ),
              ),
          ]),
      ]),
    );
  }
}
