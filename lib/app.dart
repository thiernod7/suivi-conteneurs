import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'domaine/calculs.dart';
import 'ui/coquille.dart';
import 'ui/ecrans/accueil.dart';
import 'ui/ecrans/client.dart';
import 'ui/ecrans/clients.dart';
import 'ui/ecrans/conteneur.dart';
import 'ui/ecrans/conteneurs.dart';
import 'ui/ecrans/facture.dart';
import 'ui/ecrans/factures.dart';
import 'ui/suivi_scope.dart';
import 'ui/theme.dart';

GoRouter creerRouteur() => GoRouter(routes: [
      ShellRoute(
        builder: (context, state, enfant) => Coquille(chemin: state.uri.path, enfant: enfant),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const EcranAccueil()),
          GoRoute(
            path: '/conteneurs',
            builder: (_, _) => const EcranConteneurs(),
            routes: [
              GoRoute(path: ':id', builder: (_, state) => EcranConteneur(id: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (_, _) => const EcranClients(),
            routes: [
              GoRoute(path: ':id', builder: (_, state) => EcranClient(id: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/factures',
            builder: (_, _) => const EcranFactures(),
            routes: [
              GoRoute(path: ':numero', builder: (_, state) => EcranFacture(numero: state.pathParameters['numero']!)),
            ],
          ),
        ],
      ),
    ]);

class Application extends StatefulWidget {
  const Application({super.key, required this.suivi});

  final Suivi suivi;

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  final _routeur = creerRouteur();

  @override
  Widget build(BuildContext context) => SuiviScope(
        suivi: widget.suivi,
        child: MaterialApp.router(
          title: 'Mes conteneurs',
          debugShowCheckedModeBanner: false,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _routeur,
        ),
      );
}
