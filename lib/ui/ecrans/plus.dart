import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';

/// Les écrans qu'on ouvre depuis « Plus ». Le bouton Plus reste en avant quand on y est.
const cheminsPlus = ['/produits', '/paiements', '/retours', '/fournisseurs'];

/// Le menu « Plus » : un panneau qui monte du bas, par-dessus l'écran.
Future<void> ouvrirMenuPlus(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => const _MenuPlus(),
);

class _MenuPlus extends StatelessWidget {
  const _MenuPlus();

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final depot = SuiviScope.depot(context);
    final c = context.couleurs;
    final nbProduits = suivi.conteneurs.fold(0, (s, k) => s + k.produits.length);
    final paiements = suivi.donnees.paiements;
    final recu = paiements.fold(0, (s, p) => s + p.montant);
    final fournisseurs = {for (final k in suivi.conteneurs) k.conteneur.fournisseur};
    final sombre = Theme.of(context).brightness == Brightness.dark;

    Widget ligne(IconData icone, String titre, {String? detail, Color? couleur, required VoidCallback onTap}) =>
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          leading: Icon(icone, size: 28, color: couleur),
          title: Text(titre, style: TextStyle(fontSize: 18, color: couleur)),
          subtitle: detail == null ? null : Text(detail, style: TextStyle(color: c.muet, fontSize: 14)),
          onTap: onTap,
        );

    // On ferme le panneau, puis on va à l'écran choisi.
    void aller(String chemin) {
      Navigator.pop(context);
      context.go(chemin);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ligne(Symbols.inventory_2, 'Produits', detail: '$nbProduits produits', onTap: () => aller('/produits')),
          ligne(
            Symbols.payments,
            'Paiements',
            detail: '${paiements.length} paiements · ${court(recu)} GNF',
            onTap: () => aller('/paiements'),
          ),
          ligne(Symbols.undo, 'Retours', detail: '${suivi.avoirs.length} retours', onTap: () => aller('/retours')),
          ligne(
            Symbols.local_shipping,
            'Fournisseurs',
            detail: '${fournisseurs.length} fournisseurs',
            onTap: () => aller('/fournisseurs'),
          ),
          const Divider(indent: 24, endIndent: 24, height: 24),
          ligne(
            sombre ? Symbols.light_mode : Symbols.dark_mode,
            sombre ? 'Mode clair' : 'Mode sombre',
            onTap: () => depot.changerTheme(sombre ? ThemeMode.light : ThemeMode.dark),
          ),
          ligne(
            Symbols.restart_alt,
            'Remettre les exemples',
            detail: 'Efface ce qui a été ajouté',
            couleur: c.alerte,
            onTap: () => _remettre(context),
          ),
        ],
      ),
    );
  }

  Future<void> _remettre(BuildContext context) async {
    final depot = SuiviScope.depot(context);
    final messager = ScaffoldMessenger.of(context);
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
    if (ok != true || !context.mounted) return;
    Navigator.pop(context);
    depot.remettreExemples();
    messager.showSnackBar(const SnackBar(content: Text('Exemples remis'), behavior: SnackBarBehavior.floating));
  }
}
