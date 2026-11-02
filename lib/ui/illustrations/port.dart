import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Scène du port de Conakry : le navire accoste, les conteneurs sont sur le quai,
/// des camions de la couleur des conteneurs partent vers les boutiques de Madina.
///
/// Dessinée sur un plan de 1000 × 300, mise à l'échelle par la hauteur :
/// sur un écran étroit, on voit la mer et le port, et le marché sort à droite.
class ScenePort extends StatefulWidget {
  const ScenePort({super.key, required this.nombreConteneurs});

  final int nombreConteneurs;

  @override
  State<ScenePort> createState() => _ScenePortState();
}

class _ScenePortState extends State<ScenePort> with TickerProviderStateMixin {
  late final _arrivee = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final _camions = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _arrivee.value = 1;
      _camions.stop();
    } else if (!_arrivee.isAnimating && _arrivee.value == 0) {
      _arrivee.forward().whenComplete(_camions.repeat);
    }
  }

  @override
  void dispose() {
    _arrivee.dispose();
    _camions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(
          fontFamily: policeTitre,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 1.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Semantics(
      image: true,
      label: 'Illustration : un navire accoste au port de Conakry, ses conteneurs partent en camion vers le marché de Madina.',
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, c) {
          final hauteur = (c.maxWidth * .3).clamp(150.0, 300.0);
          return ClipRect(
            child: SizedBox(
              height: hauteur,
              width: c.maxWidth,
              child: AnimatedBuilder(
                animation: Listenable.merge([_arrivee, _camions]),
                builder: (context, _) => CustomPaint(
                  painter: _PeintrePort(
                    couleurs: context.couleurs,
                    texte: style,
                    surface: Theme.of(context).colorScheme.surface,
                    navire: Curves.easeOutCubic.transform(_arrivee.value),
                    camions: _camions.value,
                    nombre: widget.nombreConteneurs,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PeintrePort extends CustomPainter {
  _PeintrePort({
    required this.couleurs,
    required this.texte,
    required this.surface,
    required this.navire,
    required this.camions,
    required this.nombre,
  });

  final Couleurs couleurs;
  final TextStyle texte;
  final Color surface;
  final double navire;
  final double camions;
  final int nombre;

  /// Les étiquettes gardent une taille lisible : on les place sur le plan, sans les mettre à l'échelle.
  void _texte(Canvas canvas, String s, Offset o, double echelle, double largeurEcran) {
    final t = TextPainter(text: TextSpan(text: s.toUpperCase(), style: texte), textDirection: TextDirection.ltr)..layout();
    final position = o * echelle;
    if (position.dx + t.width <= largeurEcran - 8) t.paint(canvas, position);
  }

  void _conteneur(Canvas canvas, Rect r, Color couleur) {
    canvas.drawRect(r, Paint()..color = couleur);
    final rainure = Paint()..color = Colors.white.withValues(alpha: .16);
    for (var x = r.left + 4; x < r.right - 2; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, r.top + 2, 2, r.height - 4), rainure);
    }
  }

  void _camion(Canvas canvas, Offset o, Color couleur) {
    canvas.drawRect(Rect.fromLTWH(o.dx - 14, o.dy - 12, 19, 13), Paint()..color = couleur);
    canvas.drawPath(
        Path()
          ..moveTo(o.dx + 5, o.dy - 9)
          ..lineTo(o.dx + 11, o.dy - 9)
          ..lineTo(o.dx + 15, o.dy - 4)
          ..lineTo(o.dx + 15, o.dy + 1)
          ..lineTo(o.dx + 5, o.dy + 1)
          ..close(),
        Paint()..color = couleurs.coque);
    final roue = Paint()..color = couleurs.coque;
    canvas.drawCircle(Offset(o.dx - 9, o.dy + 2), 3, roue);
    canvas.drawCircle(Offset(o.dx + 9, o.dy + 2), 3, roue);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = couleurs.ciel);
    final echelle = size.height / 300;
    canvas.save();
    canvas.scale(echelle);
    final largeur = size.width / echelle;

    // mer, vagues
    canvas.drawRect(const Rect.fromLTWH(0, 215, 470, 85), Paint()..color = couleurs.mer);
    final vague = Path()..moveTo(0, 219);
    for (var x = 0.0; x < 470; x += 30) {
      vague.relativeQuadraticBezierTo(7.5, -5, 15, 0);
      vague.relativeQuadraticBezierTo(7.5, 5, 15, 0);
    }
    canvas.drawPath(vague, Paint()
      ..color = couleurs.vague
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // quai et grue
    canvas.drawRect(const Rect.fromLTWH(470, 70, 170, 230), Paint()..color = couleurs.quai);
    final grue = Paint()
      ..color = texte.color!.withValues(alpha: .7)
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(484, 300), const Offset(484, 30), grue);
    canvas.drawLine(const Offset(400, 32), const Offset(600, 32), grue);
    canvas.drawLine(const Offset(484, 66), const Offset(540, 32), grue);

    // conteneurs déjà déchargés sur le quai
    for (var i = 0; i < nombre; i++) {
      _conteneur(canvas, Rect.fromLTWH(505 + (i % 2) * 64, 200 - (i ~/ 2) * 36, 58, 32), couleurs.conteneur(i));
    }

    // navire
    canvas.save();
    canvas.translate((navire - 1) * 480, 0);
    canvas.drawPath(
        Path()
          ..moveTo(30, 180)
          ..lineTo(450, 180)
          ..lineTo(424, 226)
          ..lineTo(58, 226)
          ..close(),
        Paint()..color = couleurs.coque);
    canvas.drawRect(const Rect.fromLTWH(30, 176, 420, 5), Paint()..color = couleurs.conteneur(0));
    canvas.drawRect(const Rect.fromLTWH(40, 126, 44, 52), Paint()..color = couleurs.coque);
    canvas.drawRect(const Rect.fromLTWH(46, 134, 32, 9), Paint()..color = couleurs.ciel);
    for (var rangee = 0; rangee < 2; rangee++) {
      for (var i = 0; i < 5 - rangee; i++) {
        _conteneur(canvas, Rect.fromLTWH(96 + i * 66 + rangee * 33, 146 - rangee * 32, 62, 30),
            couleurs.conteneur(i + rangee * 2));
      }
    }
    canvas.restore();

    // route et boutiques du marché
    if (largeur > 640) {
      canvas.drawRect(Rect.fromLTWH(640, 252, largeur - 640, 8), Paint()..color = couleurs.quai);
      for (var i = 0; i < 3; i++) {
        final x = 690.0 + i * 100;
        canvas.drawRect(Rect.fromLTWH(x, 170, 80, 70), Paint()..color = surface);
        for (var j = 0; j < 4; j++) {
          canvas.drawRect(Rect.fromLTWH(x + j * 20, 160, 20, 12),
              Paint()..color = j.isEven ? couleurs.conteneur(i + 1) : surface);
        }
        canvas.drawRect(Rect.fromLTWH(x + 28, 205, 24, 35), Paint()..color = couleurs.quai);
      }
      // camions qui font l'aller du quai aux boutiques
      if (navire >= 1) {
        for (var i = 0; i < math.min(nombre, 3); i++) {
          final t = (camions + i / 3) % 1;
          _camion(canvas, Offset(640 + t * 360, 250), couleurs.conteneur(i));
        }
      }
    }

    canvas.restore();
    _texte(canvas, 'Rade de Conakry', const Offset(16, 14), echelle, size.width);
    _texte(canvas, 'Port autonome', const Offset(494, 80), echelle, size.width);
    _texte(canvas, 'Marché de Madina', const Offset(690, 120), echelle, size.width);
  }

  @override
  bool shouldRepaint(_PeintrePort old) =>
      old.navire != navire || old.camions != camions || old.couleurs != couleurs || old.nombre != nombre;
}
