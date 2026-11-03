import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'ecrans/plus.dart';
import 'theme.dart';

class Destination {
  const Destination(this.chemin, this.libelle, this.icone);

  final String chemin;
  final String libelle;
  final IconData icone;
}

const destinations = [
  Destination('/', 'Accueil', Symbols.home),
  Destination('/conteneurs', 'Conteneurs', Symbols.package_2),
  Destination('/clients', 'Clients', Symbols.group),
  Destination('/factures', 'Factures', Symbols.receipt_long),
  Destination('/plus', 'Plus', Symbols.menu),
];

/// Cadre commun : barre de boutons en bas sur téléphone, sur le côté sur ordinateur.
class Coquille extends StatelessWidget {
  const Coquille({super.key, required this.chemin, required this.enfant});

  final String chemin;
  final Widget enfant;

  int get _index {
    if (cheminsPlus.any(chemin.startsWith)) return destinations.length - 1;
    final i = destinations.lastIndexWhere((d) => d.chemin == '/' ? chemin == '/' : chemin.startsWith(d.chemin));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    // « Plus » n'ouvre pas d'écran : il fait monter son menu du bas.
    void aller(int i) =>
        destinations[i].chemin == '/plus' ? ouvrirMenuPlus(context) : context.go(destinations[i].chemin);
    // L'icône du bouton choisi est pleine, les autres sont en trait fin.
    Widget icone(Destination d, {bool choisie = false}) => Icon(d.icone, fill: choisie ? 1 : 0, weight: 300);
    final trait = BorderSide(color: context.couleurs.trait, width: .8);

    if (MediaQuery.sizeOf(context).width < 760) {
      return Scaffold(
        body: enfant,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: trait)),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: aller,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: icone(d), selectedIcon: icone(d, choisie: true), label: d.libelle),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border(right: trait)),
            child: NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: aller,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.9,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: icone(d),
                    selectedIcon: icone(d, choisie: true),
                    label: Text(d.libelle),
                  ),
              ],
            ),
          ),
          Expanded(child: enfant),
        ],
      ),
    );
  }
}
