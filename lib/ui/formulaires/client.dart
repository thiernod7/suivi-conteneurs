import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../suivi_scope.dart';
import 'champs.dart';

class FormulaireClient extends StatefulWidget {
  const FormulaireClient({super.key, this.id});

  /// Le client à modifier, ou null pour un nouveau client.
  final String? id;

  @override
  State<FormulaireClient> createState() => _FormulaireClientState();
}

class _FormulaireClientState extends State<FormulaireClient> {
  final _cle = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _quartier = TextEditingController();
  final _limite = TextEditingController();
  var _pret = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret || widget.id == null) return;
    _pret = true;
    final k = SuiviScope.of(context).client(widget.id!).client;
    _nom.text = k.nom;
    _quartier.text = k.quartier;
    ecrireNombre(_limite, k.limiteCredit);
  }

  @override
  void dispose() {
    for (final c in [_nom, _quartier, _limite]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enregistrer() {
    if (widget.id != null) {
      SuiviScope.depot(context).modifierClient(
        widget.id!,
        nom: _nom.text.trim(),
        quartier: _quartier.text.trim(),
        limiteCredit: lireNombre(_limite),
      );
      annoncer(context, 'Modifié');
      context.pop();
      return;
    }
    final id = SuiviScope.depot(context)
        .ajouterClient(nom: _nom.text.trim(), quartier: _quartier.text.trim(), limiteCredit: lireNombre(_limite));
    annoncer(context, '${_nom.text.trim()} ajouté');
    context.go('/clients/$id');
  }

  @override
  Widget build(BuildContext context) => PageFormulaire(
    titre: widget.id == null ? 'Nouveau client' : 'Modifier le client',
    supprimer: widget.id == null
        ? null
        : Suppression(
            texte: 'Supprimer ce client',
            message: '${_nom.text} sera effacé.',
            raisonImpossible: SuiviScope.depot(context).raisonGarderClient(widget.id!),
            onSupprimer: () {
              final depot = SuiviScope.depot(context);
              context.go('/clients');
              depot.supprimerClient(widget.id!);
              annoncer(context, 'Client supprimé');
            },
          ),
    cle: _cle,
    onEnregistrer: _enregistrer,
    enfants: [
      ChampTexte(controleur: _nom, libelle: 'Nom', icone: Symbols.person),
      espaceChamp,
      ChampTexte(controleur: _quartier, libelle: 'Quartier ou marché', icone: Symbols.location_on),
      espaceChamp,
      ChampNombre(controleur: _limite, libelle: 'Limite', icone: Symbols.speed, minimum: 0),
    ],
  );
}
