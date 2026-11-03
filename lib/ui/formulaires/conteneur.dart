import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/modeles.dart';
import '../composants.dart';
import '../format.dart';
import '../suivi_scope.dart';
import 'champs.dart';

class FormulaireConteneur extends StatefulWidget {
  const FormulaireConteneur({super.key, this.id});

  /// Le conteneur à modifier, ou null pour un nouveau conteneur.
  final String? id;

  @override
  State<FormulaireConteneur> createState() => _FormulaireConteneurState();
}

class _FormulaireConteneurState extends State<FormulaireConteneur> {
  final _cle = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _origine = TextEditingController();
  final _fournisseur = TextEditingController();
  final _achat = TextEditingController();
  final _fret = TextEditingController();
  final _douane = TextEditingController();
  final _transport = TextEditingController();
  final _verse = TextEditingController();
  var _type = TypeConteneur.hc40;
  var _statut = StatutConteneur.enDistribution;
  late var _arrivee = SuiviScope.depot(context).aujourdhui;
  var _pret = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret || widget.id == null) return;
    _pret = true;
    final c = SuiviScope.of(context).conteneur(widget.id!).conteneur;
    _numero.text = c.numero;
    _origine.text = c.origine;
    _fournisseur.text = c.fournisseur;
    ecrireNombre(_achat, c.couts.achat);
    ecrireNombre(_fret, c.couts.fret);
    ecrireNombre(_douane, c.couts.douane);
    ecrireNombre(_transport, c.couts.manutention);
    ecrireNombre(_verse, c.verseFournisseur);
    _type = c.type;
    _statut = c.statut;
    _arrivee = c.arrivee;
  }

  List<TextEditingController> get _tous => [
    _numero,
    _origine,
    _fournisseur,
    _achat,
    _fret,
    _douane,
    _transport,
    _verse,
  ];

  @override
  void dispose() {
    for (final c in _tous) {
      c.dispose();
    }
    super.dispose();
  }

  /// « mdnu4821130 » devient « MDNU 482113 0 ».
  static String normaliser(String s) {
    final brut = s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (brut.length != 11) return s.toUpperCase().trim();
    return '${brut.substring(0, 4)} ${brut.substring(4, 10)} ${brut.substring(10)}';
  }

  int get _total => lireNombre(_achat) + lireNombre(_fret) + lireNombre(_douane) + lireNombre(_transport);

  Couts get _couts => Couts(
    achat: lireNombre(_achat),
    fret: lireNombre(_fret),
    douane: lireNombre(_douane),
    manutention: lireNombre(_transport),
  );

  void _enregistrer() {
    final numero = normaliser(_numero.text);
    if (widget.id != null) {
      SuiviScope.depot(context).modifierConteneur(
        widget.id!,
        numero: numero,
        type: _type,
        origine: _origine.text.trim(),
        arrivee: _arrivee,
        fournisseur: _fournisseur.text.trim(),
        verseFournisseur: lireNombre(_verse),
        couts: _couts,
        statut: _statut,
      );
      annoncer(context, 'Modifié');
      context.pop();
      return;
    }
    final id = SuiviScope.depot(context).ajouterConteneur(
      numero: numero,
      type: _type,
      origine: _origine.text.trim(),
      arrivee: _arrivee,
      fournisseur: _fournisseur.text.trim(),
      verseFournisseur: lireNombre(_verse),
      couts: _couts,
    );
    annoncer(context, 'Conteneur ${numero.substring(5, 11)} ajouté');
    context.go('/conteneurs/$id');
  }

  @override
  Widget build(BuildContext context) {
    final depot = SuiviScope.depot(context);
    return PageFormulaire(
      titre: widget.id == null ? 'Nouveau conteneur' : 'Modifier le conteneur',
      supprimer: widget.id == null
          ? null
          : Suppression(
              texte: 'Supprimer ce conteneur',
              message: 'Le conteneur et ses produits seront effacés.',
              raisonImpossible: depot.raisonGarderConteneur(widget.id!),
              onSupprimer: () {
                context.go('/conteneurs');
                depot.supprimerConteneur(widget.id!);
                annoncer(context, 'Conteneur supprimé');
              },
            ),
      cle: _cle,
      onEnregistrer: _enregistrer,
      enfants: [
        ChampTexte(
          controleur: _numero,
          libelle: 'Numéro',
          indice: 'MDNU 482113 0',
          icone: Symbols.tag,
          majuscules: true,
          validateur: (v) {
            final n = normaliser(v ?? '');
            if (!RegExp(r'^[A-Z]{4} \d{6} \d$').hasMatch(n)) return '4 lettres et 7 chiffres';
            final pris = widget.id == null
                ? depot.numeroConteneurPris(n)
                : depot.numeroConteneurPrisAilleurs(n, widget.id!);
            if (pris) return 'Déjà enregistré';
            return null;
          },
        ),
        const TitreChamps('Taille', icone: Symbols.straighten),
        ChoixBoutons<TypeConteneur>(
          options: [for (final t in TypeConteneur.values) (t, t.libelle, null)],
          valeur: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        if (widget.id != null) ...[
          const TitreChamps('Vente', icone: Symbols.sell),
          ChoixBoutons<StatutConteneur>(
            options: const [
              (StatutConteneur.enDistribution, 'En vente', Icon(Symbols.storefront, size: 18)),
              (StatutConteneur.vendu, 'Tout vendu', Icon(Symbols.done_all, size: 18)),
            ],
            valeur: _statut,
            onChanged: (s) => setState(() => _statut = s),
          ),
        ],
        espaceChamp,
        ChampTexte(controleur: _origine, libelle: 'Pays', indice: 'Guangzhou, Chine', icone: Symbols.public),
        espaceChamp,
        ChampDate(libelle: 'Arrivé le', valeur: _arrivee, onChanged: (d) => setState(() => _arrivee = d)),
        espaceChamp,
        ChampTexte(controleur: _fournisseur, libelle: 'Fournisseur', icone: Symbols.local_shipping),
        const TitreChamps('Dépensé', icone: Symbols.shopping_cart),
        ChampNombre(
          controleur: _achat,
          libelle: 'Achat',
          icone: Symbols.shopping_cart,
          onChanged: (_) => setState(() {}),
        ),
        espaceChamp,
        ChampNombre(
          requis: false,
          controleur: _fret,
          libelle: 'Bateau (fret)',
          icone: Symbols.directions_boat,
          minimum: 0,
          onChanged: (_) => setState(() {}),
        ),
        espaceChamp,
        ChampNombre(
          requis: false,
          controleur: _douane,
          libelle: 'Douane',
          icone: Symbols.account_balance,
          minimum: 0,
          onChanged: (_) => setState(() {}),
        ),
        espaceChamp,
        ChampNombre(
          requis: false,
          controleur: _transport,
          libelle: 'Transport',
          icone: Symbols.local_shipping,
          minimum: 0,
          onChanged: (_) => setState(() {}),
        ),
        espaceChamp,
        Card(
          child: LigneChiffre(icone: Symbols.shopping_cart, mot: 'Total dépensé', montant: court(_total)),
        ),
        espaceChamp,
        ChampNombre(
          controleur: _verse,
          libelle: 'Déjà payé au fournisseur',
          icone: Symbols.payments,
          minimum: 0,
          requis: false,
          maximum: lireNombre(_achat),
          messageMaximum: 'Plus que l\'achat',
        ),
      ],
    );
  }
}
