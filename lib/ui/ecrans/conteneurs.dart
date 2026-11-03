import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../composants.dart';
import '../suivi_scope.dart';

class EcranConteneurs extends StatelessWidget {
  const EcranConteneurs({super.key});

  @override
  Widget build(BuildContext context) {
    final conteneurs = [...SuiviScope.of(context).conteneurs]
      ..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee));
    return Scaffold(
      appBar: AppBar(title: const Text('Conteneurs')),
      body: PageContenu(enfants: [
        Grille(largeurMin: 420, enfants: [
          for (final c in conteneurs) LigneConteneur(c, onTap: () => context.push('/conteneurs/${c.conteneur.id}')),
        ]),
      ]),
    );
  }
}
