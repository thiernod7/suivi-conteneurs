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
      ..addFont(rootBundle.load('assets/fonts/Lexend-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Lexend-Bold.ttf'));
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
}
