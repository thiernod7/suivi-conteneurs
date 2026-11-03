import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../composants.dart';
import '../format.dart';
import '../suivi_scope.dart';
import '../theme.dart';

enum _Filtre { toutes, aPayer, payees }

/// Les factures, les plus récentes d'abord. On peut chercher un client ou un numéro, ou filtrer.
class EcranFactures extends StatefulWidget {
  const EcranFactures({super.key});

  @override
  State<EcranFactures> createState() => _EcranFacturesState();
}

class _EcranFacturesState extends State<EcranFactures> {
  var _recherche = '';
  var _filtre = _Filtre.toutes;

  static String _simple(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u');

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final toutes = suivi.factures..sort((a, b) => b.facture.date.compareTo(a.facture.date));
    bool aPayer(CalculFacture f) => f.solde > 0;
    final nombre = {
      _Filtre.toutes: toutes.length,
      _Filtre.aPayer: toutes.where(aPayer).length,
      _Filtre.payees: toutes.where((f) => !aPayer(f)).length,
    };
    const libelles = {_Filtre.toutes: 'Toutes', _Filtre.aPayer: 'À payer', _Filtre.payees: 'Payé'};
    final visibles = toutes.where((f) {
      final ok = switch (_filtre) {
        _Filtre.toutes => true,
        _Filtre.aPayer => aPayer(f),
        _Filtre.payees => !aPayer(f),
      };
      final texte = '${suivi.client(f.facture.clientId).client.nom} ${f.facture.numero}';
      return ok && _simple(texte).contains(_simple(_recherche.trim()));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      body: PageContenu(enfants: [
        TextField(
          onChanged: (v) => setState(() => _recherche = v),
          decoration: const InputDecoration(prefixIcon: Icon(Symbols.search), hintText: 'Chercher un nom ou un numéro'),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in _Filtre.values)
            ChoiceChip(
              label: Text('${libelles[f]}  ${nombre[f]}'),
              selected: _filtre == f,
              onSelected: (_) => setState(() => _filtre = f),
            ),
        ]),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              Icon(Symbols.receipt_long, size: 48, color: context.couleurs.muet, weight: 200),
              const SizedBox(height: 8),
              Text('Rien', style: TextStyle(fontSize: 18, color: context.couleurs.muet)),
            ]),
          )
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
