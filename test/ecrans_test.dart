import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suivi_conteneurs/app.dart';
import 'package:suivi_conteneurs/domaine/calculs.dart';
import 'package:suivi_conteneurs/donnees/exemple.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  Future<void> ouvrir(WidgetTester tester, Size taille) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Application(suivi: Suivi(donneesExemple, aujourdhuiExemple)));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('accueil sur ordinateur : rail, totaux et conteneurs', (tester) async {
    await ouvrir(tester, const Size(1400, 1000));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('INVESTI'), findsOneWidget);
    expect(find.text('1,07 Md'), findsOneWidget);
    expect(find.text('MDNU 640055 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil sur téléphone : barre en bas, sans débordement', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation vers Conteneurs puis Factures', (tester) async {
    await ouvrir(tester, const Size(390, 844));
    await tester.tap(find.text('Conteneurs').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CONTENEURS'), findsOneWidget);
    await tester.tap(find.text('Factures').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Écran en préparation'), findsOneWidget);
  });
}
