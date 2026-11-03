import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'donnees/depot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  final maintenant = DateTime.now();
  final depot = await Depot.charger(DateTime(maintenant.year, maintenant.month, maintenant.day));
  runApp(Application(depot: depot));
}
