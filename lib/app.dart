import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'domaine/calculs.dart';
import 'ui/coquille.dart';
import 'ui/ecrans/a_venir.dart';
import 'ui/ecrans/accueil.dart';
import 'ui/ecrans/conteneurs.dart';
import 'ui/suivi_scope.dart';
import 'ui/theme.dart';

GoRouter creerRouteur() => GoRouter(routes: [
      ShellRoute(
        builder: (context, state, enfant) => Coquille(chemin: state.uri.path, enfant: enfant),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const EcranAccueil()),
          GoRoute(path: '/conteneurs', builder: (_, _) => const EcranConteneurs()),
          GoRoute(
            path: '/clients',
            builder: (_, _) => const EcranAVenir(titre: 'Clients', icone: Icons.storefront_outlined, contenu: [
              'la liste des commerçants, ce qu\'ils ont acheté, payé et ce qu\'ils doivent encore ;',
              'les conteneurs dont chacun a reçu des produits ;',
              'une alerte quand un client dépasse sa limite de crédit.',
            ]),
          ),
          GoRoute(
            path: '/factures',
            builder: (_, _) => const EcranAVenir(titre: 'Factures', icone: Icons.receipt_long_outlined, contenu: [
              'les factures, avec pour chaque ligne le conteneur d\'où vient le produit ;',
              'les paiements reçus, en une ou plusieurs fois, et le solde ;',
              'les retours et remises (avoirs).',
            ]),
          ),
          GoRoute(
            path: '/rapports',
            builder: (_, _) => const EcranAVenir(titre: 'Rapports', icone: Icons.bar_chart_outlined, contenu: [
              'les impayés selon leur ancienneté ;',
              'les meilleurs clients et les meilleurs produits ;',
              'le résultat de chaque conteneur.',
            ]),
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
          title: 'Suivi des conteneurs',
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
