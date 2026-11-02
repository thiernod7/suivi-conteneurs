import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

class Destination {
  const Destination(this.chemin, this.libelle, this.icone, this.iconeActive);

  final String chemin;
  final String libelle;
  final IconData icone;
  final IconData iconeActive;
}

const destinations = [
  Destination('/', 'Accueil', Icons.space_dashboard_outlined, Icons.space_dashboard),
  Destination('/conteneurs', 'Conteneurs', Icons.inventory_2_outlined, Icons.inventory_2),
  Destination('/clients', 'Clients', Icons.storefront_outlined, Icons.storefront),
  Destination('/factures', 'Factures', Icons.receipt_long_outlined, Icons.receipt_long),
  Destination('/rapports', 'Rapports', Icons.bar_chart_outlined, Icons.bar_chart),
];

/// Cadre commun à tous les écrans : barre de navigation en bas sur téléphone,
/// rail sur le côté sur tablette et ordinateur.
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
    final largeur = MediaQuery.sizeOf(context).width;
    void aller(int i) => context.go(destinations[i].chemin);

    if (largeur < 760) {
      return Scaffold(
        appBar: AppBar(
          title: const _Marque(),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        body: enfant,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: aller,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icone), selectedIcon: Icon(d.iconeActive), label: d.libelle),
          ],
        ),
      );
    }
    final etendu = largeur >= 1180;
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          extended: etendu,
          minExtendedWidth: 210,
          selectedIndex: _index,
          onDestinationSelected: aller,
          labelType: etendu ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
            child: etendu ? const _Marque() : const _Logo(),
          ),
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(icon: Icon(d.icone), selectedIcon: Icon(d.iconeActive), label: Text(d.libelle)),
          ],
        ),
        VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(child: enfant),
      ]),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return SizedBox(
      width: 30,
      height: 30,
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 14, color: c.conteneur(0))),
          const SizedBox(width: 2),
          Expanded(child: Container(height: 14, color: c.conteneur(1))),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          Expanded(child: Container(height: 14, color: c.conteneur(2))),
          const SizedBox(width: 2),
          Expanded(child: Container(height: 14, color: c.conteneur(3))),
        ]),
      ]),
    );
  }
}

class _Marque extends StatelessWidget {
  const _Marque();

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const _Logo(),
        const SizedBox(width: 10),
        Flexible(
          child: Text('SUIVI DES CONTENEURS',
              overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 20)),
        ),
      ]);
}
