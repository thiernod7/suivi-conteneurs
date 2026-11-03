import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../suivi_scope.dart';
import '../theme.dart';

enum _Filtre { tous, doivent, payes }

/// Les clients : ceux qui doivent le plus d'abord. On peut chercher un nom ou filtrer.
class EcranClients extends StatefulWidget {
  const EcranClients({super.key});

  @override
  State<EcranClients> createState() => _EcranClientsState();
}

class _EcranClientsState extends State<EcranClients> {
  var _recherche = '';
  var _filtre = _Filtre.tous;

  static String _simple(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u');

  bool _garde(CalculClient k) {
    final ok = switch (_filtre) {
      _Filtre.tous => true,
      _Filtre.doivent => k.doit > 0,
      _Filtre.payes => k.doit <= 0,
    };
    return ok && _simple('${k.client.nom} ${k.client.quartier}').contains(_simple(_recherche.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final tous = suivi.clients..sort((a, b) => b.doit != a.doit ? b.doit.compareTo(a.doit) : a.client.nom.compareTo(b.client.nom));
    final visibles = tous.where(_garde).toList();
    final nombre = {
      _Filtre.tous: tous.length,
      _Filtre.doivent: tous.where((k) => k.doit > 0).length,
      _Filtre.payes: tous.where((k) => k.doit <= 0).length,
    };
    const libelles = {_Filtre.tous: 'Tous', _Filtre.doivent: 'Me doivent', _Filtre.payes: 'Payé'};

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: PageContenu(enfants: [
        TextField(
          onChanged: (v) => setState(() => _recherche = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Symbols.search),
            hintText: 'Chercher un nom',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in _Filtre.values)
            ChoiceChip(
              label: Text('${libelles[f]}  ${nombre[f]}'),
              selected: _filtre == f,
              onSelected: (_) => setState(() => _filtre = f),
            ),
        ]),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              Icon(Symbols.person_off, size: 48, color: context.couleurs.muet, weight: 200),
              const SizedBox(height: 8),
              Text('Personne', style: TextStyle(fontSize: 18, color: context.couleurs.muet)),
            ]),
          )
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
