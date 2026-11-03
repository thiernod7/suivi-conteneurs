import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../../domaine/modeles.dart';
import '../composants.dart';
import '../ecrans/facture.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'champs.dart';

/// Une ligne de la facture en cours : un produit d'un conteneur, une quantité, un prix.
class _Ligne {
  String? choix; // « conteneurId|produitId »
  final quantite = TextEditingController();
  final prix = TextEditingController();

  String? get conteneurId => choix?.split('|').first;
  String? get produitId => choix?.split('|').last;
  int get montant => lireNombre(quantite) * lireNombre(prix);

  void dispose() {
    quantite.dispose();
    prix.dispose();
  }
}

class FormulaireFacture extends StatefulWidget {
  const FormulaireFacture({super.key, this.clientId});

  /// Le client déjà choisi (quand on vient de sa page).
  final String? clientId;

  @override
  State<FormulaireFacture> createState() => _FormulaireFactureState();
}

class _FormulaireFactureState extends State<FormulaireFacture> {
  final _cle = GlobalKey<FormState>();
  late String? _client = widget.clientId;
  late var _date = SuiviScope.depot(context).aujourdhui;
  final _lignes = [_Ligne()];
  final _paye = TextEditingController();
  var _mode = ModePaiement.especes;

  @override
  void dispose() {
    for (final l in _lignes) {
      l.dispose();
    }
    _paye.dispose();
    super.dispose();
  }

  int get _total => _lignes.fold(0, (s, l) => s + l.montant);

  /// Ce qui reste d'un produit, moins ce qui est déjà pris par les autres lignes de cette facture.
  int _disponible(Suivi suivi, _Ligne ligne) {
    if (ligne.choix == null) return 0;
    final p = suivi.conteneur(ligne.conteneurId!).produits.firstWhere((p) => p.produit.id == ligne.produitId);
    final ailleurs = _lignes.where((l) => l != ligne && l.choix == ligne.choix).fold(0, (s, l) => s + lireNombre(l.quantite));
    return p.stock - ailleurs;
  }

  void _enregistrer() {
    final numero = SuiviScope.depot(context).ajouterFacture(
      clientId: _client!,
      date: _date,
      lignes: [
        for (final l in _lignes)
          LigneFacture(conteneurId: l.conteneurId!, produitId: l.produitId!, quantite: lireNombre(l.quantite), prix: lireNombre(l.prix)),
      ],
      payeMaintenant: lireNombre(_paye),
      mode: _mode,
    );
    annoncer(context, 'Facture ${numero.replaceFirst('FAC-', '')} enregistrée');
    context.go('/factures/$numero');
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final clients = suivi.clients..sort((a, b) => a.client.nom.compareTo(b.client.nom));
    final conteneurs = suivi.conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    final produits = [
      for (final k in conteneurs)
        for (final p in k.produits)
          if (p.stock > 0) (k.conteneur, p),
    ];

    return PageFormulaire(
      titre: 'Nouvelle facture',
      cle: _cle,
      onEnregistrer: _enregistrer,
      enfants: [
        ChampChoix<String>(
          libelle: 'Client',
          icone: Symbols.person,
          valeur: _client,
          onChanged: (v) => setState(() => _client = v),
          options: [
            for (final k in clients)
              Option(
                valeur: k.client.id,
                titre: k.client.nom,
                sousTitre: k.client.quartier,
                avant: AvatarClient(k.client, rayon: 18),
                apres: k.doit > 0
                    ? Text(court(k.doit), style: TextStyle(color: c.alerte, fontWeight: FontWeight.w600))
                    : null,
              ),
          ],
        ),
        espaceChamp,
        ChampDate(valeur: _date, onChanged: (d) => setState(() => _date = d)),
        const TitreChamps('Ce qu\'il prend', icone: Symbols.shopping_bag),
        for (final (i, ligne) in _lignes.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _carteLigne(suivi, ligne, produits),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => setState(() => _lignes.add(_Ligne())),
          icon: const Icon(Symbols.add),
          label: const Text('Ajouter un produit'),
        ),
        espaceChamp,
        Card(child: LigneChiffre(icone: Symbols.receipt_long, mot: 'Montant', montant: court(_total))),
        const TitreChamps('Payé maintenant', icone: Symbols.payments),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _paye.clear()),
              child: const Text('Rien'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => ecrireNombre(_paye, _total)),
              child: const Text('Tout'),
            ),
          ),
        ]),
        espaceChamp,
        ChampNombre(
          controleur: _paye,
          libelle: 'Reçu',
          icone: Symbols.payments,
          requis: false,
          minimum: 0,
          maximum: _total,
          messageMaximum: 'Plus que le montant',
          onChanged: (_) => setState(() {}),
        ),
        if (lireNombre(_paye) > 0) ...[
          const TitreChamps('Comment ?', icone: Symbols.wallet),
          ChoixBoutons<ModePaiement>(
            options: [for (final m in ModePaiement.values) (m, m.libelle, Icon(EcranFacture.iconeMode(m), size: 18))],
            valeur: _mode,
            onChanged: (m) => setState(() => _mode = m),
          ),
        ],
      ],
    );
  }

  Widget _carteLigne(Suivi suivi, _Ligne ligne, List<(Conteneur, CalculProduit)> produits) {
    final dispo = _disponible(suivi, ligne);
    final produit = ligne.choix == null ? null : produits.where((x) => '${x.$1.id}|${x.$2.produit.id}' == ligne.choix).firstOrNull;
    final unite = produit?.$2.produit.unite ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChampChoix<String>(
            libelle: 'Produit',
            icone: Symbols.inventory_2,
            valeur: ligne.choix,
            vide: 'Plus rien en stock',
            onChanged: (v) => setState(() {
              ligne.choix = v;
              final p = produits.firstWhere((x) => '${x.$1.id}|${x.$2.produit.id}' == v).$2.produit;
              ecrireNombre(ligne.prix, p.prix);
            }),
            options: [
              for (final (k, p) in produits)
                Option(
                  valeur: '${k.id}|${p.produit.id}',
                  titre: p.produit.nom,
                  sousTitre: 'Reste ${nombre(p.stock)} ${p.produit.unite}',
                  avant: IconeDeProduit(p.produit.icone, taille: 30),
                  apres: PuceConteneur(k),
                  recherche: [k.numero],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: ChampNombre(
                controleur: ligne.quantite,
                libelle: 'Quantité',
                icone: Symbols.inventory_2,
                suffixe: unite,
                maximum: ligne.choix == null ? null : dispo,
                messageMaximum: 'Il reste ${nombre(dispo)}',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChampNombre(
                controleur: ligne.prix,
                libelle: 'Prix pour 1',
                icone: Symbols.sell,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (_lignes.length > 1)
              TextButton.icon(
                onPressed: () => setState(() {
                  _lignes.remove(ligne);
                  ligne.dispose();
                }),
                icon: const Icon(Symbols.delete),
                label: const Text('Enlever'),
              ),
            const Spacer(),
            Text(court(ligne.montant), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(' GNF', style: TextStyle(fontSize: 13, color: context.couleurs.muet)),
          ]),
        ]),
      ),
    );
  }
}
