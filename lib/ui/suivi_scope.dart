import 'package:flutter/widgets.dart';

import '../domaine/calculs.dart';
import '../donnees/depot.dart';

/// Donne accès aux données à tous les écrans. Quand on ajoute quelque chose, les écrans se redessinent.
class SuiviScope extends InheritedNotifier<Depot> {
  const SuiviScope({super.key, required Depot depot, required super.child}) : super(notifier: depot);

  /// Les chiffres calculés, à afficher.
  static Suivi of(BuildContext context) => depot(context).suivi;

  /// Le dépôt, pour ajouter des données.
  static Depot depot(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SuiviScope>()!.notifier!;
}
