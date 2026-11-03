import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_conteneurs/domaine/modeles.dart';
import 'package:suivi_conteneurs/donnees/depot.dart';
import 'package:suivi_conteneurs/donnees/exemple.dart';
import 'package:suivi_conteneurs/donnees/json.dart';

void main() {
  Depot nouveau() => Depot(donneesExemple, aujourdhui: aujourdhuiExemple);

  test('les données passent en JSON et reviennent à l\'identique', () {
    final texte = jsonEncode(donneesVersJson(donneesExemple));
    final relues = donneesDepuisJson(jsonDecode(texte) as Json);
    expect(jsonEncode(donneesVersJson(relues)), texte);
  });

  test('nouveau conteneur, puis un produit dedans', () {
    final d = nouveau();
    final id = d.ajouterConteneur(
      numero: 'MSCU 123456 7',
      type: TypeConteneur.dv20,
      origine: 'Anvers, Belgique',
      arrivee: DateTime(2026, 11, 1),
      fournisseur: 'Anvers Trading',
      verseFournisseur: 50000000,
      couts: const Couts(achat: 100000000, fret: 20000000, douane: 10000000, manutention: 2000000),
    );
    expect(id, 'C5');
    expect(d.numeroConteneurPris('MSCU 123456 7'), isTrue);
    expect(d.suivi.conteneur(id).cout, 132000000);
    final p = d.ajouterProduit(id, nom: 'Ciment 50 kg', unite: 'sacs', quantite: 500, prix: 95000, icone: IconeProduit.sac);
    expect(d.suivi.conteneur(id).produits.single.stock, 500);
    expect(d.suivi.conteneur(id).resultatPrevu, 500 * 95000 - 132000000);
    expect(p, 'C5-p1');
  });

  test('nouvelle facture : numéro suivant, stock et dette mis à jour', () {
    final d = nouveau();
    final kid = d.ajouterClient(nom: 'Kadiatou Sylla', quartier: 'Taouyah', limiteCredit: 50000000);
    final avant = d.suivi.conteneur('C4').produits[0].stock;
    final numero = d.ajouterFacture(
      clientId: kid,
      date: DateTime(2026, 11, 2),
      lignes: const [LigneFacture(conteneurId: 'C4', produitId: 'C4-sucre', quantite: 10, prix: 420000)],
      payeMaintenant: 1000000,
      mode: ModePaiement.orangeMoney,
    );
    expect(numero, 'FAC-2026-017');
    expect(d.suivi.conteneur('C4').produits[0].stock, avant - 10);
    expect(d.suivi.client(kid).doit, 4200000 - 1000000);
    expect(d.suivi.facture(numero).statut.name, 'partiel');

    d.ajouterPaiement(Paiement(facture: numero, date: DateTime(2026, 11, 2), montant: 3200000, mode: ModePaiement.especes));
    expect(d.suivi.facture(numero).solde, 0);
  });

  test('nouveau retour : numéro suivant, déduit de la facture', () {
    final d = nouveau();
    final av = d.ajouterAvoir(
      facture: 'FAC-2026-016',
      ligne: 0,
      quantite: 5,
      type: TypeAvoir.remisEnStock,
      date: DateTime(2026, 11, 2),
      motif: 'Cartons en trop',
    );
    expect(av, 'AV-2026-004');
    expect(d.suivi.facture('FAC-2026-016').solde, 75 * 260000);
  });

  test('les ajouts sont gardés sur l\'appareil, et « remettre les exemples » efface tout', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await Depot.charger(aujourdhuiExemple);
    d.ajouterClient(nom: 'Kadiatou Sylla', quartier: 'Taouyah', limiteCredit: 0);
    final relu = await Depot.charger(aujourdhuiExemple);
    expect(relu.suivi.clients.map((k) => k.client.nom), contains('Kadiatou Sylla'));
    relu.remettreExemples();
    final apres = await Depot.charger(aujourdhuiExemple);
    expect(apres.suivi.clients.length, 7);
  });

  test('modifier et supprimer un conteneur : refusé tant que des factures l\'utilisent', () {
    final d = nouveau();
    expect(d.raisonGarderConteneur('C1'), isNotNull);
    expect(() => d.supprimerConteneur('C1'), throwsStateError);
    final c4 = d.donnees.conteneurs.firstWhere((c) => c.id == 'C4');
    d.modifierConteneur('C4',
        numero: c4.numero,
        type: c4.type,
        origine: c4.origine,
        arrivee: c4.arrivee,
        fournisseur: 'Ningbo Food',
        verseFournisseur: c4.couts.achat,
        couts: c4.couts,
        statut: StatutConteneur.vendu);
    expect(d.suivi.conteneur('C4').provisoire, isFalse);
    expect(d.suivi.conteneur('C4').conteneur.fournisseur, 'Ningbo Food');
    expect(d.numeroConteneurPrisAilleurs(c4.numero, 'C4'), isFalse);
    expect(d.numeroConteneurPrisAilleurs(c4.numero, 'C1'), isTrue);

    final id = d.ajouterConteneur(
      numero: 'MSCU 123456 7',
      type: TypeConteneur.dv20,
      origine: 'Anvers',
      arrivee: DateTime(2026, 11, 1),
      fournisseur: 'X',
      verseFournisseur: 0,
      couts: const Couts(achat: 1, fret: 0, douane: 0, manutention: 0),
    );
    expect(d.raisonGarderConteneur(id), isNull);
    d.supprimerConteneur(id);
    expect(d.suivi.conteneurs.length, 4);
  });

  test('modifier un produit, supprimer seulement s\'il n\'a jamais été vendu', () {
    final d = nouveau();
    d.modifierProduit('C4', 'C4-sucre', nom: 'Sucre 50 kg', unite: 'sacs', quantite: 800, prix: 450000, icone: IconeProduit.sucre);
    expect(d.suivi.conteneur('C4').produits[0].stock, 800 - 470);
    // Le prix des factures déjà faites ne change pas.
    expect(d.suivi.facture('FAC-2026-013').total, 200 * 420000);
    expect(() => d.supprimerProduit('C4', 'C4-sucre'), throwsStateError);
    final p = d.ajouterProduit('C4', nom: 'Thé', unite: 'cartons', quantite: 10, prix: 1, icone: IconeProduit.carton);
    d.supprimerProduit('C4', p);
    expect(d.suivi.conteneur('C4').produits.length, 2);
  });

  test('modifier un client, supprimer seulement sans facture', () {
    final d = nouveau();
    d.modifierClient('k1', nom: 'El Hadj M. Bah', quartier: 'Madina', limiteCredit: 10);
    expect(d.suivi.client('k1').client.nom, 'El Hadj M. Bah');
    expect(d.suivi.client('k1').depasseLimite, isTrue);
    expect(() => d.supprimerClient('k1'), throwsStateError);
    final k = d.ajouterClient(nom: 'Nouveau', quartier: 'Q', limiteCredit: 0);
    d.supprimerClient(k);
    expect(d.suivi.clients.length, 7);
  });

  test('modifier une facture, la supprimer avec ses paiements et retours', () {
    final d = nouveau();
    d.modifierFacture('FAC-2026-012', clientId: 'k7', date: DateTime(2026, 9, 16), lignes: const [
      LigneFacture(conteneurId: 'C3', produitId: 'C3-pneus', quantite: 100, prix: 160000),
    ]);
    expect(d.suivi.facture('FAC-2026-012').total, 16000000);
    expect(d.suivi.facture('FAC-2026-012').facture.clientId, 'k7');
    expect(d.lignesBloquees('FAC-2026-005'), isTrue);
    expect(d.lignesBloquees('FAC-2026-012'), isFalse);

    final paiements = d.donnees.paiements.length;
    d.supprimerFacture('FAC-2026-011'); // 1 paiement, 1 retour
    expect(d.donnees.paiements.length, paiements - 1);
    expect(d.donnees.avoirs.map((a) => a.numero), isNot(contains('AV-2026-002')));
    expect(d.suivi.factures.length, 15);
  });

  test('modifier et supprimer un paiement, un retour', () {
    final d = nouveau();
    final p = d.donnees.paiements.firstWhere((p) => p.facture == 'FAC-2026-008');
    final rang = d.rangPaiement(p);
    d.modifierPaiement(rang, Paiement(facture: p.facture, date: p.date, montant: 1000000, mode: ModePaiement.especes));
    expect(d.suivi.facture('FAC-2026-008').paye, 1000000);
    d.supprimerPaiement(rang);
    expect(d.suivi.facture('FAC-2026-008').paye, 0);

    d.modifierAvoir('AV-2026-001', quantite: 10, type: TypeAvoir.remisEnStock, date: DateTime(2026, 8, 4), motif: 'x');
    expect(d.suivi.facture('FAC-2026-005').solde, 78000000 - 3900000);
    d.supprimerAvoir('AV-2026-001');
    expect(d.suivi.facture('FAC-2026-005').solde, 78000000);
  });
}
