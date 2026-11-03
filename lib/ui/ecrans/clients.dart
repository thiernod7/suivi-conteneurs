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

  bool _garde(CalculClient k, _Filtre f, String? conteneur) {
    final ok = switch (f) {
      _Filtre.tous => true,
      _Filtre.doivent => k.doit > 0,
      _Filtre.payes => k.doit <= 0,
      _Filtre.limite => k.depasseLimite,
    };
    return ok &&
        (conteneur == null || k.conteneurs.contains(conteneur)) &&
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
    final visibles = tous.where((k) => _garde(k, _filtre, _conteneur)).toList();
    final conteneurs = [for (final c in suivi.conteneurs) c.conteneur]..sort((a, b) => b.arrivee.compareTo(a.arrivee));

    return Scaffold(
      floatingActionButton: const BoutonAjouter('Nouveau client', chemin: '/nouveau/client'),
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
          titreFiltres: 'Paiement',
          iconeFiltres: Symbols.payments,
          filtre: _filtre,
          conteneurs: conteneurs,
          conteneur: _conteneur,
          nombre: (f, id) => tous.where((k) => _garde(k, f, id)).length,
          onAppliquer: (f, id) => setState(() {
            _filtre = f;
            _conteneur = id;
          }),
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
