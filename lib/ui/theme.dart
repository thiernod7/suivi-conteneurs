import 'package:flutter/material.dart';

import '../domaine/calculs.dart';

// Style : fond clair, cartes blanches bordées d'un trait fin, icônes fines,
// une couleur par conteneur, trois couleurs de statut toujours accompagnées d'une icône.

class Couleurs extends ThemeExtension<Couleurs> {
  const Couleurs({
    required this.conteneurs,
    required this.ok,
    required this.attention,
    required this.alerte,
    required this.trait,
    required this.muet,
  });

  final List<Color> conteneurs;
  final Color ok;
  final Color attention;
  final Color alerte;

  /// Traits fins : bordures, séparateurs.
  final Color trait;

  /// Texte secondaire.
  final Color muet;

  Color conteneur(int rang) => conteneurs[rang % conteneurs.length];

  Color statut(StatutPaiement s) => switch (s) {
        StatutPaiement.solde => ok,
        StatutPaiement.partiel => attention,
        StatutPaiement.impaye => alerte,
      };

  static const clair = Couleurs(
    conteneurs: [Color(0xFFD0603A), Color(0xFF1F8A70), Color(0xFFC6901F), Color(0xFF4565B0)],
    ok: Color(0xFF1C8046),
    attention: Color(0xFFB06D00),
    alerte: Color(0xFFC8372D),
    trait: Color(0xFFE3E6EA),
    muet: Color(0xFF6B7480),
  );

  static const sombre = Couleurs(
    conteneurs: [Color(0xFFE5764F), Color(0xFF3DB08F), Color(0xFFE2AE45), Color(0xFF7090DA)],
    ok: Color(0xFF5BC782),
    attention: Color(0xFFF2B24C),
    alerte: Color(0xFFFF7B70),
    trait: Color(0xFF2A3038),
    muet: Color(0xFF9AA3AE),
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
  final c = sombre ? Couleurs.sombre : Couleurs.clair;
  final fond = sombre ? const Color(0xFF0F1215) : const Color(0xFFF6F7F9);
  final surface = sombre ? const Color(0xFF171B20) : Colors.white;
  final encre = sombre ? const Color(0xFFE8ECF0) : const Color(0xFF161B22);
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1D5C8C),
    brightness: luminosite,
    surface: surface,
    onSurface: encre,
    onSurfaceVariant: c.muet,
    outline: c.trait,
    outlineVariant: c.trait,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Lisible');
  final trait = BorderSide(color: c.trait, width: .8);
  return base.copyWith(
    scaffoldBackgroundColor: fond,
    textTheme: Typography.englishLike2021.merge(base.textTheme).apply(fontSizeFactor: 1.06),
    iconTheme: IconThemeData(weight: 300, color: encre, size: 24),
    dividerTheme: DividerThemeData(color: c.trait, thickness: .8, space: 1),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: trait),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: fond,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(weight: 300, color: encre),
      titleTextStyle: TextStyle(fontFamily: 'Lisible', fontSize: 22, fontWeight: FontWeight.w600, color: encre),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: .1),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: 'Lisible',
            fontSize: 13,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? encre : c.muet,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: scheme.primary.withValues(alpha: .1),
      selectedLabelTextStyle: TextStyle(fontFamily: 'Lisible', fontWeight: FontWeight.w600, color: encre),
      unselectedLabelTextStyle: TextStyle(fontFamily: 'Lisible', color: c.muet),
    ),
    chipTheme: ChipThemeData(
      side: trait,
      backgroundColor: surface,
      selectedColor: scheme.primary.withValues(alpha: .1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      labelStyle: TextStyle(fontFamily: 'Lisible', fontSize: 15, color: encre),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: trait),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: trait),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.primary, width: 1.2)),
      hintStyle: TextStyle(color: c.muet),
    ),
    extensions: [c],
  );
}
