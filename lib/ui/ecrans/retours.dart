import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../composants.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'facture.dart';

/// Les retours et remises, les plus récents d'abord.
class EcranRetours extends StatelessWidget {
  const EcranRetours({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final retours = [...suivi.avoirs]..sort((a, b) => b.avoir.date.compareTo(a.avoir.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Retours')),
      floatingActionButton: const BoutonAjouter('Nouveau retour', chemin: '/nouveau/retour'),
      body: PageContenu(enfants: [
        if (retours.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Aucun retour', style: TextStyle(fontSize: 18, color: c.muet))),
          )
        else
          CarteListe(lignes: [
            for (final a in retours)
              InkWell(
                onTap: () => context.push('/modifier/retour?numero=${a.avoir.numero}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    IconeDeProduit(suivi.produit(a.ligne.ligne).icone, taille: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(suivi.client(a.facture.facture.clientId).client.nom,
                            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                        Text(
                          '${EcranFacture.motAvoir(a.avoir.type)}'
                          '${a.avoir.type.marchandiseRendue ? ' ${nombre(a.avoir.quantite)}' : ''} · ${date(a.avoir.date)}',
                          style: TextStyle(color: c.attention, fontSize: 14),
                        ),
                        Text(a.avoir.motif, style: TextStyle(color: c.muet, fontSize: 14)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text('− ${court(a.montant)}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.attention)),
                  ]),
                ),
              ),
          ]),
      ]),
    );
  }
}
