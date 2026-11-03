import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../composants.dart';
import '../format.dart';
import '../recherche.dart';
import '../theme.dart';

// Les pièces communes à tous les formulaires d'ajout : la page, les champs, les choix.

/// Page d'un formulaire : une croix pour annuler, les champs, un grand bouton « Enregistrer » en bas.
class PageFormulaire extends StatelessWidget {
  const PageFormulaire({
    super.key,
    required this.titre,
    required this.cle,
    required this.enfants,
    required this.onEnregistrer,
    this.supprimer,
  });

  final String titre;
  final GlobalKey<FormState> cle;
  final List<Widget> enfants;
  final VoidCallback onEnregistrer;

  /// En modification : le bouton rouge « Supprimer » en bas du formulaire.
  final Suppression? supprimer;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(tooltip: 'Annuler', icon: const Icon(Symbols.close), onPressed: () => context.pop()),
      title: Text(titre),
    ),
    body: Form(
      key: cle,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: PageContenu(
        enfants: [
          // Sur grand écran, le formulaire garde une largeur confortable, au centre.
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...enfants,
                  if (supprimer != null) ...[const SizedBox(height: 32), _BoutonSupprimer(supprimer!)],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: context.couleurs.trait, width: .8)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          // heightFactor 1 : la barre garde la hauteur du bouton au lieu de prendre tout l'écran.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () {
                  if (cle.currentState!.validate()) onEnregistrer();
                },
                icon: const Icon(Symbols.check),
                label: const Text('Enregistrer', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Ce qu'il faut pour supprimer : le texte du bouton, le message de confirmation,
/// la raison pour laquelle c'est impossible (ou null), et l'action.
class Suppression {
  const Suppression({required this.texte, required this.message, required this.onSupprimer, this.raisonImpossible});

  final String texte;
  final String message;
  final String? raisonImpossible;
  final VoidCallback onSupprimer;
}

class _BoutonSupprimer extends StatelessWidget {
  const _BoutonSupprimer(this.s);

  final Suppression s;

  @override
  Widget build(BuildContext context) {
    final rouge = context.couleurs.alerte;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: rouge,
        side: BorderSide(color: rouge.withValues(alpha: .5)),
        minimumSize: const Size.fromHeight(50),
      ),
      icon: const Icon(Symbols.delete),
      label: Text(s.texte),
      onPressed: () async {
        if (s.raisonImpossible != null) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Symbols.block),
              title: const Text('Impossible'),
              content: Text(s.raisonImpossible!),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Compris'))],
            ),
          );
          return;
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(Symbols.delete, color: rouge),
            title: Text('${s.texte} ?'),
            content: Text(s.message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: rouge),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Oui, supprimer'),
              ),
            ],
          ),
        );
        if (ok == true) s.onSupprimer();
      },
    );
  }
}

/// Espace entre deux champs.
const espaceChamp = SizedBox(height: 16);

/// Titre d'une partie du formulaire.
class TitreChamps extends StatelessWidget {
  const TitreChamps(this.texte, {super.key, required this.icone});

  final String texte;
  final IconData icone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 10),
    child: Row(
      children: [
        Icon(icone, size: 20, color: context.couleurs.muet),
        const SizedBox(width: 8),
        Flexible(
          child: Text(texte, style: TextStyle(fontSize: 16, color: context.couleurs.muet)),
        ),
      ],
    ),
  );
}

String? obligatoire(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

class ChampTexte extends StatelessWidget {
  const ChampTexte({
    super.key,
    required this.controleur,
    required this.libelle,
    required this.icone,
    this.requis = true,
    this.majuscules = false,
    this.indice,
    this.validateur,
    this.formateurs,
  });

  final TextEditingController controleur;
  final String libelle;
  final IconData icone;
  final bool requis;
  final bool majuscules;
  final String? indice;
  final FormFieldValidator<String>? validateur;
  final List<TextInputFormatter>? formateurs;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controleur,
    textCapitalization: majuscules ? TextCapitalization.characters : TextCapitalization.sentences,
    inputFormatters: formateurs,
    decoration: InputDecoration(labelText: libelle, hintText: indice, prefixIcon: Icon(icone)),
    validator: (v) => (requis ? obligatoire(v) : null) ?? validateur?.call(v),
  );
}

/// Écrit les nombres par paquets de trois chiffres pendant qu'on tape : 1 250 000.
class FormateurMilliers extends TextInputFormatter {
  static final _f = NumberFormat.decimalPattern('fr');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue ancien, TextEditingValue nouveau) {
    final chiffres = nouveau.text.replaceAll(RegExp(r'\D'), '');
    if (chiffres.isEmpty) return const TextEditingValue();
    final texte = _f.format(int.parse(chiffres));
    return TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
  }
}

