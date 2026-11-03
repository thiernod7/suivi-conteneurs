import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suivi_conteneurs/app.dart';
import 'package:suivi_conteneurs/donnees/depot.dart';
import 'package:suivi_conteneurs/donnees/exemple.dart';
import 'package:suivi_conteneurs/ui/format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    final police = FontLoader('Lisible');
    for (final f in ['Light', 'Regular', 'Medium', 'SemiBold']) {
      police.addFont(rootBundle.load('assets/fonts/Lexend-$f.ttf'));
    }
    await police.load();
  });

  late Depot depot;

  Future<void> ouvrir(WidgetTester tester, {Size taille = const Size(390, 844)}) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    depot = Depot(donneesExemple, aujourdhui: aujourdhuiExemple);
    await tester.pumpWidget(Application(depot: depot));
    await tester.pumpAndSettle();
  }

  Future<void> aller(WidgetTester tester, String onglet) async {
    await tester.tap(find.text(onglet).last);
    await tester.pumpAndSettle();
  }

  // Comme une personne : on fait venir l'élément au milieu de l'écran, puis on touche.
  Future<void> montrer(WidgetTester tester, Finder f) async {
    final element = tester.element(f);
    if (Scrollable.maybeOf(element) != null) {
      Scrollable.ensureVisible(element, alignment: .5);
      await tester.pumpAndSettle();
    }
  }

  Future<void> toucher(WidgetTester tester, Finder f) async {
    await montrer(tester, f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> ecrire(WidgetTester tester, String libelle, String texte) async {
    final champ = find.widgetWithText(TextFormField, libelle);
    await montrer(tester, champ);
    await tester.enterText(champ, texte);
    await tester.pumpAndSettle();
  }

  Future<void> enregistrer(WidgetTester tester) => toucher(tester, find.text('Enregistrer'));

  testWidgets('la barre du bas a un bouton Plus, qui ouvre ses écrans', (tester) async {
    await ouvrir(tester);
    await aller(tester, 'Plus');
    for (final ecran in ['Produits', 'Paiements', 'Retours', 'Fournisseurs']) {
      await toucher(tester, find.text(ecran));
      expect(find.text(ecran), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    expect(find.text('Remettre les exemples'), findsOneWidget);
  });

  testWidgets('nouveau client', (tester) async {
    await ouvrir(tester);
    await aller(tester, 'Clients');
    await toucher(tester, find.text('Nouveau client'));
    await enregistrer(tester);
    expect(find.text('Obligatoire'), findsNWidgets(3));
    await ecrire(tester, 'Nom', 'Kadiatou Sylla');
    await ecrire(tester, 'Quartier ou marché', 'Taouyah');
    await ecrire(tester, 'Limite', '50000000');
    expect(find.text(nombre(50000000)), findsOneWidget);
    await enregistrer(tester);
    expect(find.text('Kadiatou Sylla'), findsWidgets);
    expect(depot.suivi.clients.last.client.limiteCredit, 50000000);
  });

  testWidgets('nouvelle facture depuis un client, stock contrôlé, payée tout de suite', (tester) async {
    await ouvrir(tester);
    await aller(tester, 'Clients');
    await toucher(tester, find.text('Ibrahima Sow'));
    await toucher(tester, find.text('Nouvelle facture'));
    expect(find.text('Ibrahima Sow'), findsOneWidget);
    await toucher(tester, find.text('Produit'));
    await toucher(tester, find.text('Sucre 50 kg'));
    expect(find.text(nombre(420000)), findsOneWidget);
    await ecrire(tester, 'Quantité', '300');
    await enregistrer(tester);
    expect(find.text('Il reste 230'), findsOneWidget);
    await ecrire(tester, 'Quantité', '10');
    await toucher(tester, find.text('Tout'));
    await toucher(tester, find.text('Orange Money'));
    await enregistrer(tester);
    expect(find.text('Facture 2026-017'), findsOneWidget);
    expect(find.text('Payé'), findsWidgets);
    expect(depot.suivi.conteneur('C4').produits[0].stock, 220);
  });

  testWidgets('paiement depuis une facture : « Tout payé »', (tester) async {
    await ouvrir(tester);
    await aller(tester, 'Factures');
    await tester.enterText(find.byType(TextField), '2026-005');
    await tester.pumpAndSettle();
    await toucher(tester, find.textContaining('2026-005').last);
    await toucher(tester, find.text('Ajouter un paiement'));
    await ecrire(tester, 'Reçu', '999999999');
    await enregistrer(tester);
    expect(find.textContaining('Il reste'), findsOneWidget);
    await toucher(tester, find.text('Tout payé'));
    await enregistrer(tester);
    expect(find.text('Ajouter un paiement'), findsNothing);
    expect(depot.suivi.facture('FAC-2026-005').solde, 0);
  });

  testWidgets('nouveau conteneur, puis un produit dedans', (tester) async {
    await ouvrir(tester, taille: const Size(1280, 900));
    await aller(tester, 'Conteneurs');
    await toucher(tester, find.text('Nouveau conteneur'));
    await ecrire(tester, 'Numéro', 'MDNU 482113 0');
    await ecrire(tester, 'Pays', 'Anvers, Belgique');
    await enregistrer(tester);
    expect(find.text('Déjà enregistré'), findsOneWidget);
    await ecrire(tester, 'Numéro', 'mscu1234567');
    await ecrire(tester, 'Fournisseur', 'Anvers Trading');
    await ecrire(tester, 'Achat', '100000000');
    await ecrire(tester, 'Bateau (fret)', '20000000');
    expect(find.textContaining('120,0 M', findRichText: true), findsOneWidget);
    await enregistrer(tester);
    expect(find.text('Conteneur 123456'), findsOneWidget);
    await toucher(tester, find.text('Ajouter un produit'));
    await toucher(tester, find.byTooltip('Pneus'));
    await ecrire(tester, 'Quantité reçue', '200');
    await ecrire(tester, 'Prix pour 1 sac', '150000');
    await enregistrer(tester);
    expect(find.text('Pneus'), findsOneWidget);
    expect(find.text('Vendu 0 / 200'), findsOneWidget);
  });

  testWidgets('retour depuis une facture', (tester) async {
    await ouvrir(tester);
    await aller(tester, 'Factures');
    await tester.enterText(find.byType(TextField), '2026-016');
    await tester.pumpAndSettle();
    await toucher(tester, find.textContaining('2026-016').last);
    await toucher(tester, find.text('Retour'));
    await toucher(tester, find.text('Produit'));
    await toucher(tester, find.text('Lait en poudre'));
    await ecrire(tester, 'Quantité', '5');
    await ecrire(tester, 'Pourquoi ?', 'Cartons en trop');
    await enregistrer(tester);
    expect(find.text('Rendus 5'), findsOneWidget);
    expect(depot.suivi.facture('FAC-2026-016').solde, 75 * 260000);
  });

  testWidgets('formulaire de facture en grand texte (+30 %) : rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ouvrir(tester, taille: const Size(360, 780));
    await aller(tester, 'Factures');
    await toucher(tester, find.text('Nouvelle facture'));
    await toucher(tester, find.text('Client'));
    await toucher(tester, find.text('Mariama Diallo'));
    await toucher(tester, find.text('Produit'));
    await toucher(tester, find.text('Batteries 12 V'));
    await toucher(tester, find.text('Ajouter un produit'));
    await ecrire(tester, 'Reçu', '1000');
    expect(tester.takeException(), isNull);
  });
}
