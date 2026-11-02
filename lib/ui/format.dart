import 'package:intl/intl.dart';

final _entier = NumberFormat.decimalPattern('fr');
final _date = DateFormat('d MMM y', 'fr');

/// 1 250 000 GNF
String gnf(int montant) => '${_entier.format(montant)} GNF';

/// 1 250 000
String nombre(int n) => _entier.format(n);

/// 1,3 M · 1,25 Md · 950 000
String court(int montant) {
  final signe = montant < 0 ? '−' : '';
  final a = montant.abs();
  String virgule(double v, int decimales) => v.toStringAsFixed(decimales).replaceAll('.', ',');
  if (a >= 1000000000) return '$signe${virgule(a / 1e9, 2)} Md';
  if (a >= 1000000) return '$signe${virgule(a / 1e6, 1)} M';
  return '$signe${_entier.format(a)}';
}

/// +32,1 M · −5,5 M
String signe(int montant) => montant > 0 ? '+${court(montant)}' : court(montant);

/// 28 juil. 2026
String date(DateTime d) => _date.format(d);

/// 74 %
String pourcent(double part) => '${(part * 100).round()} %';
