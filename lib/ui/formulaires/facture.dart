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
  const FormulaireFacture({super.key, this.clientId, this.numero});

  /// La facture à modifier, ou null pour une nouvelle facture.
  final String? numero;

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
  var _pret = false;

  /// En modification : ce que la facture prenait déjà, par produit (c'est déjà sorti du stock).
  final _avant = <String, int>{};

  bool get _modification => widget.numero != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret || !_modification) return;
    _pret = true;
    final f = SuiviScope.of(context).facture(widget.numero!).facture;
    _client = f.clientId;
    _date = f.date;
    for (final l in _lignes) {
      l.dispose();
    }
    _lignes
      ..clear()
      ..addAll([
        for (final l in f.lignes)
          _Ligne()
            ..choix = '${l.conteneurId}|${l.produitId}'
            ..quantite.text = nombre(l.quantite)
            ..prix.text = nombre(l.prix),
      ]);
    for (final l in f.lignes) {
      _avant.update('${l.conteneurId}|${l.produitId}', (q) => q + l.quantite, ifAbsent: () => l.quantite);
    }
  }

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
    final ailleurs = _lignes
        .where((l) => l != ligne && l.choix == ligne.choix)
        .fold(0, (s, l) => s + lireNombre(l.quantite));
    return p.stock + (_avant[ligne.choix] ?? 0) - ailleurs;
  }

  List<LigneFacture> get _lignesFacture => [
    for (final l in _lignes)
      LigneFacture(
        conteneurId: l.conteneurId!,
        produitId: l.produitId!,
        quantite: lireNombre(l.quantite),
        prix: lireNombre(l.prix),
      ),
  ];

  void _enregistrer() {
    final depot = SuiviScope.depot(context);
    if (_modification) {
      final deja = depot.suivi.facture(widget.numero!).paye;
      if (_total < deja) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Déjà reçu ${court(deja)} GNF : le montant ne peut pas être plus petit.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      depot.modifierFacture(widget.numero!, clientId: _client!, date: _date, lignes: _lignesFacture);
      annoncer(context, 'Modifié');
      context.pop();
      return;
    }
    final numero = depot.ajouterFacture(
      clientId: _client!,
      date: _date,
      lignes: _lignesFacture,
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
          if (p.stock > 0 || _avant.containsKey('${k.conteneur.id}|${p.produit.id}')) (k.conteneur, p),
    ];
    final depot = SuiviScope.depot(context);
    final bloquees = _modification && depot.lignesBloquees(widget.numero!);
    final dejaRecu = _modification ? (suivi.factureOuNull(widget.numero!)?.paye ?? 0) : 0;

    return PageFormulaire(
      titre: _modification ? 'Modifier la facture' : 'Nouvelle facture',
      supprimer: !_modification
          ? null
          : Suppression(
              texte: 'Supprimer cette facture',
              message: 'Ses paiements et ses retours seront effacés aussi. Ce qui avait été pris revient dans les conteneurs.',
              onSupprimer: () {
                context.go('/factures');
                depot.supprimerFacture(widget.numero!);
                annoncer(context, 'Facture supprimée');
              },
            ),
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
                    ? Text(
                        court(k.doit),
                        style: TextStyle(color: c.alerte, fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
          ],
        ),
        espaceChamp,
        ChampDate(valeur: _date, onChanged: (d) => setState(() => _date = d)),
        const TitreChamps('Ce qu\'il prend', icone: Symbols.shopping_bag),
        if (bloquees) ...[
          const Note(icone: Symbols.lock, texte: 'Cette facture a des retours : ses produits ne changent plus.'),
          const SizedBox(height: 12),
          CarteListe(
            lignes: [
              for (final l in _lignes)
                Builder(
                  builder: (context) {
                    final x = produits.firstWhere((x) => '${x.$1.id}|${x.$2.produit.id}' == l.choix);
                    return ListTile(
                      leading: IconeDeProduit(x.$2.produit.icone, taille: 30),
                      title: Text(x.$2.produit.nom),
                      subtitle: Text('${l.quantite.text} ${x.$2.produit.unite} × ${l.prix.text}'),
                      trailing: PuceConteneur(x.$1),
                    );
                  },
                ),
            ],
          ),
        ] else ...[
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
        ],
        espaceChamp,
        Card(
          child: LigneChiffre(icone: Symbols.receipt_long, mot: 'Montant', montant: court(_total)),
        ),
        if (!_modification) ...[
          const TitreChamps('Payé maintenant', icone: Symbols.payments),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => setState(() => _paye.clear()), child: const Text('Rien')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => ecrireNombre(_paye, _total)),
                  child: const Text('Tout'),
                ),
              ),
            ],
          ),
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
        ] else if (dejaRecu > 0) ...[
          const SizedBox(height: 12),
          Card(
            child: LigneChiffre(icone: Symbols.payments, mot: 'Déjà reçu', montant: court(dejaRecu), couleur: c.ok),
          ),
        ],
      ],
    );
  }

  Widget _carteLigne(Suivi suivi, _Ligne ligne, List<(Conteneur, CalculProduit)> produits) {
    final dispo = _disponible(suivi, ligne);
    final produit = ligne.choix == null
        ? null
        : produits.where((x) => '${x.$1.id}|${x.$2.produit.id}' == ligne.choix).firstOrNull;
    final unite = produit?.$2.produit.unite ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
