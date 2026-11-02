import 'package:flutter/material.dart';

import '../domaine/calculs.dart';

// Couleurs de l'application : une couleur par conteneur, des couleurs de statut,
// et le décor du port (mer, coque, quai).

class Couleurs extends ThemeExtension<Couleurs> {
  const Couleurs({
    required this.conteneurs,
    required this.ok,
    required this.attention,
    required this.alerte,
    required this.okFond,
    required this.attentionFond,
    required this.alerteFond,
    required this.mer,
    required this.vague,
    required this.coque,
    required this.quai,
    required this.ciel,
  });

  final List<Color> conteneurs;
  final Color ok;
  final Color attention;
  final Color alerte;
  final Color okFond;
  final Color attentionFond;
  final Color alerteFond;
  final Color mer;
  final Color vague;
  final Color coque;
  final Color quai;
  final Color ciel;

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
    conteneurs: [Color(0xFFC4532D), Color(0xFF2C7D69), Color(0xFFC98F1E), Color(0xFF3B5A9C)],
    ok: Color(0xFF2E8549),
    attention: Color(0xFFA9740C),
    alerte: Color(0xFFC0392B),
    okFond: Color(0xFFE2F1E6),
    attentionFond: Color(0xFFF7EDD6),
    alerteFond: Color(0xFFF8E2DF),
    mer: Color(0xFF245A78),
    vague: Color(0xFF3A7598),
    coque: Color(0xFF1B2A35),
    quai: Color(0xFFC7CED3),
    ciel: Color(0xFFE3E8EB),
  );

  static const sombre = Couleurs(
    conteneurs: [Color(0xFFDA6440), Color(0xFF3A9A82), Color(0xFFDCA332), Color(0xFF5C7CC2)],
    ok: Color(0xFF53B26D),
    attention: Color(0xFFE0A93A),
    alerte: Color(0xFFE8685A),
    okFond: Color(0xFF16301F),
    attentionFond: Color(0xFF33290F),
    alerteFond: Color(0xFF3A1A17),
    mer: Color(0xFF123247),
    vague: Color(0xFF1B4660),
    coque: Color(0xFF05090C),
    quai: Color(0xFF2C3943),
    ciel: Color(0xFF121D24),
  );

  @override
  Couleurs copyWith() => this;

  @override
  Couleurs lerp(Couleurs? other, double t) => t < .5 || other == null ? this : other;
}

extension CouleursContexte on BuildContext {
  Couleurs get couleurs => Theme.of(this).extension<Couleurs>()!;
}

const policeTitre = 'BigShoulders';
const policeTexte = 'Plex';
const policeNumero = 'PlexMono';

ThemeData theme(Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF245A78),
    brightness: luminosite,
    surface: sombre ? const Color(0xFF162129) : Colors.white,
    onSurface: sombre ? const Color(0xFFE2E9EE) : const Color(0xFF14212B),
    onSurfaceVariant: sombre ? const Color(0xFF93A3AE) : const Color(0xFF5A6A75),
    outlineVariant: sombre ? const Color(0xFF29363F) : const Color(0xFFD2D9DE),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: policeTexte);
  TextStyle titre(double taille) =>
      TextStyle(fontFamily: policeTitre, fontWeight: FontWeight.w700, fontSize: taille, letterSpacing: .3, height: 1.05);
  return base.copyWith(
    scaffoldBackgroundColor: sombre ? const Color(0xFF0E161C) : const Color(0xFFECEFF1),
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall!.merge(titre(40).copyWith(fontWeight: FontWeight.w800)),
      headlineSmall: base.textTheme.headlineSmall!.merge(titre(26)),
      titleLarge: base.textTheme.titleLarge!.merge(titre(22)),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    extensions: [sombre ? Couleurs.sombre : Couleurs.clair],
  );
}
