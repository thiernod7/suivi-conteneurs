import 'package:flutter/widgets.dart';

import '../domaine/calculs.dart';

/// Donne accès au [Suivi] calculé à tous les écrans.
class SuiviScope extends InheritedWidget {
  const SuiviScope({super.key, required this.suivi, required super.child});

  final Suivi suivi;

  static Suivi of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SuiviScope>()!.suivi;

  @override
  bool updateShouldNotify(SuiviScope old) => old.suivi != suivi;
}
