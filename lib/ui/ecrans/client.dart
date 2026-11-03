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

/// Un client : ce qu'il a acheté, ce qu'il a payé, ce qu'il doit, et ce qu'il a pris dans chaque conteneur.
class EcranClient extends StatelessWidget {
  const EcranClient({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final suivi = SuiviScope.of(context);
    final k = suivi.client(id);
    final c = context.couleurs;
    final factures = [...k.factures]..sort((a, b) => b.facture.date.compareTo(a.facture.date));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/clients')),
        title: Row(children: [
          AvatarClient(k.client, rayon: 17),
          const SizedBox(width: 10),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(k.client.nom))),
        ]),
      ),
      body: PageContenu(enfants: [
        Row(children: [
          Icon(Symbols.location_on, size: 20, color: c.muet),
          const SizedBox(width: 4),
          Flexible(child: Text(k.client.quartier, style: TextStyle(color: c.muet, fontSize: 15.5))),
        ]),
        const SizedBox(height: 14),
        Grille(largeurMin: 180, colonnesMin: 2, enfants: [
          CaseChiffre(icone: Symbols.shopping_bag, mot: 'Acheté', montant: court(k.achete)),
          CaseChiffre(icone: Symbols.payments, mot: 'Reçu', montant: court(k.paye), couleur: c.ok),
          if (k.doit >= 0)
            CaseChiffre(
              icone: Symbols.hourglass_bottom,
              mot: 'Me doit',
              montant: court(k.doit),
              couleur: k.doit > 0 ? c.alerte : c.ok,
            )
          else
            CaseChiffre(icone: Symbols.undo, mot: 'Je lui dois', montant: court(-k.doit), couleur: c.attention),
        ]),
        const SizedBox(height: 12),
        _Limite(k),
        const TitreSection('Ses conteneurs', icone: Symbols.package_2),
        Grille(largeurMin: 420, enfants: [
          for (final part in k.parConteneur)
            _CartePart(part, suivi.conteneur(part.conteneurId).conteneur,
                onTap: () => context.push('/conteneurs/${part.conteneurId}')),
        ]),
        const TitreSection('Ses factures', icone: Symbols.receipt_long),
        CarteListe(lignes: [for (final f in factures) _LigneFacture(f, suivi)]),
      ]),
    );
  }
}

/// Ce que le client doit, comparé à sa limite.
class _Limite extends StatelessWidget {
  const _Limite(this.k);

  final CalculClient k;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final doit = k.doit < 0 ? 0 : k.doit;
    final limite = k.client.limiteCredit;
    final couleur = k.depasseLimite ? c.alerte : (doit > limite * .8 ? c.attention : c.ok);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(k.depasseLimite ? Symbols.warning : Symbols.speed, color: couleur, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(k.depasseLimite ? 'Limite dépassée' : 'Limite',
                  style: TextStyle(fontSize: 16, color: k.depasseLimite ? c.alerte : c.muet)),
            ),
            Text('${court(doit)} / ${court(limite)}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          Barre(part: limite == 0 ? 1 : doit / limite, couleur: couleur),
        ]),
      ),
    );
  }
}

/// Ce que le client a pris dans un conteneur.
class _CartePart extends StatelessWidget {
  const _CartePart(this.part, this.conteneur, {required this.onTap});

  final PartConteneur part;
  final Conteneur conteneur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CarreConteneur(conteneur, taille: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(conteneur.numeroCourt, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final p in conteneur.produits)
                  if ((part.quantites[p.id] ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        IconeDeProduit(p.icone, taille: 24),
                        const SizedBox(width: 8),
                        Flexible(child: Text('${nombre(part.quantites[p.id]!)} ${p.unite}', style: const TextStyle(fontSize: 15.5))),
                      ]),
                    ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (part.doit > 0)
                Text(court(part.doit), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.alerte)),
              const SizedBox(height: 4),
              StatutBadge(part.statut),
            ]),
            const SizedBox(width: 4),
            Icon(Symbols.chevron_right, color: c.muet),
          ]),
        ),
      ),
    );
  }
}

class _LigneFacture extends StatelessWidget {
  const _LigneFacture(this.f, this.suivi);

  final CalculFacture f;
  final Suivi suivi;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(Symbols.receipt_long, color: c.muet),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.facture.numero.substring(4), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(date(f.facture.date), style: TextStyle(color: c.muet, fontSize: 14)),
              for (final id in f.conteneurs) PuceConteneur(suivi.conteneur(id).conteneur),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(court(f.net), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          StatutBadge(f.statut),
        ]),
      ]),
    );
  }
}
