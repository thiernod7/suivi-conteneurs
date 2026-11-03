import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/modeles.dart';
import '../composants.dart';
import '../format.dart';
import '../recherche.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'facture.dart';
import 'factures.dart';

/// Tout l'argent reçu, le plus récent d'abord.
class EcranPaiements extends StatefulWidget {
  const EcranPaiements({super.key});

  @override
  State<EcranPaiements> createState() => _EcranPaiementsState();
}

class _EcranPaiementsState extends State<EcranPaiements> {
  final _controleur = TextEditingController();
  var _recherche = '';
  ModePaiement? _mode;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final tous = [...suivi.donnees.paiements]..sort((a, b) => b.date.compareTo(a.date));
    bool garde(Paiement p, ModePaiement? m) =>
        (m == null || p.mode == m) &&
        correspond([suivi.client(suivi.facture(p.facture).facture.clientId).client.nom, p.facture, p.remarque ?? ''], _recherche);
    final visibles = tous.where((p) => garde(p, _mode)).toList();
    final total = visibles.fold(0, (s, p) => s + p.montant);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      floatingActionButton: const BoutonAjouter('Nouveau paiement', chemin: '/nouveau/paiement'),
      body: PageContenu(enfants: [
        BarreRecherche<ModePaiement?>(
          controleur: _controleur,
          indice: 'Nom ou numéro de facture',
          onRecherche: (v) => setState(() => _recherche = v),
          titreFiltres: 'Comment ?',
          iconeFiltres: Symbols.wallet,
          filtres: [
            const Filtre(null, 'Tous'),
            for (final m in ModePaiement.values) Filtre(m, m.libelle, icone: EcranFacture.iconeMode(m)),
          ],
          filtre: _mode,
          conteneurs: const [],
          conteneur: null,
          nombre: (m, _) => tous.where((p) => garde(p, m)).length,
          onAppliquer: (m, _) => setState(() => _mode = m),
        ),
        const SizedBox(height: 16),
        Card(child: LigneChiffre(icone: Symbols.payments, mot: 'Reçu', montant: court(total), couleur: c.ok)),
        const SizedBox(height: 12),
        CarteListe(lignes: [
          for (final p in visibles)
            InkWell(
              onTap: () => context.push('/factures/${p.facture}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Icon(EcranFacture.iconeMode(p.mode), color: c.ok),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(suivi.client(suivi.facture(p.facture).facture.clientId).client.nom,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                      Text('${numeroCourt(suivi.facture(p.facture))} · ${date(p.date)} · ${p.mode.libelle}',
                          style: TextStyle(color: c.muet, fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(court(p.montant), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ok)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}
