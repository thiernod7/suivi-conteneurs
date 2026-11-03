import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'donnees/depot.dart';
import 'ui/coquille.dart';
import 'ui/ecrans/accueil.dart';
import 'ui/ecrans/client.dart';
import 'ui/ecrans/clients.dart';
import 'ui/ecrans/conteneur.dart';
import 'ui/ecrans/conteneurs.dart';
import 'ui/ecrans/facture.dart';
import 'ui/ecrans/fournisseurs.dart';
import 'ui/ecrans/paiements.dart';
import 'ui/ecrans/produits.dart';
import 'ui/ecrans/retours.dart';
import 'ui/formulaires/client.dart';
import 'ui/formulaires/conteneur.dart';
import 'ui/formulaires/facture.dart';
import 'ui/formulaires/paiement.dart';
import 'ui/formulaires/produit.dart';
import 'ui/formulaires/retour.dart';
import 'ui/ecrans/factures.dart';
import 'ui/suivi_scope.dart';
import 'ui/theme.dart';

GoRouter creerRouteur() => GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, enfant) => Coquille(chemin: state.uri.path, enfant: enfant),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const EcranAccueil()),
        GoRoute(
          path: '/conteneurs',
          builder: (_, _) => const EcranConteneurs(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => EcranConteneur(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/clients',
          builder: (_, _) => const EcranClients(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => EcranClient(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/factures',
          builder: (_, _) => const EcranFactures(),
          routes: [
            GoRoute(
              path: ':numero',
              builder: (_, state) => EcranFacture(numero: state.pathParameters['numero']!),
            ),
          ],
        ),
        // Les écrans du menu « Plus ».
        GoRoute(path: '/produits', builder: (_, _) => const EcranProduits()),
        GoRoute(path: '/paiements', builder: (_, _) => const EcranPaiements()),
        GoRoute(path: '/retours', builder: (_, _) => const EcranRetours()),
        GoRoute(path: '/fournisseurs', builder: (_, _) => const EcranFournisseurs()),
      ],
    ),
    // Les formulaires d'ajout s'ouvrent en plein écran, par-dessus la barre du bas.
    GoRoute(path: '/nouveau/conteneur', builder: (_, _) => const FormulaireConteneur()),
    GoRoute(path: '/nouveau/client', builder: (_, _) => const FormulaireClient()),
    GoRoute(
      path: '/nouveau/produit',
      builder: (_, state) => FormulaireProduit(conteneurId: state.uri.queryParameters['conteneur']),
    ),
    GoRoute(
      path: '/nouveau/facture',
      builder: (_, state) => FormulaireFacture(clientId: state.uri.queryParameters['client']),
    ),
    GoRoute(
      path: '/nouveau/paiement',
      builder: (_, state) => FormulairePaiement(facture: state.uri.queryParameters['facture']),
    ),
    GoRoute(
      path: '/nouveau/retour',
      builder: (_, state) => FormulaireRetour(facture: state.uri.queryParameters['facture']),
    ),
    // Les mêmes formulaires, déjà remplis, pour modifier (et supprimer).
    GoRoute(
      path: '/modifier/conteneur',
      builder: (_, state) => FormulaireConteneur(id: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/modifier/client',
      builder: (_, state) => FormulaireClient(id: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/modifier/produit',
      builder: (_, state) => FormulaireProduit(
        conteneurId: state.uri.queryParameters['conteneur'],
        produitId: state.uri.queryParameters['produit'],
      ),
    ),
    GoRoute(
      path: '/modifier/facture',
      builder: (_, state) => FormulaireFacture(numero: state.uri.queryParameters['numero']),
    ),
    GoRoute(
      path: '/modifier/paiement',
      builder: (_, state) => FormulairePaiement(rang: int.tryParse(state.uri.queryParameters['rang'] ?? '')),
    ),
    GoRoute(
      path: '/modifier/retour',
      builder: (_, state) => FormulaireRetour(numero: state.uri.queryParameters['numero']),
    ),
  ],
);

class Application extends StatefulWidget {
  const Application({super.key, required this.depot});

  final Depot depot;

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  final _routeur = creerRouteur();

  @override
  Widget build(BuildContext context) => SuiviScope(
    depot: widget.depot,
    child: ListenableBuilder(
      listenable: widget.depot,
      builder: (context, _) => MaterialApp.router(
        title: 'Mes conteneurs',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        themeMode: widget.depot.modeTheme,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _routeur,
      ),
    ),
  );
}
