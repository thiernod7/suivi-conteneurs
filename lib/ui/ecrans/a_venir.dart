import 'package:flutter/material.dart';

import '../composants.dart';

/// Écran prévu dans le cahier des charges mais pas encore construit.
class EcranAVenir extends StatelessWidget {
  const EcranAVenir({super.key, required this.titre, required this.icone, required this.contenu});

  final String titre;
  final IconData icone;

  /// Ce que l'écran montrera.
  final List<String> contenu;

  @override
  Widget build(BuildContext context) {
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    return PageContenu(enfants: [
      Text(titre.toUpperCase(), style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icone, size: 32, color: muet),
              const SizedBox(width: 12),
              Expanded(child: Text('Écran en préparation', style: Theme.of(context).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 12),
            Text('Il montrera :', style: TextStyle(color: muet)),
            const SizedBox(height: 6),
            for (final ligne in contenu)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(color: muet)),
                  Expanded(child: Text(ligne)),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }
}
