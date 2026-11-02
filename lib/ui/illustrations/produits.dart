import 'package:flutter/material.dart';

import '../../domaine/modeles.dart';

/// Petit dessin d'un produit (sac, bidon, carton, pneu…), dessiné sur une grille de 24 × 24.
class IconeDeProduit extends StatelessWidget {
  const IconeDeProduit(this.icone, {super.key, this.taille = 20});

  final IconeProduit icone;
  final double taille;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: taille,
        child: CustomPaint(painter: _PeintreProduit(icone)),
      );
}

class _PeintreProduit extends CustomPainter {
  _PeintreProduit(this.icone);

  final IconeProduit icone;

  Paint _plein(int c) => Paint()..color = Color(c);
  Paint _trait(int c, [double l = .8]) => Paint()
    ..color = Color(c)
    ..style = PaintingStyle.stroke
    ..strokeWidth = l;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    switch (icone) {
      case IconeProduit.sac:
      case IconeProduit.sucre:
        final riz = icone == IconeProduit.sac;
        final sac = Path()
          ..moveTo(7, 6.5)
          ..quadraticBezierTo(12, 4, 17, 6.5)
          ..lineTo(19.5, 20)
          ..quadraticBezierTo(12, 22.5, 4.5, 20)
          ..close();
        canvas.drawPath(sac, _plein(riz ? 0xFFD9C08C : 0xFFF4F4F0));
        canvas.drawPath(sac, _trait(riz ? 0xFF8A6D3B : 0xFF8C979E));
        canvas.drawRect(const Rect.fromLTWH(8, 12, 8, 4), _plein(riz ? 0xFFC4532D : 0xFF3B5A9C));
        canvas.drawPath(
            Path()
              ..moveTo(9, 6.5)
              ..quadraticBezierTo(12, 9, 15, 6.5),
            _trait(riz ? 0xFF8A6D3B : 0xFF8C979E));
      case IconeProduit.bidon:
        final corps = RRect.fromRectAndRadius(const Rect.fromLTWH(5.5, 6, 13, 15.5), const Radius.circular(2));
        canvas.drawRRect(corps, _plein(0xFFE8B923));
        canvas.drawRRect(corps, _trait(0xFFA07C0C));
        canvas.drawRect(const Rect.fromLTWH(13, 2.5, 4, 4), _plein(0xFFC4532D));
        canvas.drawRect(const Rect.fromLTWH(7.5, 8, 3.5, 3), _plein(0x8CFFFFFF));
      case IconeProduit.carton:
        canvas.drawPath(
            Path()
              ..moveTo(3.5, 8.5)
              ..lineTo(12, 4.5)
              ..lineTo(20.5, 8.5)
              ..lineTo(20.5, 18.5)
              ..lineTo(12, 22.5)
              ..lineTo(3.5, 18.5)
              ..close(),
            _plein(0xFFB98552));
        canvas.drawPath(
            Path()
              ..moveTo(3.5, 8.5)
              ..lineTo(12, 12.5)
              ..lineTo(20.5, 8.5)
              ..moveTo(12, 12.5)
              ..lineTo(12, 22.5),
            _trait(0xFF7A5430, 1));
      case IconeProduit.tomate:
      case IconeProduit.lait:
        final tomate = icone == IconeProduit.tomate;
        final boite = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 5, 12, 15), const Radius.circular(2));
        canvas.drawRRect(boite, _plein(tomate ? 0xFFD7D9DB : 0xFFEEF2F5));
        canvas.drawRRect(boite, _trait(tomate ? 0xFF8C979E : 0xFF3B5A9C));
        if (tomate) {
          canvas.drawRect(const Rect.fromLTWH(6, 9, 12, 7), _plein(0xFFC0392B));
          canvas.drawCircle(const Offset(12, 12.5), 2.2, _plein(0xFFE8573F));
        } else {
          canvas.drawRect(const Rect.fromLTWH(6, 10, 12, 5), _plein(0xFF3B5A9C));
        }
      case IconeProduit.pneu:
        canvas.drawCircle(const Offset(12, 12), 9.5, _plein(0xFF2A2A2A));
        canvas.drawCircle(const Offset(12, 12), 7.6, _trait(0xFF555555, 1.5));
        canvas.drawCircle(const Offset(12, 12), 4, _plein(0xFF9AA4AB));
      case IconeProduit.batterie:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 8, 16, 12), const Radius.circular(1.5)), _plein(0xFF3B5A9C));
        canvas.drawRect(const Rect.fromLTWH(6, 5, 3, 3), _plein(0xFF333333));
        canvas.drawRect(const Rect.fromLTWH(15, 5, 3, 3), _plein(0xFFC0392B));
        canvas.drawPath(
            Path()
              ..moveTo(12, 10.5)
              ..lineTo(10, 14.5)
              ..lineTo(12.5, 14.5)
              ..lineTo(11.5, 18),
            _trait(0xFFF0B429, 1.2));
    }
  }

  @override
  bool shouldRepaint(_PeintreProduit old) => old.icone != icone;
}
