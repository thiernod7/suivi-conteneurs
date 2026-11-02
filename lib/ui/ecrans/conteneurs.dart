import 'package:flutter/material.dart';

import '../composants.dart';
import '../suivi_scope.dart';
import 'accueil.dart';

class EcranConteneurs extends StatelessWidget {
  const EcranConteneurs({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    return PageContenu(enfants: [
      Text('CONTENEURS', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 4),
      Text(
        'Chaque conteneur avec ses produits, ce qui est vendu et ce qu\'il rapporte. Le détail d\'un conteneur arrive à la prochaine étape.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      ListeConteneurs(suivi.conteneurs),
    ]);
  }
}
