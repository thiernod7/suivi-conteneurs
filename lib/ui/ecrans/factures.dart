import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../format.dart';
import '../recherche.dart';
import '../suivi_scope.dart';
import '../theme.dart';

enum _Filtre { toutes, aPayer, enRetard, payees }

/// Les factures, les plus récentes d'abord. On cherche un client, un numéro ou un produit, on filtre.
class EcranFactures extends StatefulWidget {
  const EcranFactures({super.key});

  @override
  State<EcranFactures> createState() => _EcranFacturesState();
}

class _EcranFacturesState extends State<EcranFactures> {
  final _controleur = TextEditingController();
  var _recherche = '';
  var _filtre = _Filtre.toutes;
  String? _conteneur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  bool _garde(Suivi suivi, CalculFacture f, _Filtre filtre, String? conteneur) {
    final ok = switch (filtre) {
      _Filtre.toutes => true,
      _Filtre.aPayer => f.solde > 0,
      _Filtre.enRetard => f.solde > 0 && f.age > 30,
      _Filtre.payees => f.solde == 0,
    };
    return ok &&
        (conteneur == null || f.conteneurs.contains(conteneur)) &&
        correspond([
          suivi.client(f.facture.clientId).client.nom,
          f.facture.numero,
          for (final l in f.lignes) suivi.produit(l.ligne).nom,
        ], _recherche);
  }

  void _toutVoir() => setState(() {
        _controleur.clear();
        _recherche = '';
        _filtre = _Filtre.toutes;
        _conteneur = null;
      });

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final toutes = suivi.factures..sort((a, b) => b.facture.date.compareTo(a.facture.date));
    final visibles = toutes.where((f) => _garde(suivi, f, _filtre, _conteneur)).toList();
    final conteneurs = [for (final c in suivi.conteneurs) c.conteneur]..sort((a, b) => b.arrivee.compareTo(a.arrivee));

    return Scaffold(
      floatingActionButton: const BoutonAjouter('Nouvelle facture', chemin: '/nouveau/facture'),
      appBar: AppBar(title: const Text('Factures')),
      body: PageContenu(enfants: [
        BarreRecherche<_Filtre>(
          controleur: _controleur,
          indice: 'Nom, numéro ou produit',
          onRecherche: (v) => setState(() => _recherche = v),
          filtres: const [
            Filtre(_Filtre.toutes, 'Toutes'),
            Filtre(_Filtre.aPayer, 'À payer', icone: Symbols.hourglass_bottom),
            Filtre(_Filtre.enRetard, 'En retard', icone: Symbols.schedule),
            Filtre(_Filtre.payees, 'Payé', icone: Symbols.check_circle),
          ],
          titreFiltres: 'Paiement',
          iconeFiltres: Symbols.payments,
          filtre: _filtre,
          conteneurs: conteneurs,
          conteneur: _conteneur,
          nombre: (f, id) => toutes.where((x) => _garde(suivi, x, f, id)).length,
          onAppliquer: (f, id) => setState(() {
            _filtre = f;
            _conteneur = id;
          }),
        ),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          AucunResultat(icone: Symbols.receipt_long, texte: 'Rien', onToutVoir: _toutVoir)
        else
          CarteListe(lignes: [
            for (final f in visibles) RangFacture(f, onTap: () => context.push('/factures/${f.facture.numero}')),
          ]),
      ]),
    );
  }
}

/// Une ligne de facture dans une liste : le client, le numéro et la date, les conteneurs,
/// ce qui reste à payer (ou le montant si tout est payé), le statut, l'âge si elle traîne.
class RangFacture extends StatelessWidget {
  const RangFacture(this.f, {super.key, this.onTap, this.avecClient = true});

  final CalculFacture f;
  final VoidCallback? onTap;

  /// Faux sur la page d'un client : on sait déjà qui c'est.
  final bool avecClient;

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final c = context.couleurs;
    final client = suivi.client(f.facture.clientId).client;
    final enRetard = f.solde > 0 && f.age > 30;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (avecClient) AvatarClient(client) else Icon(Symbols.receipt_long, color: c.muet),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(avecClient ? client.nom : numeroCourt(f), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(avecClient ? '${numeroCourt(f)} · ${date(f.facture.date)}' : date(f.facture.date),
                    style: TextStyle(color: c.muet, fontSize: 14)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(court(f.solde > 0 ? f.solde : f.net),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: f.solde > 0 ? c.alerte : null)),
              const SizedBox(height: 4),
              StatutBadge(f.statut),
            ]),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right, color: c.muet),
            ],
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 58, top: 8),
            child: Wrap(spacing: 14, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final id in f.conteneurs) PuceConteneur(suivi.conteneur(id).conteneur),
              if (f.solde > 0)
                Text.rich(
                  TextSpan(children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Symbols.schedule, size: 16, color: enRetard ? c.alerte : c.muet),
                      ),
                    ),
                    TextSpan(text: '${f.age} jours'),
                  ]),
                  style: TextStyle(fontSize: 13.5, color: enRetard ? c.alerte : c.muet),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// « 2026-008 » à partir de « FAC-2026-008 ».
String numeroCourt(CalculFacture f) => f.facture.numero.replaceFirst('FAC-', '');
