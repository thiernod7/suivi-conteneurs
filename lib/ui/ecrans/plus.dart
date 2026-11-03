import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../composants.dart';
import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// Le menu « Plus » : tout ce qui n'a pas sa place dans la barre du bas.
class EcranPlus extends StatelessWidget {
  const EcranPlus({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final nbProduits = suivi.conteneurs.fold(0, (s, c) => s + c.produits.length);
    final paiements = suivi.donnees.paiements;
    final recu = paiements.fold(0, (s, p) => s + p.montant);
    final fournisseurs = {for (final c in suivi.conteneurs) c.conteneur.fournisseur};
    final c = context.couleurs;

    Widget ligne(IconData icone, String titre, String detail, String chemin) => InkWell(
          onTap: () => context.push(chemin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(children: [
              Icon(icone, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                  Text(detail, style: TextStyle(color: c.muet, fontSize: 14)),
                ]),
              ),
              Icon(Symbols.chevron_right, color: c.muet),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: PageContenu(enfants: [
        CarteListe(lignes: [
          ligne(Symbols.inventory_2, 'Produits', '$nbProduits produits', '/plus/produits'),
          ligne(Symbols.payments, 'Paiements', '${paiements.length} paiements · ${court(recu)} GNF', '/plus/paiements'),
          ligne(Symbols.undo, 'Retours', '${suivi.avoirs.length} retours', '/plus/retours'),
          ligne(Symbols.local_shipping, 'Fournisseurs', '${fournisseurs.length} fournisseurs', '/plus/fournisseurs'),
        ]),
        const SizedBox(height: 24),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _remettre(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Symbols.restart_alt, color: c.alerte),
                const SizedBox(width: 16),
                Expanded(child: Text('Remettre les exemples', style: TextStyle(fontSize: 17, color: c.alerte))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _remettre(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Symbols.restart_alt),
        title: const Text('Remettre les exemples ?'),
        content: const Text('Tout ce qui a été ajouté sera effacé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, effacer')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      SuiviScope.depot(context).remettreExemples();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exemples remis'), behavior: SnackBarBehavior.floating));
    }
  }
}
