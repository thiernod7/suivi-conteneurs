import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/modeles.dart';
import '../composants.dart';
import '../ecrans/facture.dart';
import '../ecrans/factures.dart';
import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'champs.dart';

class FormulairePaiement extends StatefulWidget {
  const FormulairePaiement({super.key, this.facture, this.rang});

  /// Le rang du paiement à modifier, ou null pour un nouveau paiement.
  final int? rang;

  /// La facture déjà choisie (quand on vient de sa page).
  final String? facture;

  @override
  State<FormulairePaiement> createState() => _FormulairePaiementState();
}

class _FormulairePaiementState extends State<FormulairePaiement> {
  final _cle = GlobalKey<FormState>();
  late String? _facture = widget.facture;
  final _montant = TextEditingController();
  final _remarque = TextEditingController();
  var _mode = ModePaiement.especes;
  late var _date = SuiviScope.depot(context).aujourdhui;
  var _pret = false;

  /// En modification : la facture et le montant d'avant (il compte déjà dans ce qui a été payé).
  String? _factureAvant;
  var _avant = 0;

  bool get _modification => widget.rang != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret || !_modification) return;
    _pret = true;
    final p = SuiviScope.depot(context).donnees.paiements[widget.rang!];
    _facture = _factureAvant = p.facture;
    _avant = p.montant;
    ecrireNombre(_montant, p.montant);
    _mode = p.mode;
    _date = p.date;
    _remarque.text = p.remarque ?? '';
  }

  @override
  void dispose() {
    _montant.dispose();
    _remarque.dispose();
    super.dispose();
  }

  void _enregistrer() {
    final montant = lireNombre(_montant);
    final paiement = Paiement(
      facture: _facture!,
      date: _date,
      montant: montant,
      mode: _mode,
      remarque: _remarque.text.trim().isEmpty ? null : _remarque.text.trim(),
    );
    if (_modification) {
      SuiviScope.depot(context).modifierPaiement(widget.rang!, paiement);
      annoncer(context, 'Modifié');
    } else {
      SuiviScope.depot(context).ajouterPaiement(paiement);
      annoncer(context, '${court(montant)} GNF reçus');
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final aPayer = suivi.factures.where((f) => f.solde > 0 || f.facture.numero == _facture).toList()
      ..sort((a, b) => a.facture.date.compareTo(b.facture.date));
    // En modification, l'ancien montant de ce paiement est de nouveau « à payer ».
    final solde = _facture == null
        ? 0
        : (suivi.factureOuNull(_facture!)?.solde ?? 0) + (_facture == _factureAvant ? _avant : 0);
    final depot = SuiviScope.depot(context);

    return PageFormulaire(
      titre: _modification ? 'Modifier le paiement' : 'Nouveau paiement',
      supprimer: !_modification
          ? null
          : Suppression(
              texte: 'Supprimer ce paiement',
              message: '${court(_avant)} GNF ne seront plus comptés comme reçus.',
              onSupprimer: () {
                context.pop();
                depot.supprimerPaiement(widget.rang!);
                annoncer(context, 'Paiement supprimé');
              },
            ),
      cle: _cle,
      onEnregistrer: _enregistrer,
      enfants: [
        ChampChoix<String>(
          libelle: 'Facture',
          icone: Symbols.receipt_long,
          valeur: _facture,
          vide: 'Tout est payé',
          onChanged: (v) => setState(() => _facture = v),
          options: [
            for (final f in aPayer)
              Option(
                valeur: f.facture.numero,
                titre: suivi.client(f.facture.clientId).client.nom,
                sousTitre: '${numeroCourt(f)} · ${date(f.facture.date)}',
                avant: AvatarClient(suivi.client(f.facture.clientId).client, rayon: 18),
                apres: Text(
                  court(f.solde),
                  style: TextStyle(color: c.alerte, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        if (_facture != null) ...[
          espaceChamp,
          Card(
            child: LigneChiffre(
              icone: Symbols.hourglass_bottom,
              mot: 'À payer',
              montant: court(solde),
              couleur: solde > 0 ? c.alerte : c.ok,
            ),
          ),
        ],
        espaceChamp,
        ChampNombre(
          controleur: _montant,
          libelle: 'Reçu',
          icone: Symbols.payments,
          maximum: _facture == null ? null : solde,
          messageMaximum: 'Il reste ${court(solde)} à payer',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: solde == 0 ? null : () => setState(() => ecrireNombre(_montant, solde)),
            icon: const Icon(Symbols.done_all),
            label: const Text('Tout payé'),
          ),
        ),
        const TitreChamps('Comment ?', icone: Symbols.wallet),
        ChoixBoutons<ModePaiement>(
          options: [for (final m in ModePaiement.values) (m, m.libelle, Icon(EcranFacture.iconeMode(m), size: 18))],
          valeur: _mode,
          onChanged: (m) => setState(() => _mode = m),
        ),
        espaceChamp,
        ChampDate(valeur: _date, onChanged: (d) => setState(() => _date = d)),
        espaceChamp,
        ChampTexte(controleur: _remarque, libelle: 'Remarque', icone: Symbols.edit_note, requis: false),
      ],
    );
  }
}
