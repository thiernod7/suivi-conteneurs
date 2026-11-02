import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'domaine/calculs.dart';
import 'donnees/exemple.dart';

Future<void> main() async {
  await initializeDateFormatting('fr');
  runApp(Application(suivi: Suivi(donneesExemple, aujourdhuiExemple)));
}
