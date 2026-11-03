import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Destination {
  const Destination(this.chemin, this.libelle, this.icone, this.iconeActive);

  final String chemin;
  final String libelle;
  final IconData icone;
  final IconData iconeActive;
}

const destinations = [
  Destination('/', 'Accueil', Icons.home_outlined, Icons.home),
  Destination('/conteneurs', 'Conteneurs', Icons.inventory_2_outlined, Icons.inventory_2),
  Destination('/clients', 'Clients', Icons.people_outline, Icons.people),
  Destination('/factures', 'Factures', Icons.receipt_long_outlined, Icons.receipt_long),
];

/// Cadre commun : barre de boutons en bas sur téléphone, sur le côté sur ordinateur.
class Coquille extends StatelessWidget {
  const Coquille({super.key, required this.chemin, required this.enfant});

  final String chemin;
  final Widget enfant;

  int get _index {
    final i = destinations.lastIndexWhere((d) => d.chemin == '/' ? chemin == '/' : chemin.startsWith(d.chemin));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    void aller(int i) => context.go(destinations[i].chemin);

    if (MediaQuery.sizeOf(context).width < 760) {
      return Scaffold(
        body: enfant,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: aller,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icone), selectedIcon: Icon(d.iconeActive), label: d.libelle),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: aller,
          labelType: NavigationRailLabelType.all,
          groupAlignment: -.9,
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(icon: Icon(d.icone), selectedIcon: Icon(d.iconeActive), label: Text(d.libelle)),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: enfant),
      ]),
    );
  }
}
