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

  testWidgets('clients : chercher un nom et filtrer', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    expect(find.text('Tous  7'), findsOneWidget);
    await tester.tap(find.text('Payé  2'));
    await tester.pumpAndSettle();
    expect(find.text('Ibrahima Sow'), findsOneWidget);
    expect(find.text('Mariama Diallo'), findsNothing);
    await tester.tap(find.text('Tous  7'));
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
}
