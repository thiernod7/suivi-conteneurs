import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domaine/calculs.dart';
import '../../domaine/modeles.dart';
import '../composants.dart';
import '../format.dart';
import '../illustrations/produits.dart';
import '../suivi_scope.dart';
import '../theme.dart';
import 'factures.dart';

/// Une facture, comme un reçu : ce qui a été pris, l'argent reçu, et ce qui reste à payer.
class EcranFacture extends StatelessWidget {
  const EcranFacture({super.key, required this.numero});

  final String numero;

  static String motAvoir(TypeAvoir t) => switch (t) {
        TypeAvoir.remisEnStock => 'Rendus',
        TypeAvoir.rebut => 'Rendus · abîmés',
        TypeAvoir.remise => 'Remise',
      };

  static IconData iconeMode(ModePaiement m) => switch (m) {
        ModePaiement.especes => Symbols.payments,
        ModePaiement.orangeMoney || ModePaiement.mtnMomo => Symbols.smartphone,
        ModePaiement.virement => Symbols.account_balance,
      };

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final f = suivi.facture(numero);
    final client = suivi.client(f.facture.clientId).client;
    final c = context.couleurs;
    final retours = f.avoirs.where((a) => a.deduitDeLaFacture).fold(0, (s, a) => s + a.montant);
    final paiements = [...f.paiements]..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/factures')),
        title: Row(children: [
          Icon(Symbols.receipt_long, color: c.muet),
          const SizedBox(width: 10),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Facture ${numeroCourt(f)}'))),
        ]),
      ),
      body: PageContenu(enfants: [
        // Le client et la date.
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/clients/${client.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                AvatarClient(client),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(client.nom, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Wrap(spacing: 12, runSpacing: 2, children: [
                      Text(date(f.facture.date), style: TextStyle(color: c.muet, fontSize: 14)),
                      if (f.solde > 0)
                        Text('${f.age} jours',
                            style: TextStyle(color: f.age > 30 ? c.alerte : c.muet, fontSize: 14)),
                    ]),
                  ]),
                ),
                Icon(Symbols.chevron_right, color: c.muet),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Le chiffre qui compte.
        if (f.solde > 0)
          CaseChiffre(grand: true, icone: Symbols.hourglass_bottom, mot: 'À payer', montant: court(f.solde), couleur: c.alerte)
        else if (f.credit > 0)
          CaseChiffre(grand: true, icone: Symbols.undo, mot: 'Je lui dois', montant: court(f.credit), couleur: c.attention)
        else
          CaseChiffre(grand: true, icone: Symbols.check_circle, mot: 'Payé', montant: court(f.net), couleur: c.ok),
        const SizedBox(height: 12),
        // Le compte, ligne par ligne, comme sur un reçu.
        CarteListe(lignes: [
          LigneChiffre(icone: Symbols.receipt_long, mot: 'Montant', montant: court(f.total)),
          if (retours > 0) LigneChiffre(icone: Symbols.undo, mot: 'Retours', montant: '− ${court(retours)}'),
          LigneChiffre(icone: Symbols.payments, mot: 'Reçu', montant: f.paye > 0 ? '− ${court(f.paye)}' : '0', couleur: c.ok),
          LigneChiffre(
            icone: Symbols.hourglass_bottom,
            mot: 'À payer',
            montant: court(f.solde),
            couleur: f.solde > 0 ? c.alerte : c.ok,
          ),
        ]),
        if (f.credit > 0) ...[
          const SizedBox(height: 12),
          Note(
            icone: Symbols.info,
            texte: 'Déjà payée avant le retour. Je lui dois ${court(f.credit)} GNF.',
            couleur: c.attention,
          ),
        ],
        const TitreSection('Ce qu\'il a pris', icone: Symbols.shopping_bag),
        CarteListe(lignes: [for (final l in f.lignes) _LigneProduit(l, suivi)]),
        const TitreSection('Paiements', icone: Symbols.payments),
        if (paiements.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Symbols.cancel, color: c.alerte),
                const SizedBox(width: 12),
                Text('Rien reçu', style: TextStyle(fontSize: 16, color: c.alerte)),
              ]),
            ),
          )
        else
          CarteListe(lignes: [
            for (final p in paiements)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Icon(iconeMode(p.mode), color: c.ok),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.mode.libelle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Text([date(p.date), ?p.remarque].join(' · '), style: TextStyle(color: c.muet, fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(court(p.montant), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ok)),
                ]),
              ),
          ]),
      ]),
    );
  }
}

/// Un produit de la facture : image, conteneur d'origine, quantité × prix, montant, et retour éventuel.
class _LigneProduit extends StatelessWidget {
  const _LigneProduit(this.l, this.suivi);

  final CalculLigne l;
  final Suivi suivi;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final p = suivi.produit(l.ligne);
    final conteneur = suivi.conteneur(l.ligne.conteneurId).conteneur;
    final avoirs = suivi.avoirs.where((a) => a.ligne == l).toList();
    return InkWell(
      onTap: () => context.push('/conteneurs/${conteneur.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconeDeProduit(p.icone, taille: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${nombre(l.ligne.quantite)} ${p.unite} × ${nombre(l.ligne.prix)}',
                    style: TextStyle(color: c.muet, fontSize: 14)),
                const SizedBox(height: 4),
                PuceConteneur(conteneur),
              ]),
            ),
            const SizedBox(width: 8),
            Text(court(l.ligne.montant), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
          ]),
          for (final a in avoirs)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: Row(children: [
                Icon(Symbols.undo, size: 18, color: c.attention),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    a.avoir.type == TypeAvoir.remise
                        ? EcranFacture.motAvoir(a.avoir.type)
                        : '${EcranFacture.motAvoir(a.avoir.type)} ${nombre(a.avoir.quantite)}',
                    style: TextStyle(color: c.attention, fontSize: 14.5),
                  ),
                ),
                Text('− ${court(a.montant)}', style: TextStyle(color: c.attention, fontWeight: FontWeight.w500)),
              ]),
            ),
        ]),
      ),
    );
  }
}
