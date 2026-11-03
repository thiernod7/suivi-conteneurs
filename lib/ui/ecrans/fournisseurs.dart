import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../composants.dart';
import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// Les fournisseurs : leurs conteneurs, ce qu'on leur a acheté, ce qu'on leur doit encore.
class EcranFournisseurs extends StatelessWidget {
  const EcranFournisseurs({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final parNom = <String, List<String>>{};
    for (final k in suivi.conteneurs..sort((a, b) => b.conteneur.arrivee.compareTo(a.conteneur.arrivee))) {
      parNom.putIfAbsent(k.conteneur.fournisseur, () => []).add(k.conteneur.id);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      body: PageContenu(enfants: [
        CarteListe(lignes: [
          for (final MapEntry(key: nom, value: ids) in parNom.entries)
            Builder(builder: (context) {
              final conteneurs = [for (final id in ids) suivi.conteneur(id).conteneur];
              final achat = conteneurs.fold(0, (s, k) => s + k.couts.achat);
              final verse = conteneurs.fold(0, (s, k) => s + k.verseFournisseur);
              final doit = achat - verse;
              return InkWell(
                onTap: () => context.push('/conteneurs/${ids.first}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    const Icon(Symbols.local_shipping, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(nom, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('Achat ${court(achat)} · payé ${court(verse)}', style: TextStyle(color: c.muet, fontSize: 14)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 12, children: [for (final k in conteneurs) PuceConteneur(k)]),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    if (doit > 0)
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Je lui dois', style: TextStyle(color: c.muet, fontSize: 13.5)),
                        Text(court(doit), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.attention)),
                      ])
                    else
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Symbols.check_circle, color: c.ok, size: 18),
                        const SizedBox(width: 4),
                        Text('Payé', style: TextStyle(color: c.ok, fontWeight: FontWeight.w500)),
                      ]),
                  ]),
                ),
              );
            }),
        ]),
      ]),
    );
  }
}
