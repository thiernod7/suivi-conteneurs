import 'package:flutter/material.dart';

import '../domaine/calculs.dart';

// Couleurs de l'application : une couleur par conteneur, et trois couleurs de statut
// toujours accompagnées d'une icône (on ne compte pas sur la couleur seule).

class Couleurs extends ThemeExtension<Couleurs> {
  const Couleurs({
    required this.conteneurs,
    required this.ok,
    required this.attention,
    required this.alerte,
    required this.okFond,
    required this.attentionFond,
    required this.alerteFond,
  });

  final List<Color> conteneurs;
  final Color ok;
  final Color attention;
  final Color alerte;
  final Color okFond;
  final Color attentionFond;
  final Color alerteFond;

  Color conteneur(int rang) => conteneurs[rang % conteneurs.length];

  Color statut(StatutPaiement s) => switch (s) {
        StatutPaiement.solde => ok,
        StatutPaiement.partiel => attention,
        StatutPaiement.impaye => alerte,
      };

  Color statutFond(StatutPaiement s) => switch (s) {
        StatutPaiement.solde => okFond,
        StatutPaiement.partiel => attentionFond,
        StatutPaiement.impaye => alerteFond,
      };

  static const clair = Couleurs(
    conteneurs: [Color(0xFFC4532D), Color(0xFF1F7A63), Color(0xFFB7831A), Color(0xFF3B5A9C)],
    ok: Color(0xFF1E7B3C),
    attention: Color(0xFF9A6200),
    alerte: Color(0xFFB3261E),
    okFond: Color(0xFFDDF0E2),
    attentionFond: Color(0xFFFBEBCB),
    alerteFond: Color(0xFFF9DEDC),
  );

  static const sombre = Couleurs(
    conteneurs: [Color(0xFFE06C47), Color(0xFF3DA88C), Color(0xFFE0AA3E), Color(0xFF6C8BD0)],
    ok: Color(0xFF6CCB86),
    attention: Color(0xFFF0B54A),
    alerte: Color(0xFFFF8A80),
    okFond: Color(0xFF173322),
    attentionFond: Color(0xFF3A2C0E),
    alerteFond: Color(0xFF431D1A),
  );

  @override
  Couleurs copyWith() => this;

  @override
  Couleurs lerp(Couleurs? other, double t) => t < .5 || other == null ? this : other;
}

extension CouleursContexte on BuildContext {
  Couleurs get couleurs => Theme.of(this).extension<Couleurs>()!;
}

ThemeData theme(Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F5F8B),
    brightness: luminosite,
    surface: sombre ? const Color(0xFF1A1F24) : Colors.white,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Lisible');
  return base.copyWith(
    scaffoldBackgroundColor: sombre ? const Color(0xFF111417) : const Color(0xFFF2F4F6),
    // Texte un peu plus grand que d'habitude.
    textTheme: Typography.englishLike2021.merge(base.textTheme).apply(fontSizeFactor: 1.08),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Lisible', fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700)),
    ),
    extensions: [sombre ? Couleurs.sombre : Couleurs.clair],
  );
}
