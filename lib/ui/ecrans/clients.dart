import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../recherche.dart';
import '../suivi_scope.dart';

enum _Filtre { tous, doivent, payes, limite }

/// Les clients : ceux qui doivent le plus d'abord. On cherche un nom ou un quartier, on filtre.
class EcranClients extends StatefulWidget {
  const EcranClients({super.key});

  @override
  State<EcranClients> createState() => _EcranClientsState();
}

class _EcranClientsState extends State<EcranClients> {
  final _controleur = TextEditingController();
  var _recherche = '';
  var _filtre = _Filtre.tous;
  String? _conteneur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  bool _garde(CalculClient k, _Filtre f) {
    final ok = switch (f) {
      _Filtre.tous => true,
      _Filtre.doivent => k.doit > 0,
      _Filtre.payes => k.doit <= 0,
      _Filtre.limite => k.depasseLimite,
    };
    return ok &&
        (_conteneur == null || k.conteneurs.contains(_conteneur)) &&
        correspond([k.client.nom, k.client.quartier], _recherche);
  }

  void _toutVoir() => setState(() {
        _controleur.clear();
        _recherche = '';
        _filtre = _Filtre.tous;
        _conteneur = null;
      });

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final tous = suivi.clients
      ..sort((a, b) => b.doit != a.doit ? b.doit.compareTo(a.doit) : a.client.nom.compareTo(b.client.nom));
    final visibles = tous.where((k) => _garde(k, _filtre)).toList();
    final conteneurs = [for (final c in suivi.conteneurs) c.conteneur]..sort((a, b) => b.arrivee.compareTo(a.arrivee));

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: PageContenu(enfants: [
        BarreRecherche<_Filtre>(
          controleur: _controleur,
          indice: 'Nom ou quartier',
          onRecherche: (v) => setState(() => _recherche = v),
          filtres: const [
            Filtre(_Filtre.tous, 'Tous'),
            Filtre(_Filtre.doivent, 'Me doivent', icone: Symbols.hourglass_bottom),
            Filtre(_Filtre.payes, 'Payé', icone: Symbols.check_circle),
            Filtre(_Filtre.limite, 'Limite dépassée', icone: Symbols.warning),
          ],
          filtre: _filtre,
          nombre: (f) => tous.where((k) => _garde(k, f)).length,
          onFiltre: (f) => setState(() => _filtre = f),
          conteneurs: conteneurs,
          conteneur: _conteneur,
          onConteneur: (id) => setState(() => _conteneur = id),
        ),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          AucunResultat(icone: Symbols.person_off, texte: 'Personne', onToutVoir: _toutVoir)
        else
          CarteListe(lignes: [
            for (final k in visibles)
              LigneClient(
                client: k.client,
                doit: k.doit,
                statut: k.statut,
                alerte: k.depasseLimite,
                dessous: Wrap(spacing: 14, runSpacing: 4, children: [
                  for (final id in k.conteneurs) PuceConteneur(suivi.conteneur(id).conteneur),
                ]),
                onTap: () => context.push('/clients/${k.client.id}'),
              ),
          ]),
      ]),
    );
  }
}