/// Le nombre écrit dans un champ (0 s'il est vide).
int lireNombre(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

/// Met un nombre dans un champ, écrit par paquets de trois chiffres.
void ecrireNombre(TextEditingController c, int n) => c.text = n == 0 ? '' : nombre(n);

/// Un montant en GNF, ou une quantité : seulement des chiffres, groupés par trois.
class ChampNombre extends StatelessWidget {
  const ChampNombre({
    super.key,
    required this.controleur,
    required this.libelle,
    required this.icone,
    this.suffixe = 'GNF',
    this.requis = true,
    this.minimum = 1,
    this.maximum,
    this.messageMaximum,
    this.messageMinimum,
    this.onChanged,
  });

  final TextEditingController controleur;
  final String libelle;
  final IconData icone;
  final String suffixe;
  final bool requis;
  final int minimum;
  final int? maximum;

  /// Message quand on dépasse le maximum (sinon « Trop grand »).
  final String? messageMaximum;

  /// Message quand on est sous le minimum (sinon « Au moins … »).
  final String? messageMinimum;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controleur,
    keyboardType: TextInputType.number,
    inputFormatters: [FormateurMilliers()],
    onChanged: (_) => onChanged?.call(lireNombre(controleur)),
    decoration: InputDecoration(labelText: libelle, prefixIcon: Icon(icone), suffixText: suffixe),
    validator: (v) {
      if (!requis && (v == null || v.isEmpty)) return null;
      if (requis && obligatoire(v) != null) return 'Obligatoire';
      final n = lireNombre(controleur);
      if (n < minimum) return messageMinimum ?? 'Au moins ${nombre(minimum)}';
      if (maximum != null && n > maximum!) return messageMaximum ?? 'Trop grand';
      return null;
    },
  );
}

/// Une date : on touche, un calendrier s'ouvre.
class ChampDate extends StatelessWidget {
  const ChampDate({super.key, required this.valeur, required this.onChanged, this.libelle = 'Date'});

  final DateTime valeur;
  final ValueChanged<DateTime> onChanged;
  final String libelle;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () async {
      final choisie = await showDatePicker(
        context: context,
        initialDate: valeur,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (choisie != null) onChanged(choisie);
    },
    child: InputDecorator(
      decoration: InputDecoration(labelText: libelle, prefixIcon: const Icon(Symbols.calendar_today)),
      child: Text(date(valeur), style: const TextStyle(fontSize: 16)),
    ),
  );
}

/// Un choix parmi quelques boutons visibles (taille, unité, mode de paiement…).
class ChoixBoutons<T> extends StatelessWidget {
  const ChoixBoutons({super.key, required this.options, required this.valeur, required this.onChanged});

  final List<(T, String, Widget?)> options;
  final T? valeur;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, libelle, avant) in options)
        ChoiceChip(avatar: avant, label: Text(libelle), selected: v == valeur, onSelected: (_) => onChanged(v)),
    ],
  );
}

/// Une possibilité dans un choix qui s'ouvre en panneau (client, facture, produit…).
class Option<T> {
  const Option({
    required this.valeur,
    required this.titre,
    this.sousTitre,
    this.avant,
    this.apres,
    this.recherche = const [],
  });

  final T valeur;
  final String titre;
  final String? sousTitre;
  final Widget? avant;
  final Widget? apres;

  /// Textes en plus sur lesquels on peut chercher.
  final List<String> recherche;
}

/// Un champ qu'on touche pour choisir dans une liste qui monte du bas, avec une recherche.
class ChampChoix<T> extends FormField<T> {
  ChampChoix({
    super.key,
    required String libelle,
    required IconData icone,
    required List<Option<T>> options,
    required T? valeur,
    required ValueChanged<T> onChanged,
    String vide = 'Rien à choisir',
  }) : super(
         initialValue: valeur,
         validator: (v) => v == null ? 'Obligatoire' : null,
         builder: (etat) {
           final context = etat.context;
           final choisie = options.where((o) => o.valeur == etat.value).firstOrNull;
           return InkWell(
             borderRadius: BorderRadius.circular(14),
             onTap: () async {
               final v = await _choisir<T>(context, libelle, options, vide);
               if (v != null) {
                 etat.didChange(v);
                 onChanged(v);
               }
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: libelle,
                 prefixIcon: choisie?.avant == null
                     ? Icon(icone)
                     : Padding(padding: const EdgeInsets.all(10), child: choisie!.avant),
                 suffixIcon: const Icon(Symbols.expand_more),
                 errorText: etat.errorText,
               ),
               isEmpty: choisie == null,
               child: choisie == null
                   ? null
                   : Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(choisie.titre, style: const TextStyle(fontSize: 16)),
                         if (choisie.sousTitre != null)
                           Text(choisie.sousTitre!, style: TextStyle(fontSize: 13.5, color: context.couleurs.muet)),
                       ],
                     ),
             ),
           );
         },
       );

  @override
  FormFieldState<T> createState() => _EtatChoix<T>();
}

class _EtatChoix<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(ChampChoix<T> ancien) {
    super.didUpdateWidget(ancien);
    // La valeur peut changer de l'extérieur (ex. on vide le produit quand on change de facture).
    if (widget.initialValue != value) setValue(widget.initialValue);
  }
}

Future<T?> _choisir<T>(BuildContext context, String titre, List<Option<T>> options, String vide) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        var recherche = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final visibles = options
                .where((o) => correspond([o.titre, o.sousTitre ?? '', ...o.recherche], recherche))
                .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: .75,
              maxChildSize: .95,
              builder: (context, defilement) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        if (options.length > 6) ...[
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) => setState(() => recherche = v),
                            decoration: const InputDecoration(prefixIcon: Icon(Symbols.search), hintText: 'Chercher'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibles.isEmpty
                        ? Center(
                            child: Text(vide, style: TextStyle(fontSize: 17, color: context.couleurs.muet)),
                          )
                        : ListView.separated(
                            controller: defilement,
                            itemCount: visibles.length,
                            separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
                            itemBuilder: (context, i) {
                              final o = visibles[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                leading: o.avant,
                                title: Text(
                                  o.titre,
                                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500),
                                ),
                                subtitle: o.sousTitre == null ? null : Text(o.sousTitre!),
                                trailing: o.apres,
                                onTap: () => Navigator.pop(context, o.valeur),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

/// Après un enregistrement : un message en bas de l'écran.
void annoncer(BuildContext context, String texte) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Symbols.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(texte)),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
