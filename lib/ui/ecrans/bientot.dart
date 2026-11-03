import 'package:flutter/material.dart';

/// Écran pas encore construit.
class EcranBientot extends StatelessWidget {
  const EcranBientot({super.key, required this.titre, required this.icone});

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final muet = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 64, color: muet),
          const SizedBox(height: 12),
          Text('Bientôt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: muet)),
        ]),
      ),
    );
  }
}
