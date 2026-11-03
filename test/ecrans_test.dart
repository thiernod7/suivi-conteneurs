import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suivi_conteneurs/app.dart';
import 'package:suivi_conteneurs/domaine/calculs.dart';
import 'package:suivi_conteneurs/donnees/exemple.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    // La vraie police, pour que les tests mesurent les textes comme sur l'écran.
    final police = FontLoader('Lisible')
      ..addFont(rootBundle.load('assets/fonts/Lexend-Light.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Lexend-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Lexend-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Lexend-SemiBold.ttf'));
    await police.load();
  });

  Future<void> ouvrir(WidgetTester tester, Size taille) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Application(suivi: Suivi(donneesExemple, aujourdhuiExemple)));
    await tester.pumpAndSettle();
  }

  testWidgets('accueil sur ordinateur : rail, chiffres clés, conteneurs', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Perdu'), findsWidgets);
    expect(find.text('On me doit'), findsOneWidget);
    expect(find.text('Qui me doit ?'), findsOneWidget);
    expect(find.text('640055'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil sur téléphone : barre en bas, sans débordement', (tester) async {
    await ouvrir(tester, const Size(360, 780));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('texte agrandi sur le téléphone (+30 %) : rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ouvrir(tester, const Size(360, 780));
    await tester.scrollUntilVisible(find.text('482113'), 300);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('482113'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Mariama Diallo'), 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ouvrir un conteneur puis revenir', (tester) async {
    await ouvrir(tester, const Size(360, 780));
    await tester.tap(find.text('Conteneurs').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('482113'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.tap(find.text('482113'));
    await tester.pumpAndSettle();
    expect(find.text('Conteneur 482113'), findsOneWidget);
    expect(find.text('Dedans'), findsOneWidget);
    expect(find.text('Vendu 270 / 300'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mariama Diallo'), 200);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Conteneur 482113'), findsNothing);
  });

  Future<void> ouvrirFiltres(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filtres'));
    await tester.pumpAndSettle();
  }

  Future<void> voirResultats(WidgetTester tester) async {
    await tester.tap(find.textContaining('Voir les résultats'));
    await tester.pumpAndSettle();
  }

  testWidgets('clients : chercher un nom et filtrer', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('Filtres'), findsOneWidget);
    expect(find.text('Tous  7'), findsOneWidget);
    await tester.tap(find.text('Payé  2'));
    await tester.pumpAndSettle();
    expect(find.text('Voir les résultats · 2'), findsOneWidget);
    await voirResultats(tester);
    expect(find.text('Ibrahima Sow'), findsOneWidget);
    expect(find.text('Mariama Diallo'), findsNothing);
    // Le filtre actif s'affiche sous la recherche ; sa croix l'enlève.
    await tester.tap(find.byTooltip('Enlever'));
    await tester.pumpAndSettle();
    expect(find.text('Mariama Diallo'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'keita');
    await tester.pumpAndSettle();
    expect(find.text('Moussa Keïta'), findsOneWidget);
    expect(find.text('Fatoumata Camara'), findsNothing);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Personne'), findsOneWidget);
  });

  testWidgets('un client : limite dépassée, ses conteneurs, ses factures', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatoumata Camara'));
    await tester.pumpAndSettle();
    expect(find.text('Limite dépassée'), findsOneWidget);
    expect(find.text('Me doit'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2026-008'), 300,
        scrollable: find.byType(Scrollable).hitTestable().first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('client avec un crédit : « Je lui dois »', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ibrahima Sow'));
    await tester.pumpAndSettle();
    expect(find.text('Je lui dois'), findsOneWidget);
    expect(find.textContaining('2,1 M', findRichText: true), findsOneWidget);
  });

  testWidgets('clients en grand texte (+30 %) : rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ouvrir(tester, const Size(360, 780));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('El Hadj Mamadou Bah'), 200,
        scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.tap(find.text('El Hadj Mamadou Bah'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('2026-001'), 300,
        scrollable: find.byType(Scrollable).hitTestable().first);
    expect(tester.takeException(), isNull);
  });

  Future<void> ouvrirFacture(WidgetTester tester, String numero, {Size taille = const Size(390, 844)}) async {
    await ouvrir(tester, taille);
    await tester.tap(find.text('Factures').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), numero);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(numero).last);
    await tester.pumpAndSettle();
  }

  testWidgets('factures : filtres et recherche', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    await tester.tap(find.text('Factures').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('Toutes  16'), findsOneWidget);
    expect(find.text('À payer  10'), findsOneWidget);
    await tester.tap(find.text('Payé  6'));
    await tester.pumpAndSettle();
    await voirResultats(tester);
    expect(find.text('Mariama Diallo'), findsNothing);
    // « Réinitialiser » dans le panneau remet tout.
    await ouvrirFiltres(tester);
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
    expect(find.text('Voir les résultats · 16'), findsOneWidget);
    await voirResultats(tester);
    await tester.enterText(find.byType(TextField), 'mariama');
    await tester.pumpAndSettle();
    expect(find.text('Mariama Diallo'), findsNWidgets(3));
  });

  testWidgets('facture à deux conteneurs, payée en partie', (tester) async {
    await ouvrirFacture(tester, '2026-008');
    expect(find.text('Facture 2026-008'), findsOneWidget);
    expect(find.text('Fatoumata Camara'), findsOneWidget);
    expect(find.text('À payer'), findsNWidgets(2));
    expect(find.textContaining('26,0 M', findRichText: true), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Orange Money'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
    expect(find.text('Huile végétale 20 L'), findsOneWidget);
    expect(find.text('Tomate concentrée'), findsOneWidget);
  });

  testWidgets('facture avec retour, rien reçu', (tester) async {
    await ouvrirFacture(tester, '2026-005');
    expect(find.text('Retours'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rien reçu'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
    expect(find.text('Rendus 20'), findsOneWidget);
  });

  testWidgets('facture payée avant un retour : « Je lui dois »', (tester) async {
    await ouvrirFacture(tester, '2026-011', taille: const Size(1400, 1000));
    expect(find.text('Je lui dois'), findsOneWidget);
    expect(find.text('Rendus · abîmés 10'), findsOneWidget);
  });

  testWidgets('factures en grand texte (+30 %) : rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ouvrir(tester, const Size(360, 780));
    await tester.tap(find.text('Factures').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), '2026-013');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('2026-013').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Espèces'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conteneurs : chercher un produit, filtrer, tout revoir', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    await tester.tap(find.text('Conteneurs').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('En vente  1'), findsOneWidget);
    expect(find.text('Tout vendu  3'), findsOneWidget);
    await voirResultats(tester);
    await tester.enterText(find.byType(TextField), 'riz');
    await tester.pumpAndSettle();
    expect(find.text('482113'), findsOneWidget);
    expect(find.text('640055'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Rien'), findsOneWidget);
    await tester.tap(find.text('Tout voir'));
    await tester.pumpAndSettle();
    expect(find.text('640055'), findsOneWidget);
    await ouvrirFiltres(tester);
    await tester.tap(find.text('En vente  1'));
    await tester.pumpAndSettle();
    await voirResultats(tester);
    expect(find.text('482113'), findsNothing);
    expect(find.widgetWithText(InputChip, 'En vente'), findsOneWidget);
  });

  testWidgets('clients : filtre par conteneur et limite dépassée', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('Limite dépassée  2'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '603218'));
    await tester.pumpAndSettle();
    expect(find.text('Tous  3'), findsOneWidget);
    // Toucher encore le conteneur l'enlève.
    await tester.tap(find.widgetWithText(ChoiceChip, '603218'));
    await tester.pumpAndSettle();
    expect(find.text('Tous  7'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '603218'));
    await tester.pumpAndSettle();
    await voirResultats(tester);
    expect(find.text('Ibrahima Sow'), findsOneWidget);
    expect(find.text('Fatoumata Camara'), findsNothing);
  });

  testWidgets('factures : en retard, par produit, par conteneur', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    await tester.tap(find.text('Factures').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('En retard  6'), findsOneWidget);
    await voirResultats(tester);
    await tester.enterText(find.byType(TextField), 'sucre');
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    expect(find.text('Toutes  3'), findsOneWidget);
    await voirResultats(tester);
    await tester.tap(find.byTooltip('Effacer'));
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '517390'));
    await tester.pumpAndSettle();
    expect(find.text('Toutes  4'), findsOneWidget);
    await voirResultats(tester);
    expect(find.widgetWithText(InputChip, '517390'), findsOneWidget);
  });

  testWidgets('panneau des filtres en grand texte (+30 %) : rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ouvrir(tester, const Size(360, 780));
    await tester.tap(find.text('Factures').last);
    await tester.pumpAndSettle();
    await ouvrirFiltres(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '640055'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await voirResultats(tester);
    expect(tester.takeException(), isNull);
  });
}
