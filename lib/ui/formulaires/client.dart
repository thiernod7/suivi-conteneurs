import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../suivi_scope.dart';
import 'champs.dart';

class FormulaireClient extends StatefulWidget {
  const FormulaireClient({super.key});

  @override
  State<FormulaireClient> createState() => _FormulaireClientState();
}

class _FormulaireClientState extends State<FormulaireClient> {
  final _cle = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _quartier = TextEditingController();
  final _limite = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nom, _quartier, _limite]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enregistrer() {
    final id = SuiviScope.depot(context).ajouterClient(
      nom: _nom.text.trim(),
      quartier: _quartier.text.trim(),
      limiteCredit: lireNombre(_limite),
    );
    annoncer(context, '${_nom.text.trim()} ajouté');
    context.go('/clients/$id');
  }

  @override
  Widget build(BuildContext context) => PageFormulaire(
        titre: 'Nouveau client',
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
