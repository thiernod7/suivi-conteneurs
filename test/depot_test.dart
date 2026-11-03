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
}
