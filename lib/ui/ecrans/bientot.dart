import 'package:flutter/material.dart';

import '../theme.dart';

/// Écran pas encore construit.
class EcranBientot extends StatelessWidget {
  const EcranBientot({super.key, required this.titre, required this.icone});

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final muet = context.couleurs.muet;
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 56, color: muet, weight: 200),
          const SizedBox(height: 12),
          Text('Bientôt', style: TextStyle(fontSize: 20, color: muet)),
        ]),
      ),
    );
  }
}
