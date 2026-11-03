import 'package:flutter_test/flutter_test.dart';
import 'package:suivi_conteneurs/domaine/calculs.dart';
import 'package:suivi_conteneurs/donnees/exemple.dart';

void main() {
  final suivi = Suivi(donneesExemple, aujourdhuiExemple);

  test('coût d\'un conteneur = achat + fret + dédouanement + manutention', () {
    expect(suivi.conteneur('C1').cout, 290000000 + 48000000 + 22000000 + 6000000);
    expect(suivi.totaux.investi, 1069000000);
  });

  test('ventes du conteneur après retour remis en stock', () {
    final c1 = suivi.conteneur('C1');
    // riz : 1 000 sacs ; huile : 200 − 20 rendus + 90 = 270 bidons
    expect(c1.ventes, 1000 * 285000 + 270 * 390000);
    final huile = c1.produits[1];
    expect((huile.vendu, huile.rendu, huile.rebut, huile.stock), (270, 20, 0, 30));
    expect(c1.resultat, c1.ventes - c1.cout);
    expect(c1.resultatPrevu, c1.resultat + 30 * 390000);
  });

  test('marchandise au rebut : ni vendue ni en stock', () {
    final batteries = suivi.conteneur('C3').produits[1];
    expect((batteries.vendu, batteries.rendu, batteries.rebut, batteries.stock), (340, 10, 10, 50));
  });

  test('avoir déduit d\'une facture qui restait à payer', () {
    final f5 = suivi.facture('FAC-2026-005');
    expect(f5.avoirs.single.deduitDeLaFacture, isTrue);
    expect(f5.solde, 78000000 - 7800000);
    expect(f5.statut, StatutPaiement.impaye);

    final f13 = suivi.facture('FAC-2026-013');
    expect(f13.solde, 84000000 - 2520000 - 42000000);
    expect(f13.statut, StatutPaiement.partiel);
  });

  test('avoir sur une facture déjà payée : crédit pour le client', () {
    final f11 = suivi.facture('FAC-2026-011');
    expect(f11.avoirs.single.deduitDeLaFacture, isFalse);
    expect((f11.solde, f11.credit, f11.statut), (0, 2100000, StatutPaiement.solde));
    expect(suivi.client('k3').doit, -2100000);
  });

  test('un paiement couvre les lignes au prorata, conteneur par conteneur', () {
    final f8 = suivi.facture('FAC-2026-008');
    expect(f8.conteneurs, {'C1', 'C2'});
    final huile = f8.lignes[0], tomate = f8.lignes[1];
    expect(huile.encaisse + tomate.encaisse, 21060000);
    expect(huile.encaisse, 21060000 * 35100000 ~/ 47100000);
  });

  test('les totaux se recoupent', () {
    final t = suivi.totaux;
    final paiements = donneesExemple.paiements.fold(0, (s, p) => s + p.montant);
    final credits = suivi.factures.fold(0, (s, f) => s + f.credit);
    expect(t.encaisse, paiements - credits);
    expect(t.reste, t.ventes - t.encaisse);
    expect(t.resultat, t.ventes - t.investi);
    expect(suivi.clients.fold(0, (s, k) => s + k.doit), t.reste - credits);
    expect(suivi.clients.fold(0, (s, k) => s + k.achete), t.ventes);
  });

  test('statuts et limite de crédit', () {
    expect(suivi.client('k3').statut, StatutPaiement.solde);
    expect(suivi.client('k2').statut, StatutPaiement.partiel);
    expect(suivi.client('k4').statut, StatutPaiement.impaye);
    expect(suivi.clients.where((k) => k.depasseLimite).map((k) => k.client.nom), ['Fatoumata Camara', 'Mariama Diallo']);
  });

  test('ce qu\'un client a pris dans chaque conteneur', () {
    final parts = {for (final p in suivi.client('k2').parConteneur) p.conteneurId: p};
    expect(parts.keys.toSet(), {'C1', 'C2', 'C4'});
    expect(parts['C1']!.quantites, {'C1-riz': 250, 'C1-huile': 90});
    expect(parts.values.fold(0, (s, p) => s + p.achete), suivi.client('k2').achete);
    expect(parts.values.fold(0, (s, p) => s + p.paye), suivi.client('k2').paye);
    // retour de 20 bidons : Mariama Diallo en garde 180
    expect(suivi.client('k4').parConteneur.firstWhere((p) => p.conteneurId == 'C1').quantites['C1-huile'], 180);
  });
}
